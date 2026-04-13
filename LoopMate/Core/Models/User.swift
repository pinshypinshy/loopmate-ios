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
    static let preview = User(
        id: "testuser",
        displayName: "プレビュー用",
        username: "testuser",
        usernameKey: "testuser",
        iconName: "person.crop.circle.fill"
    )
}
