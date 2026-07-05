//
//  AccountService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    /// アカウント削除が完了したときに送る通知。ルート側でセッションを再確立するために使う。
    static let accountDeleted = Notification.Name("accountDeleted")
}

/// アカウント削除の責務を担うサービス。
/// Firestore 上の関連データをすべて削除したうえで、Firebase Authentication のユーザー自体を削除する。
final class AccountService {

    private let db = Firestore.firestore()
    private let authService = AuthService()

    /// ログイン中（匿名）ユーザーのアカウントと関連データを全削除する。
    ///
    /// ミッション記録・ルーム所属・フレンド・フレンド申請・ブロック情報・プロフィールの順に削除し、
    /// 最後に Firebase Authentication のユーザーを削除する。
    /// - Throws: 未認証は `AuthError.notAuthenticated`、削除失敗時は Firestore／Auth のエラー。
    func deleteAccount() async throws {
        let uid = try authService.requireUid()

        try await deleteMissionRecords(uid: uid)
        try await leaveOrDeleteRooms(uid: uid)
        try await deleteFriends(uid: uid)
        try await deleteFriendRequests(uid: uid)
        try await deleteBlockedUsers(uid: uid)
        try await db.collection("users").document(uid).delete()

        try await Auth.auth().currentUser?.delete()
    }

    // MARK: - Cascade steps

    /// 自分が作成したミッション記録をすべて削除する。
    private func deleteMissionRecords(uid: String) async throws {
        let snapshot = try await db.collection("mission_records")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()

        try await commitDeletions(snapshot.documents.map { $0.reference })
    }

    /// 自分が所属するルームを整理する。
    /// オーナーのルームはルーム本体と全メンバーを削除し、一般メンバーのルームは自分のメンバー情報削除とメンバー数の減算を行う。
    private func leaveOrDeleteRooms(uid: String) async throws {
        let memberSnapshot = try await db.collection("roomMembers")
            .whereField("uid", isEqualTo: uid)
            .getDocuments()

        for memberDoc in memberSnapshot.documents {
            guard let roomId = memberDoc.data()["roomId"] as? String else { continue }

            let roomRef = db.collection("rooms").document(roomId)
            let roomSnapshot = try await roomRef.getDocument()
            let ownerUid = roomSnapshot.data()?["ownerUid"] as? String

            if ownerUid == uid {
                // オーナー: ルームと全メンバーを削除
                let allMembers = try await db.collection("roomMembers")
                    .whereField("roomId", isEqualTo: roomId)
                    .getDocuments()

                var refs = allMembers.documents.map { $0.reference }
                refs.append(roomRef)
                try await commitDeletions(refs)
            } else {
                // 一般メンバー: 自分のメンバー情報を削除し、メンバー数を減らす
                let batch = db.batch()
                batch.deleteDocument(memberDoc.reference)

                if roomSnapshot.exists {
                    let currentCount = roomSnapshot.data()?["memberCount"] as? Int ?? 1
                    batch.updateData([
                        "memberCount": max(currentCount - 1, 0),
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: roomRef)
                }

                try await batch.commit()
            }
        }
    }

    /// フレンド関係を双方向で解除する。
    private func deleteFriends(uid: String) async throws {
        let friendsSnapshot = try await db.collection("users")
            .document(uid)
            .collection("friends")
            .getDocuments()

        var refs: [DocumentReference] = []
        for friendDoc in friendsSnapshot.documents {
            let otherUid = friendDoc.documentID
            refs.append(db.collection("users").document(uid).collection("friends").document(otherUid))
            refs.append(db.collection("users").document(otherUid).collection("friends").document(uid))
        }

        try await commitDeletions(refs)
    }

    /// 自分が関与する（送信・受信）フレンド申請をすべて削除する。
    private func deleteFriendRequests(uid: String) async throws {
        let outgoing = try await db.collection("friendRequests")
            .whereField("fromUid", isEqualTo: uid)
            .getDocuments()

        let incoming = try await db.collection("friendRequests")
            .whereField("toUid", isEqualTo: uid)
            .getDocuments()

        let refs = (outgoing.documents + incoming.documents).map { $0.reference }
        try await commitDeletions(refs)
    }

    /// 自分のブロック一覧を削除する。
    private func deleteBlockedUsers(uid: String) async throws {
        let snapshot = try await db.collection("users")
            .document(uid)
            .collection("blockedUsers")
            .getDocuments()

        try await commitDeletions(snapshot.documents.map { $0.reference })
    }

    // MARK: - Helpers

    /// ドキュメント参照の配列をバッチ削除する。Firestore のバッチ上限（500）に収まるよう分割して commit する。
    private func commitDeletions(_ refs: [DocumentReference]) async throws {
        guard !refs.isEmpty else { return }

        let chunkSize = 400
        var index = 0

        while index < refs.count {
            let batch = db.batch()
            let chunk = refs[index..<min(index + chunkSize, refs.count)]
            for ref in chunk {
                batch.deleteDocument(ref)
            }
            try await batch.commit()
            index += chunkSize
        }
    }
}
