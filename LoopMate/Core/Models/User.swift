//
//  User.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/05.
//

import Foundation

struct User: Identifiable, Hashable {
    let id: String
    let displayName: String
    let username: String
    let usernameKey: String
    let iconName: String
}

extension User {
    init?(id: String, data: [String: Any]) {
        guard
            let displayName = data["displayName"] as? String,
            let username = data["username"] as? String,
            let usernameKey = data["usernameKey"] as? String,
            let iconName = data["iconName"] as? String
        else { return nil }

        self.init(
            id: id,
            displayName: displayName,
            username: username,
            usernameKey: usernameKey,
            iconName: iconName
        )
    }

    static let preview = User(
        id: "testuser",
        displayName: "プレビュー用",
        username: "testuser",
        usernameKey: "testuser",
        iconName: "person.crop.circle.fill"
    )

    /// ユーザーIDに使用できる文字（小文字英数字と _）。検証・入力フィルタの唯一の定義。
    private static let allowedUsernameCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789_")

    /// 入力文字列を小文字化し、ユーザーIDに使えない文字を取り除く。
    static func sanitizeUsername(_ input: String) -> String {
        input.lowercased().filter { allowedUsernameCharacters.contains($0) }
    }

    /// ユーザーIDとして使える文字列か判定する（空でなく、許可文字のみ）。
    static func isValidUsername(_ username: String) -> Bool {
        !username.isEmpty && username.allSatisfy { allowedUsernameCharacters.contains($0) }
    }
}
