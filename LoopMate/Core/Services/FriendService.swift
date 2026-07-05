//
//  FriendService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import Foundation
import FirebaseFirestore

/// フレンド機能で発生するエラー。
enum FriendError: LocalizedError {
    /// ブロック関係のため操作できない。
    case blocked

    var errorDescription: String? {
        switch self {
        case .blocked:
            return "このユーザーには操作できません"
        }
    }
}

final class FriendService {

    private let db = Firestore.firestore()
    private let authService = AuthService()
    private let blockService = BlockService()

    /// ログイン中のユーザーと相手ユーザーのフレンド関係の状態を取得する。
    ///
    /// フレンド登録・送信済み申請・受信済み申請の順に確認し、いずれにも当てはまらなければ `.none` を返す。
    /// - Parameter otherUid: 相手の UID
    /// - Returns: 現在のフレンド関係の状態
    func fetchRelationState(
        otherUid: String
    ) async throws -> FriendRelationState {
        let myUid = try authService.requireUid()

        let myFriendSnapshot = try await db.collection("users")
            .document(myUid)
            .collection("friends")
            .document(otherUid)
            .getDocument()

        if myFriendSnapshot.exists {
            return .friend
        }

        let outgoingSnapshot = try await db.collection("friendRequests")
            .document("\(myUid)_\(otherUid)")
            .getDocument()

        if
            let status = outgoingSnapshot.data()?["status"] as? String,
            status == "pending"
        {
            return .outgoingPending
        }

        let incomingSnapshot = try await db.collection("friendRequests")
            .document("\(otherUid)_\(myUid)")
            .getDocument()

        if
            let status = incomingSnapshot.data()?["status"] as? String,
            status == "pending"
        {
            return .incomingPending
        }

        return .none
    }

    /// 相手ユーザーへフレンド申請を送信する。
    ///
    /// 関係が `.none` のときのみ申請ドキュメントを作成する。既にフレンド・申請中などの場合は何もしない。
    /// - Parameter toUid: 申請を受け取る相手の UID
    func sendFriendRequest(
        toUid: String
    ) async throws {
        let fromUid = try authService.requireUid()

        if await blockService.isBlockedByMe(toUid) {
            throw FriendError.blocked
        }

        let state = try await fetchRelationState(otherUid: toUid)

        guard state == .none else { return }

        let requestId = "\(fromUid)_\(toUid)"

        let data: [String: Any] = [
            "fromUid": fromUid,
            "toUid": toUid,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("friendRequests").document(requestId).setData(data)
    }

    /// ログイン中のユーザー宛に届いている保留中（pending）のフレンド申請一覧を取得する。
    ///
    /// 各申請の送信者ユーザー情報を並行取得して付与し、作成日時の降順で返す。
    /// - Returns: 送信者情報付きのフレンド申請一覧（新しい順）
    func fetchIncomingFriendRequests() async throws -> [FriendRequest] {
        let myUid = try authService.requireUid()

        let snapshot = try await db.collection("friendRequests")
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let requests = try await withThrowingTaskGroup(of: FriendRequest?.self) { group in
            for document in snapshot.documents {
                let data = document.data()
                let documentID = document.documentID

                guard
                    let fromUid = data["fromUid"] as? String,
                    let toUid = data["toUid"] as? String,
                    let status = data["status"] as? String,
                    let createdAt = data["createdAt"] as? Timestamp
                else {
                    continue
                }

                group.addTask {
                    let userSnapshot = try await self.db.collection("users")
                        .document(fromUid)
                        .getDocument()

                    guard
                        let userData = userSnapshot.data(),
                        let user = User(id: fromUid, data: userData)
                    else {
                        return nil
                    }

                    return FriendRequest(
                        id: documentID,
                        fromUid: fromUid,
                        toUid: toUid,
                        status: status,
                        createdAt: createdAt,
                        user: user
                    )
                }
            }

            var results: [FriendRequest] = []
            for try await request in group {
                if let request {
                    results.append(request)
                }
            }
            return results
        }

        return requests.sorted { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
    }

    /// 相手からのフレンド申請を承認する。
    ///
    /// 双方の `friends` サブコレクションへの登録と申請ドキュメントの削除を、1つのバッチで原子的に実行する。
    /// - Parameter otherUid: 申請を送ってきた相手の UID
    func acceptFriendRequest(
        otherUid: String
    ) async throws {
        let myUid = try authService.requireUid()

        let batch = db.batch()

        let myFriendRef = db.collection("users")
            .document(myUid)
            .collection("friends")
            .document(otherUid)

        let otherFriendRef = db.collection("users")
            .document(otherUid)
            .collection("friends")
            .document(myUid)

        let requestRef = db.collection("friendRequests")
            .document("\(otherUid)_\(myUid)")

        let now = Timestamp(date: Date())

        batch.setData([
            "friendUid": otherUid,
            "createdAt": now
        ], forDocument: myFriendRef)

        batch.setData([
            "friendUid": myUid,
            "createdAt": now
        ], forDocument: otherFriendRef)

        batch.deleteDocument(requestRef)

        try await batch.commit()
    }

    /// 相手からのフレンド申請を拒否する。
    ///
    /// 該当する申請ドキュメントを削除するのみで、フレンド登録は行わない。
    /// - Parameter otherUid: 申請を送ってきた相手の UID
    func rejectFriendRequest(
        otherUid: String
    ) async throws {
        let myUid = try authService.requireUid()

        try await db.collection("friendRequests")
            .document("\(otherUid)_\(myUid)")
            .delete()
    }

    /// ログイン中のユーザーのフレンドの UID 一覧を取得する。
    ///
    /// `friends` サブコレクションのドキュメント ID をそのままフレンドの UID として返す。
    /// - Returns: フレンドの UID 一覧
    func fetchFriendIds() async throws -> [String] {
        let myUid = try authService.requireUid()

        let snapshot = try await db.collection("users")
            .document(myUid)
            .collection("friends")
            .getDocuments()

        return snapshot.documents.map { $0.documentID }
    }

    /// フレンド関係を解除する。
    ///
    /// 双方の `friends` サブコレクションから相手のドキュメントを、1つのバッチで原子的に削除する。
    /// - Parameter otherUid: 解除する相手の UID
    func removeFriend(
        otherUid: String
    ) async throws {
        let myUid = try authService.requireUid()

        let batch = db.batch()

        let myFriendRef = db.collection("users")
            .document(myUid)
            .collection("friends")
            .document(otherUid)

        let otherFriendRef = db.collection("users")
            .document(otherUid)
            .collection("friends")
            .document(myUid)

        batch.deleteDocument(myFriendRef)
        batch.deleteDocument(otherFriendRef)

        try await batch.commit()
    }

    /// ログイン中のユーザー宛に届いている保留中（pending）のフレンド申請の件数を取得する。
    ///
    /// バッジ表示などの件数のみが必要な用途向けに、ユーザー情報は取得せず件数だけを返す。
    /// - Returns: 保留中のフレンド申請の件数
    func fetchIncomingFriendRequestCount() async throws -> Int {
        let myUid = try authService.requireUid()

        let snapshot = try await db.collection("friendRequests")
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()

        return snapshot.documents.count
    }
}
