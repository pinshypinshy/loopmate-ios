//
//  RoomService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/15.
//

import Foundation
import FirebaseFirestore

enum RoomServiceError: LocalizedError, Equatable {
    case roomNotFound
    case invalidRoomData
    case roomAlreadyJoined

    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            return "該当するルームが見つかりませんでした"
        case .invalidRoomData:
            return "ルームデータの形式が不正です"
        case .roomAlreadyJoined:
            return "このルームにはすでに参加しています"
        }
    }
}

final class RoomService {

    private let db = Firestore.firestore()
    private let authService = AuthService()

    /// ルームを新規作成し、作成者をオーナーとして登録する。
    /// - Parameters:
    ///   - name: ルーム名。
    ///   - iconName: ルームアイコン名。
    ///   - isNumberRequired: 記録時に数値入力を必須とするか。
    ///   - isPhotoRequired: 記録時に写真添付を必須とするか。
    ///   - startDate: ミッション開始日。
    ///   - endDate: ミッション終了日（無期限の場合は nil）。
    ///   - selectedWeekdays: 曜日ごとの有効フラグ（日曜始まりの 7 要素）。
    /// - Returns: 作成されたルーム。
    /// - Throws: 未認証の場合は `AuthError.notAuthenticated`、書き込み失敗時は Firestore エラー。
    func createRoom(
        name: String,
        iconName: String,
        isNumberRequired: Bool,
        isPhotoRequired: Bool,
        startDate: Date,
        endDate: Date?,
        selectedWeekdays: [Bool]
    ) async throws -> Room {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let roomRef = db.collection("rooms").document()
        let roomId = roomRef.documentID
        let now = Timestamp(date: Date())
        let roomCode = Self.generateRoomCode()

        let roomData: [String: Any] = [
            "name": name,
            "code": roomCode,
            "ownerUid": uid,
            "createdAt": now,
            "updatedAt": now,
            "iconName": iconName,
            "memberCount": 1,
            "isNumberRequired": isNumberRequired,
            "isPhotoRequired": isPhotoRequired,
            "startDate": Timestamp(date: startDate),
            "endDate": endDate.map { Timestamp(date: $0) } as Any,
            "selectedWeekdays": selectedWeekdays
        ]

        let memberDocId = "\(roomId)_\(uid)"

        let memberData: [String: Any] = [
            "roomId": roomId,
            "uid": uid,
            "role": "owner",
            "joinedAt": now
        ]

        let batch = db.batch()
        batch.setData(roomData, forDocument: roomRef)
        batch.setData(memberData, forDocument: db.collection("roomMembers").document(memberDocId))

        try await batch.commit()

        return Room(
            id: roomId,
            name: name,
            code: roomCode,
            memberCount: 1,
            ownerUid: uid,
            createdAt: now,
            updatedAt: now,
            iconName: iconName,
            isNumberRequired: isNumberRequired,
            isPhotoRequired: isPhotoRequired,
            startDate: Timestamp(date: startDate),
            endDate: endDate.map { Timestamp(date: $0) },
            selectedWeekdays: selectedWeekdays,
            progress: 0
        )
    }

