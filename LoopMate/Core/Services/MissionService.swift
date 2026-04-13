//
//  MissionService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class MissionService {
    
    private let db = Firestore.firestore()
    
    // 今日のdateKey生成
    static func makeDateKey(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    // 今日の実施記録を取得
    func fetchTodayRecords(uid: String, completion: @escaping (Result<[MissionRecord], Error>) -> Void) {
        
        let dateKey = Self.makeDateKey()
        
        db.collection("mission_records")
            .whereField("userId", isEqualTo: uid)
            .whereField("dateKey", isEqualTo: dateKey)
            .getDocuments { snapshot, error in
                
                if let error {
                    completion(.failure(error))
                    return
                }
                
                let records = snapshot?.documents.compactMap {
                    try? $0.data(as: MissionRecord.self)
                } ?? []
                
                completion(.success(records))
            }
    }
    
    // 保存
    func saveRecord(
        room: Room,
        value: Double?,
        comment: String,
        photoURL: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
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
        
        db.collection("mission_records")
            .document(recordId)
            .setData(data, merge: true) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func uploadMissionPhoto(
        image: UIImage,
        roomId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(MissionServiceError.userNotSignedIn))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(MissionServiceError.failedToConvertImage))
            return
        }
        
        let dateKey = Self.makeDateKey()
        let fileName = UUID().uuidString + ".jpg"
        let path = "missionPhotos/\(uid)/\(roomId)/\(dateKey)/\(fileName)"
        
        let storageRef = Storage.storage().reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error {
                print("upload error:", error.localizedDescription)
                completion(.failure(error))
                return
            }
            
            print("upload success. path =", path)
            print("metadata =", metadata as Any)
            
            storageRef.downloadURL { url, error in
                if let error {
                    print("downloadURL error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }
                
                print("downloadURL =", url?.absoluteString as Any)
                
                guard let url else {
                    completion(.failure(MissionServiceError.failedToGetDownloadURL))
                    return
                }
                
                completion(.success(url.absoluteString))
            }
        }
    }
    
    // 対象のルームの記録日一覧を取る関数
    func fetchMyRecordDateKeys(
        roomId: String,
        completion: @escaping (Result<Set<String>, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(MissionServiceError.userNotSignedIn))
            return
        }
        
        fetchRecordDateKeys(roomId: roomId, userId: uid, completion: completion)
    }
    
    func fetchRecordsForRoom(
        roomId: String,
        completion: @escaping (Result<[MissionRecord], Error>) -> Void
    ) {
        db.collection("mission_records")
            .whereField("roomId", isEqualTo: roomId)
            .getDocuments { snapshot, error in
                
                if let error {
                    completion(.failure(error))
                    return
                }
                
                let records = snapshot?.documents.compactMap {
                    try? $0.data(as: MissionRecord.self)
                } ?? []
                
                completion(.success(records))
            }
    }
    
    func fetchMyRecord(
        roomId: String,
        date: Date,
        completion: @escaping (Result<MissionRecord?, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(MissionServiceError.userNotSignedIn))
            return
        }
        
        fetchRecord(roomId: roomId, userId: uid, date: date, completion: completion)
    }
    
    func fetchRecordDateKeys(
        roomId: String,
        userId: String,
        completion: @escaping (Result<Set<String>, Error>) -> Void
    ) {
        db.collection("mission_records")
            .whereField("roomId", isEqualTo: roomId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                
                if let error {
                    completion(.failure(error))
                    return
                }
                
                let dateKeys: Set<String> = Set(
                    snapshot?.documents.compactMap { document in
                        document.data()["dateKey"] as? String
                    } ?? []
                )
                
                completion(.success(dateKeys))
            }
    }
    
    func fetchRecord(
        roomId: String,
        userId: String,
        date: Date,
        completion: @escaping (Result<MissionRecord?, Error>) -> Void
    ) {
        let dateKey = Self.makeDateKey(from: date)
        let recordId = "\(roomId)_\(userId)_\(dateKey)"
        
        db.collection("mission_records")
            .document(recordId)
            .getDocument { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot, snapshot.exists else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    let record = try snapshot.data(as: MissionRecord.self)
                    completion(.success(record))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}

enum MissionServiceError: LocalizedError {
    case userNotSignedIn
    case failedToConvertImage
    case failedToUploadImage
    case failedToGetDownloadURL
    
    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "ログイン状態を確認できませんでした"
        case .failedToConvertImage:
            return "画像データの変換に失敗しました"
        case .failedToUploadImage:
            return "画像のアップロードに失敗しました"
        case .failedToGetDownloadURL:
            return "画像URLの取得に失敗しました"
        }
    }
}
