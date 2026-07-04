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
    
    func fetchUsers(uids: [String]) async -> [User] {
        await withTaskGroup(of: User?.self) { group in
            for uid in uids {
                group.addTask {
                    let snapshot = try? await self.db.collection("users").document(uid).getDocument()

                    guard let data = snapshot?.data() else { return nil }

                    return User(id: uid, data: data)
                }
            }

            var users: [User] = []
            for await user in group {
                if let user {
                    users.append(user)
                }
            }
            return users
        }
    }

    func fetchUserByUsernameKey(_ searchedUsernameKey: String) async throws -> User? {
        let snapshot = try await db.collection("users")
            .whereField("usernameKey", isEqualTo: searchedUsernameKey)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else { return nil }

        return User(id: document.documentID, data: document.data())
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let usernameKey = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let snapshot = try await db.collection("users")
            .whereField("usernameKey", isEqualTo: usernameKey)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.isEmpty
    }
    
    func checkUserProfileExists(uid: String) async throws -> Bool {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return snapshot.exists
    }
}
