//
//  BlockService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import Foundation
import FirebaseFirestore

/// ユーザーのブロックまわりの責務を担うサービス。
/// ブロック情報は `users/{uid}/blockedUsers/{blockedUid}` サブコレクションで管理する。
final class BlockService {

    private let db = Firestore.firestore()
    private let authService = AuthService()
    private let userService = UserService()

    /// 自分がブロックしている相手の UID 一覧を取得する。
    func fetchBlockedUids() async throws -> Set<String> {
        let myUid = try authService.requireUid()

        let snapshot = try await db.collection("users")
            .document(myUid)
            .collection("blockedUsers")
            .getDocuments()

        return Set(snapshot.documents.map { $0.documentID })
    }

    /// 自分がブロックしている相手の一覧を、ユーザー情報付きで取得する。
    func fetchBlockedUsers() async throws -> [User] {
        let uids = try await fetchBlockedUids()
        guard !uids.isEmpty else { return [] }
        return await userService.fetchUsers(uids: Array(uids))
    }

    /// 自分が相手をブロックしているかどうかを判定する。
    ///
    /// セキュリティルール上、他ユーザーの `blockedUsers` は読めないため、参照するのは自分のブロック一覧のみ。
    /// - Parameter otherUid: 判定する相手の UID
    func isBlockedByMe(_ otherUid: String) async -> Bool {
        guard let myUid = authService.currentUid else { return false }

        let ref = db.collection("users").document(myUid)
            .collection("blockedUsers").document(otherUid)

        return (try? await ref.getDocument())?.exists ?? false
    }

    /// 相手をブロックする。
    ///
    /// ブロック情報の登録に加えて、既存のフレンド関係の解除と、双方向の保留中フレンド申請の削除を
    /// 1 つのバッチで原子的に実行する。
    ///
    /// フレンド申請は「実際に存在するものだけ」を削除する。存在しないドキュメントを削除しようとすると
    /// セキュリティルール上 `resource` が nil となり拒否されるため、事前に存在確認する。
    /// - Parameter otherUid: ブロックする相手の UID
    func blockUser(_ otherUid: String) async throws {
        let myUid = try authService.requireUid()

        // 保留中フレンド申請の存在を先に確認する（存在しないものは削除対象にしない）。
        let outgoingRequestRef = db.collection("friendRequests").document("\(myUid)_\(otherUid)")
        let incomingRequestRef = db.collection("friendRequests").document("\(otherUid)_\(myUid)")

        async let outgoingSnapshot = outgoingRequestRef.getDocument()
        async let incomingSnapshot = incomingRequestRef.getDocument()
        let (outgoing, incoming) = try await (outgoingSnapshot, incomingSnapshot)

        let batch = db.batch()

        // ブロック情報を登録
        batch.setData(
            ["blockedAt": Timestamp(date: Date())],
            forDocument: db.collection("users").document(myUid)
                .collection("blockedUsers").document(otherUid)
        )

        // フレンド関係を双方向で解除（friends はパスベースのルールのため未存在でも安全に削除できる）
        batch.deleteDocument(
            db.collection("users").document(myUid).collection("friends").document(otherUid)
        )
        batch.deleteDocument(
            db.collection("users").document(otherUid).collection("friends").document(myUid)
        )

        // 実際に存在する保留中フレンド申請のみ削除
        if outgoing.exists {
            batch.deleteDocument(outgoingRequestRef)
        }
        if incoming.exists {
            batch.deleteDocument(incomingRequestRef)
        }

        try await batch.commit()
    }

    /// 相手のブロックを解除する。
    /// - Parameter otherUid: ブロック解除する相手の UID
    func unblockUser(_ otherUid: String) async throws {
        let myUid = try authService.requireUid()

        try await db.collection("users")
            .document(myUid)
            .collection("blockedUsers")
            .document(otherUid)
            .delete()
    }
}
