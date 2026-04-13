//
//  TodayAllRoomsMissionData.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/05.
//

import Foundation

struct TodayAllRoomsMissionData: Identifiable {
    let id: String
    let room: Room
    let isCompleted: Bool
    
    var roomID: String { room.id }
    var roomName: String { room.name }
}

extension TodayAllRoomsMissionData {
    static let preview = TodayAllRoomsMissionData(
        id: "preview",
        room: .preview,
        isCompleted: false
    )
}
