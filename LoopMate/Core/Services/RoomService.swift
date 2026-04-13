//
//  RoomService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/15.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class RoomService {
    
    private let db = Firestore.firestore()
    
    func createRoom(
        name: String,
        iconName: String,
        isNumberRequired: Bool,
        isPhotoRequired: Bool,
        startDate: Date,
        endDate: Date?,
        selectedWeekdays: [Bool],
        completion: @escaping (Result<Room, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(RoomServiceError.userNotSignedIn))
            return
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
        
        batch.commit { error in
            if let error {
                completion(.failure(error))
            } else {
                let createdRoom = Room(
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
                
                completion(.success(createdRoom))
            }
        }
    }
    
    private static func generateRoomCode(length: Int = 5) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    // 自分の所属ルーム一覧を取得する関数
    func fetchMyRooms(completion: @escaping (Result<[Room], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(RoomServiceError.userNotSignedIn))
            return
        }
        
        db.collection("roomMembers")
            .whereField("uid", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let roomIds = documents.compactMap { $0.data()["roomId"] as? String }
                
                if roomIds.isEmpty {
                    completion(.success([]))
                    return
                }
                
                self.fetchRooms(by: roomIds, completion: completion)
            }
    }
    
    // roomId 配列から rooms を取得する関数
    private func fetchRooms(
        by roomIds: [String],
        completion: @escaping (Result<[Room], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var rooms: [Room] = []
        var fetchError: Error?
        
        for roomId in roomIds {
            group.enter()
            
            db.collection("rooms").document(roomId).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error {
                    fetchError = error
                    return
                }
                
                guard
                    let snapshot,
                    let data = snapshot.data()
                else {
                    return
                }
                
                guard
                    let name = data["name"] as? String,
                    let code = data["code"] as? String,
                    let memberCount = data["memberCount"] as? Int,
                    let ownerUid = data["ownerUid"] as? String,
                    let createdAt = data["createdAt"] as? Timestamp,
                    let updatedAt = data["updatedAt"] as? Timestamp,
                    let isNumberRequired = data["isNumberRequired"] as? Bool,
                    let isPhotoRequired = data["isPhotoRequired"] as? Bool,
                    let startDate = data["startDate"] as? Timestamp,
                    let selectedWeekdays = data["selectedWeekdays"] as? [Bool]
                else {
                    return
                }
                
                let iconName = data["iconName"] as? String ?? "checkmark.circle"
                let endDate = data["endDate"] as? Timestamp
                
                let room = Room(
                    id: snapshot.documentID,
                    name: name,
                    code: code,
                    memberCount: memberCount,
                    ownerUid: ownerUid,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    iconName: iconName,
                    isNumberRequired: isNumberRequired,
                    isPhotoRequired: isPhotoRequired,
                    startDate: startDate,
                    endDate: endDate,
                    selectedWeekdays: selectedWeekdays,
                    progress: 0
                )
                
                rooms.append(room)
            }
        }
        
        group.notify(queue: .main) {
            if let fetchError {
                completion(.failure(fetchError))
            } else {
                let sortedRooms = rooms.sorted {
                    $0.createdAt.dateValue() > $1.createdAt.dateValue()
                }
                completion(.success(sortedRooms))
            }
        }
    }
    
    // 単一ルーム取得
    func fetchRoom(roomId: String, completion: @escaping (Result<Room, Error>) -> Void) {
        db.collection("rooms").document(roomId).getDocument { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard
                let snapshot,
                let data = snapshot.data()
            else {
                completion(.failure(RoomServiceError.roomNotFound))
                return
            }
            
            guard
                let name = data["name"] as? String,
                let code = data["code"] as? String,
                let memberCount = data["memberCount"] as? Int,
                let ownerUid = data["ownerUid"] as? String,
                let createdAt = data["createdAt"] as? Timestamp,
                let updatedAt = data["updatedAt"] as? Timestamp,
                let isNumberRequired = data["isNumberRequired"] as? Bool,
                let isPhotoRequired = data["isPhotoRequired"] as? Bool,
                let startDate = data["startDate"] as? Timestamp,
                let selectedWeekdays = data["selectedWeekdays"] as? [Bool]
            else {
                completion(.failure(RoomServiceError.invalidRoomData))
                return
            }
            
            let iconName = data["iconName"] as? String ?? "checkmark.circle"
            let endDate = data["endDate"] as? Timestamp
            
            let room = Room(
                id: snapshot.documentID,
                name: name,
                code: code,
                memberCount: memberCount,
                ownerUid: ownerUid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                iconName: iconName,
                isNumberRequired: isNumberRequired,
                isPhotoRequired: isPhotoRequired,
                startDate: startDate,
                endDate: endDate,
                selectedWeekdays: selectedWeekdays,
                progress: 0
            )
            
            completion(.success(room))
        }
    }
    
    // ルームコードの検索
    func searchRoom(byCode code: String, completion: @escaping (Result<Room, Error>) -> Void) {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !normalizedCode.isEmpty else {
            completion(.failure(RoomServiceError.roomNotFound))
            return
        }
        
        db.collection("rooms")
            .whereField("code", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(.failure(RoomServiceError.roomNotFound))
                    return
                }
                
                let data = document.data()
                
                guard
                    let name = data["name"] as? String,
                    let code = data["code"] as? String,
                    let memberCount = data["memberCount"] as? Int,
                    let ownerUid = data["ownerUid"] as? String,
                    let createdAt = data["createdAt"] as? Timestamp,
                    let updatedAt = data["updatedAt"] as? Timestamp,
                    let isNumberRequired = data["isNumberRequired"] as? Bool,
                    let isPhotoRequired = data["isPhotoRequired"] as? Bool,
                    let startDate = data["startDate"] as? Timestamp,
                    let selectedWeekdays = data["selectedWeekdays"] as? [Bool]
                else {
                    completion(.failure(RoomServiceError.invalidRoomData))
                    return
                }
                
                let iconName = data["iconName"] as? String ?? "checkmark.circle"
                let endDate = data["endDate"] as? Timestamp
                
                let room = Room(
                    id: document.documentID,
                    name: name,
                    code: code,
                    memberCount: memberCount,
                    ownerUid: ownerUid,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    iconName: iconName,
                    isNumberRequired: isNumberRequired,
                    isPhotoRequired: isPhotoRequired,
                    startDate: startDate,
                    endDate: endDate,
                    selectedWeekdays: selectedWeekdays,
                    progress: 0
                )
                
                completion(.success(room))
            }
    }
    
    // ルーム参加
    func joinRoom(roomId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(RoomServiceError.userNotSignedIn))
            return
        }
        
        let roomRef = db.collection("rooms").document(roomId)
        let memberRef = db.collection("roomMembers").document("\(roomId)_\(uid)")
        
        db.runTransaction { transaction, errorPointer in
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
        } completion: { object, error in
            if let error {
                completion(.failure(error))
            } else if let roomId = object as? String {
                completion(.success(roomId))
            } else {
                completion(.failure(RoomServiceError.roomNotFound))
            }
        }
    }
    
    // 自分が対象のルームのメンバーかどうか
    func isUserMember(of roomId: String, completion: @escaping (Bool) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let memberDocId = "\(roomId)_\(uid)"
        
        db.collection("roomMembers")
            .document(memberDocId)
            .getDocument { snapshot, error in
                
                if let snapshot, snapshot.exists {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    // ルーム退会処理
    func leaveRoom(room: Room, completion: @escaping (Result<Void, Error>) -> Void) {

        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(RoomServiceError.userNotSignedIn))
            return
        }

        let roomRef = db.collection("rooms").document(room.id)
        let memberRef = db.collection("roomMembers").document("\(room.id)_\(uid)")
        let now = Timestamp(date: Date())

        // オーナーの場合
        if room.ownerUid == uid {

            db.collection("roomMembers")
                .whereField("roomId", isEqualTo: room.id)
                .getDocuments { snapshot, error in

                    if let error {
                        completion(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        completion(.failure(RoomServiceError.roomNotFound))
                        return
                    }

                    let batch = self.db.batch()

                    for doc in documents {
                        batch.deleteDocument(doc.reference)
                    }

                    batch.deleteDocument(roomRef)

                    batch.commit { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }

        } else {

            // 通常メンバー
            db.runTransaction { transaction, errorPointer in

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

            } completion: { _, error in

                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }

            }
        }
    }
    
    func fetchRoomMembers(
        roomId: String,
        completion: @escaping (Result<[RoomMember], Error>) -> Void
    ) {
        db.collection("roomMembers")
            .whereField("roomId", isEqualTo: roomId)
            .getDocuments { snapshot, error in
                
                if let error {
                    completion(.failure(error))
                    return
                }
                
                let members: [RoomMember] = snapshot?.documents.compactMap { doc in
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
                } ?? []
                
                completion(.success(members))
            }
    }
}

enum RoomServiceError: LocalizedError, Equatable {
    case userNotSignedIn
    case roomNotFound
    case invalidRoomData
    case roomAlreadyJoined
    
    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "ログイン状態を確認できませんでした"
        case .roomNotFound:
            return "該当するルームが見つかりませんでした"
        case .invalidRoomData:
            return "ルームデータの形式が不正です"
        case .roomAlreadyJoined:
            return "このルームにはすでに参加しています"
        }
    }
}
