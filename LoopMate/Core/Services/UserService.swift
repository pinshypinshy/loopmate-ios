//
//  UserService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import Foundation
import FirebaseFirestore

/// ユーザー情報まわりで発生するエラー。
enum UserError: LocalizedError {
    /// ユーザーIDが不正な形式（小文字英数字と _ 以外を含む）。
    case invalidUsername
    /// 指定したユーザーIDがすでに他ユーザーに使われている。
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "ユーザーIDは小文字英数字と_のみ使用できます"
        case .usernameTaken:
            return "このユーザーIDはすでに使われています"
        }
    }
}

final class UserService {

    private let db = Firestore.firestore()
    private let authService = AuthService()

    /// ログイン中のユーザー自身のプロフィールを取得する。
    /// プロフィール未登録などでドキュメントが存在しなければ nil を返す。
    func fetchCurrentUser() async throws -> User? {
        let uid = try authService.requireUid()
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard let data = snapshot.data() else { return nil }
        return User(id: uid, data: data)
    }

    /// ログイン中のユーザーの表示名とアイコンを更新する。
    /// ユーザーIDは変更しないため、該当フィールドのみ部分更新する。
    func updateProfile(displayName: String, iconName: String) async throws {
        let uid = try authService.requireUid()
        try await db.collection("users").document(uid).updateData([
            "displayName": displayName,
            "iconName": iconName
        ])
    }

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

    /// ユーザープロフィールを保存する。
    /// 同じ usernameKey を自分以外のユーザーが使っていれば `UserError.usernameTaken` を throw する。
    func saveUserProfile(uid: String, username: String, displayName: String, iconName: String) async throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameKey = trimmedUsername.lowercased()

        guard User.isValidUsername(trimmedUsername) else {
            throw UserError.invalidUsername
        }

        let snapshot = try await db.collection("users")
            .whereField("usernameKey", isEqualTo: usernameKey)
            .getDocuments()

        let existsOtherUser = snapshot.documents.contains { $0.documentID != uid }
        if existsOtherUser {
            throw UserError.usernameTaken
        }

        let data: [String: Any] = [
            "username": trimmedUsername,
            "usernameKey": usernameKey,
            "displayName": trimmedDisplayName,
            "iconName": iconName
        ]

        try await db.collection("users").document(uid).setData(data)
    }
}