    /// ルーム参加用のランダムな招待コードを生成する。
    /// - Parameter length: 生成するコードの文字数（既定 5）。
    /// - Returns: 英大文字と数字からなるコード文字列。
    private static func generateRoomCode(length: Int = 5) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }

    /// 自分が所属するルーム一覧を取得する。
    /// - Returns: 作成日の新しい順に並べたルーム配列。所属がなければ空配列。
    /// - Throws: 未認証の場合は `AuthError.notAuthenticated`、取得失敗時は Firestore エラー。
    func fetchMyRooms() async throws -> [Room] {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let snapshot = try await db.collection("roomMembers")
            .whereField("uid", isEqualTo: uid)
            .getDocuments()

        let roomIds = snapshot.documents.compactMap { $0.data()["roomId"] as? String }

        if roomIds.isEmpty {
            return []
        }

        return try await fetchRooms(by: roomIds)
    }

    /// 複数の roomId から対応するルームを並列に取得する。
    /// - Parameter roomIds: 取得対象のルーム ID 配列。
    /// - Returns: 作成日の新しい順に並べたルーム配列（取得・パースできなかったものは除外）。
    /// - Throws: いずれかの取得に失敗した場合は Firestore エラー。
    private func fetchRooms(by roomIds: [String]) async throws -> [Room] {
        let rooms = try await withThrowingTaskGroup(of: Room?.self) { group -> [Room] in
            for roomId in roomIds {
                group.addTask {
                    let snapshot = try await self.db.collection("rooms").document(roomId).getDocument()
                    return Room(snapshot: snapshot)
                }
            }

            var results: [Room] = []
            for try await room in group {
                if let room {
                    results.append(room)
                }
            }
            return results
        }

        return rooms.sorted {
            $0.createdAt.dateValue() > $1.createdAt.dateValue()
        }
    }

    /// 単一のルームを取得する。
    /// - Parameter roomId: 取得対象のルーム ID。
    /// - Returns: 対応するルーム。
    /// - Throws: 存在しない場合は `RoomServiceError.roomNotFound`、パース不能なら `RoomServiceError.invalidRoomData`、取得失敗時は Firestore エラー。
    func fetchRoom(roomId: String) async throws -> Room {
        let snapshot = try await db.collection("rooms").document(roomId).getDocument()

        guard snapshot.exists else {
            throw RoomServiceError.roomNotFound
        }

        guard let room = Room(snapshot: snapshot) else {
            throw RoomServiceError.invalidRoomData
        }

        return room
    }

    /// 招待コードからルームを検索する。
    /// - Parameter code: 検索する招待コード（前後空白は除去し大文字化して照合）。
    /// - Returns: 一致したルーム。
    /// - Throws: 空文字や該当なしの場合は `RoomServiceError.roomNotFound`、パース不能なら `RoomServiceError.invalidRoomData`、取得失敗時は Firestore エラー。
    func searchRoom(byCode code: String) async throws -> Room {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !normalizedCode.isEmpty else {
            throw RoomServiceError.roomNotFound
        }

        let snapshot = try await db.collection("rooms")
            .whereField("code", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            throw RoomServiceError.roomNotFound
        }

        guard let room = Room(snapshot: document) else {
            throw RoomServiceError.invalidRoomData
        }

        return room
    }

    /// トランザクションでルームに参加し、メンバー登録とメンバー数の加算を行う。
    /// - Parameter roomId: 参加対象のルーム ID。
    /// - Returns: 参加したルームの ID。
    /// - Throws: 未認証は `AuthError.notAuthenticated`、ルーム不在は `RoomServiceError.roomNotFound`、参加済みは `RoomServiceError.roomAlreadyJoined`、失敗時は Firestore エラー。
    func joinRoom(roomId: String) async throws -> String {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let roomRef = db.collection("rooms").document(roomId)
        let memberRef = db.collection("roomMembers").document("\(roomId)_\(uid)")

        let result = try await db.runTransaction { transaction, errorPointer in
            let roomSnapshot: DocumentSnapshot
            let memberSnapshot: DocumentSnapshot

            do {
                roomSnapshot = try transaction.getDocument(roomRef)
                memberSnapshot = try transaction.getDocument(memberRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard roomSnapshot.exists else {
                errorPointer?.pointee = NSError(
                    domain: "RoomServiceError",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: RoomServiceError.roomNotFound.localizedDescription]
                )
                return nil
            }

            if memberSnapshot.exists {
                errorPointer?.pointee = NSError(
                    domain: "RoomServiceError",
                    code: 409,
                    userInfo: [NSLocalizedDescriptionKey: RoomServiceError.roomAlreadyJoined.localizedDescription]
                )
                return nil
            }

            let currentMemberCount = roomSnapshot.data()?["memberCount"] as? Int ?? 0
            let now = Timestamp(date: Date())

            transaction.setData([
                "roomId": roomId,
                "uid": uid,
                "role": "member",
                "joinedAt": now
            ], forDocument: memberRef)

            transaction.updateData([
                "memberCount": currentMemberCount + 1,
                "updatedAt": now
            ], forDocument: roomRef)

            return roomId
        }

        guard let joinedRoomId = result as? String else {
            throw RoomServiceError.roomNotFound
        }

        return joinedRoomId
    }

    /// 自分が対象ルームのメンバーかどうかを判定する。
    /// - Parameter roomId: 判定対象のルーム ID。
    /// - Returns: メンバーなら `true`。未認証・未参加・取得失敗時は `false`。
    func isUserMember(of roomId: String) async -> Bool {

        guard let uid = authService.currentUid else {
            return false
        }

        let memberDocId = "\(roomId)_\(uid)"

        let snapshot = try? await db.collection("roomMembers")
            .document(memberDocId)
            .getDocument()

        return snapshot?.exists ?? false
    }

    /// ルームから退会する。オーナーの場合はルームと全メンバーを削除し、通常メンバーの場合は自分のメンバー情報削除とメンバー数の減算を行う。
    /// - Parameter room: 退会対象のルーム。
    /// - Throws: 未認証は `AuthError.notAuthenticated`、削除・更新失敗時は Firestore エラー。
    func leaveRoom(room: Room) async throws {

        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let roomRef = db.collection("rooms").document(room.id)
        let memberRef = db.collection("roomMembers").document("\(room.id)_\(uid)")
        let now = Timestamp(date: Date())

        // オーナーの場合
        if room.ownerUid == uid {

            let snapshot = try await db.collection("roomMembers")
                .whereField("roomId", isEqualTo: room.id)
                .getDocuments()

            let batch = db.batch()

            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }

            batch.deleteDocument(roomRef)

            try await batch.commit()

        } else {

            // 通常メンバー
            _ = try await db.runTransaction { transaction, errorPointer in

                let roomSnapshot: DocumentSnapshot

                do {
                    roomSnapshot = try transaction.getDocument(roomRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }

                let currentMemberCount = roomSnapshot.data()?["memberCount"] as? Int ?? 1

                transaction.deleteDocument(memberRef)

                transaction.updateData([
                    "memberCount": currentMemberCount - 1,
                    "updatedAt": now
                ], forDocument: roomRef)

                return nil
            }
        }
    }

    /// 対象ルームのメンバー一覧を取得する。
    /// - Parameter roomId: 取得対象のルーム ID。
    /// - Returns: メンバー配列（uid・参加日を持たないドキュメントは除外）。
    /// - Throws: 取得失敗時は Firestore エラー。
    func fetchRoomMembers(roomId: String) async throws -> [RoomMember] {
        let snapshot = try await db.collection("roomMembers")
            .whereField("roomId", isEqualTo: roomId)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard
                let uid = doc["uid"] as? String,
                let joinedAt = doc["joinedAt"] as? Timestamp
            else {
                return nil
            }

            return RoomMember(
                id: uid,
                joinedAt: joinedAt.dateValue()
            )
        }
    }
}
