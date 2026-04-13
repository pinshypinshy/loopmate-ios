//
//  FriendRequest.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import Foundation
import FirebaseFirestore

struct FriendRequest: Identifiable, Hashable {
    let id: String
    let fromUid: String
    let toUid: String
    let status: String
    let createdAt: Timestamp
    let user: User
}
