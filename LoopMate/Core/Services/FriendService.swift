//
//  FriendService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import Foundation
import FirebaseFirestore

final class FriendService {
    
    private let db = Firestore.firestore()
    
    func fetchRelationState(
        myUid: String,
        otherUid: String,
        completion: @escaping (Result<FriendRelationState, Error>) -> Void
    ) {
        let myFriendRef = db.collection("users")
            .document(myUid)
            .collection("friends")
            .document(otherUid)
        
        myFriendRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if snapshot?.exists == true {
                completion(.success(.friend))
                return
            }
            
            self.db.collection("friendRequests")
                .document("\(myUid)_\(otherUid)")
                .getDocument { outgoingSnapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    if
                        let data = outgoingSnapshot?.data(),
                        let status = data["status"] as? String,
                        status == "pending"
                    {
                        completion(.success(.outgoingPending))
                        return
                    }
                    
                    self.db.collection("friendRequests")
                        .document("\(otherUid)_\(myUid)")
                        .getDocument { incomingSnapshot, error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            if
                                let data = incomingSnapshot?.data(),
                                let status = data["status"] as? String,
                                status == "pending"
                            {
                                completion(.success(.incomingPending))
                                return
                            }
                            
                            completion(.success(.none))
                        }
                }
        }
    }
    
    func sendFriendRequest(
        fromUid: String,
        toUid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        fetchRelationState(myUid: fromUid, otherUid: toUid) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let state):
                guard state == .none else {
                    completion(.success(()))
                    return
                }
                
                let requestId = "\(fromUid)_\(toUid)"
                let requestRef = self.db.collection("friendRequests").document(requestId)
                
                let data: [String: Any] = [
                    "fromUid": fromUid,
                    "toUid": toUid,
                    "status": "pending",
                    "createdAt": Timestamp(date: Date())
                ]
                
                requestRef.setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(()))
                }
            }
        }
    }
    
    func fetchIncomingFriendRequests(
        myUid: String,
        completion: @escaping (Result<[FriendRequest], Error>) -> Void
    ) {
        db.collection("friendRequests")
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let documents = snapshot?.documents ?? []
                
                if documents.isEmpty {
                    completion(.success([]))
                    return
                }
                
                let group = DispatchGroup()
                var requests: [FriendRequest] = []
                var firstError: Error?
                
                for document in documents {
                    let data = document.data()
                    
                    guard
                        let fromUid = data["fromUid"] as? String,
                        let toUid = data["toUid"] as? String,
                        let status = data["status"] as? String,
                        let createdAt = data["createdAt"] as? Timestamp
                    else {
                        continue
                    }
                    
                    group.enter()
                    
                    self.db.collection("users").document(fromUid).getDocument { userSnapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            if firstError == nil {
                                firstError = error
                            }
                            return
                        }
                        
                        guard
                            let userData = userSnapshot?.data(),
                            let displayName = userData["displayName"] as? String,
                            let username = userData["username"] as? String,
                            let usernameKey = userData["usernameKey"] as? String,
                            let iconName = userData["iconName"] as? String
                        else {
                            return
                        }
                        
                        let user = User(
                            id: fromUid,
                            displayName: displayName,
                            username: username,
                            usernameKey: usernameKey,
                            iconName: iconName
                        )
                        
                        let request = FriendRequest(
                            id: document.documentID,
                            fromUid: fromUid,
                            toUid: toUid,
                            status: status,
                            createdAt: createdAt,
                            user: user
                        )
                        
                        requests.append(request)
                    }
                }
                
                group.notify(queue: .main) {
                    if let firstError {
                        completion(.failure(firstError))
                    } else {
                        requests.sort { $0.createdAt.dateValue() > $1.createdAt.dateValue() }
                        completion(.success(requests))
                    }
                }
            }
    }

    func acceptFriendRequest(
        myUid: String,
        otherUid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
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
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }

    func rejectFriendRequest(
        myUid: String,
        otherUid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("friendRequests")
            .document("\(otherUid)_\(myUid)")
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(()))
            }
    }
    
    func fetchFriendIds(
        uid: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        db.collection("users")
            .document(uid)
            .collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let friendIds = documents.map { $0.documentID }
                completion(.success(friendIds))
            }
    }
    
    func removeFriend(
        myUid: String,
        otherUid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
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
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    func fetchIncomingFriendRequestCount(
        myUid: String,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        db.collection("friendRequests")
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                completion(.success(snapshot?.documents.count ?? 0))
            }
    }
}
