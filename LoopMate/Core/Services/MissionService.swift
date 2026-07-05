//
//  MissionService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

enum MissionServiceError: LocalizedError {
    case failedToConvertImage
    case failedToUploadImage
    case failedToGetDownloadURL

    var errorDescription: String? {
        switch self {
        case .failedToConvertImage:
            return "画像データの変換に失敗しました"
        case .failedToUploadImage:
            return "画像のアップロードに失敗しました"
        case .failedToGetDownloadURL:
            return "画像URLの取得に失敗しました"
        }
    }
}

final class MissionService {
    
    private let db = Firestore.firestore()
    private let authService = AuthService()

    // 今日のdateKey生成
    static func makeDateKey(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    // 今日の実施記録を取得
    func fetchTodayRecords(uid: String) async throws -> [MissionRecord] {

        let dateKey = Self.makeDateKey()

        let snapshot = try await db.collection("mission_records")
            .whereField("userId", isEqualTo: uid)
            .whereField("dateKey", isEqualTo: dateKey)
            .getDocuments()

        return snapshot.documents.compactMap {
            try? $0.data(as: MissionRecord.self)
        }
    }

    func saveRecord(
        room: Room,
        value: Double?,
        comment: String,
        photoURL: String?
    ) async throws {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let dateKey = Self.makeDateKey()
        let recordId = "\(room.id)_\(uid)_\(dateKey)"

        let data: [String: Any] = [
            "roomId": room.id,
            "userId": uid,
            "dateKey": dateKey,
            "value": value as Any,
            "comment": comment,
            "photoURL": photoURL as Any,
            "updatedAt": Timestamp(date: Date())
        ]

        try await db.collection("mission_records")
            .document(recordId)
            .setData(data, merge: true)
    }

    func uploadMissionPhoto(
        image: UIImage,
        roomId: String
    ) async throws -> String {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MissionServiceError.failedToConvertImage
        }

        let dateKey = Self.makeDateKey()
        let fileName = UUID().uuidString + ".jpg"
        let path = "missionPhotos/\(uid)/\(roomId)/\(dateKey)/\(fileName)"

        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let uploadedMetadata = try await storageRef.putDataAsync(imageData, metadata: metadata)

        print("upload success. path =", path)
        print("metadata =", uploadedMetadata as Any)

        let url = try await storageRef.downloadURL()

        print("downloadURL =", url.absoluteString)

        return url.absoluteString
    }

    // 対象のルームの記録日一覧を取る関数
    func fetchMyRecordDateKeys(roomId: String) async throws -> Set<String> {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        return try await fetchRecordDateKeys(roomId: roomId, userId: uid)
    }

    func fetchRecordsForRoom(roomId: String) async throws -> [MissionRecord] {
        let snapshot = try await db.collection("mission_records")
            .whereField("roomId", isEqualTo: roomId)
            .getDocuments()

        return snapshot.documents.compactMap {
            try? $0.data(as: MissionRecord.self)
        }
    }

    func fetchMyRecord(
        roomId: String,
        date: Date
    ) async throws -> MissionRecord? {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        return try await fetchRecord(roomId: roomId, userId: uid, date: date)
    }

    func fetchRecordDateKeys(
        roomId: String,
        userId: String
    ) async throws -> Set<String> {
        let snapshot = try await db.collection("mission_records")
            .whereField("roomId", isEqualTo: roomId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return Set(
            snapshot.documents.compactMap { document in
                document.data()["dateKey"] as? String
            }
        )
    }

    func fetchRecord(
        roomId: String,
        userId: String,
        date: Date
    ) async throws -> MissionRecord? {
        let dateKey = Self.makeDateKey(from: date)
        let recordId = "\(roomId)_\(userId)_\(dateKey)"

        let snapshot = try await db.collection("mission_records")
            .document(recordId)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(as: MissionRecord.self)
    }
}
