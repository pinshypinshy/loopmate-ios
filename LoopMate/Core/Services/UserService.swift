//
//  UserService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import Foundation
import FirebaseFirestore

final class UserService {
    
    private let db = Firestore.firestore()
    
    func fetchUsers(
        uids: [String],
        completion: @escaping ([User]) -> Void
    ) {
        let group = DispatchGroup()
        var users: [User] = []
        
        for uid in uids {
            group.enter()
            
            db.collection("users").document(uid).getDocument { snapshot, _ in
                defer { group.leave() }
                
                guard
                    let data = snapshot?.data(),
                    let displayName = data["displayName"] as? String,
                    let username = data["username"] as? String,
                    let usernameKey = data["usernameKey"] as? String,
                    let iconName = data["iconName"] as? String
                else { return }
                
                users.append(User(
                    id: uid,
                    displayName: displayName,
                    username: username,
                    usernameKey: usernameKey,
                    iconName: iconName
                ))
            }
        }
        
        group.notify(queue: .main) {
            completion(users)
        }
    }
    
    func fetchUserByUsernameKey(
        _ searchedUsernameKey: String,
        completion: @escaping (Result<User?, Error>) -> Void
    ) {
        db.collection("users")
            .whereField("usernameKey", isEqualTo: searchedUsernameKey)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }
                
                let data = document.data()
                
                guard
                    let displayName = data["displayName"] as? String,
                    let username = data["username"] as? String,
                    let usernameKey = data["usernameKey"] as? String,
                    let iconName = data["iconName"] as? String
                else {
                    completion(.success(nil))
                    return
                }
                
                let user = User(
                    id: document.documentID,
                    displayName: displayName,
                    username: username,
                    usernameKey: usernameKey,
                    iconName: iconName
                )
                
                completion(.success(user))
            }
    }
    
    func isUsernameAvailable(
        _ username: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let usernameKey = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        db.collection("users")
            .whereField("usernameKey", isEqualTo: usernameKey)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let isAvailable = snapshot?.documents.isEmpty ?? true
                completion(.success(isAvailable))
            }
    }
    
    func checkUserProfileExists(
        uid: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let exists = snapshot?.exists ?? false
            completion(.success(exists))
        }
    }
}
