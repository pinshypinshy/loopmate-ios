//
//  MissionRecord.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import Foundation

struct MissionRecord: Codable {
    let roomId: String
    let userId: String
    let dateKey: String
    let value: Double?
    let comment: String
    let photoURL: String?
}
