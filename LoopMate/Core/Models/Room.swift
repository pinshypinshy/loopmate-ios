//
//  Room.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import Foundation
import FirebaseFirestore

struct Room: Identifiable, Hashable {
    let id: String
    let name: String
    let code: String
    let memberCount: Int
    let ownerUid: String
    let createdAt: Timestamp
    let updatedAt: Timestamp
    let iconName: String
    let isNumberRequired: Bool
    let isPhotoRequired: Bool
    let startDate: Timestamp
    let endDate: Timestamp?
    let selectedWeekdays: [Bool]

    // 今は Firestore に progress がないので、一覧表示用に仮で持たせる
    let progress: Int

    init(
        id: String,
        name: String,
        code: String,
        memberCount: Int,
        ownerUid: String,
        createdAt: Timestamp,
        updatedAt: Timestamp,
        iconName: String,
        isNumberRequired: Bool,
        isPhotoRequired: Bool,
        startDate: Timestamp,
        endDate: Timestamp?,
        selectedWeekdays: [Bool],
        progress: Int
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.memberCount = memberCount
        self.ownerUid = ownerUid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.iconName = iconName
        self.isNumberRequired = isNumberRequired
        self.isPhotoRequired = isPhotoRequired
        self.startDate = startDate
        self.endDate = endDate
        self.progress = progress
        // 必ず7要素（日〜土）になるよう補正する
        let padded = selectedWeekdays + Array(repeating: false, count: max(0, 7 - selectedWeekdays.count))
        self.selectedWeekdays = Array(padded.prefix(7))
    }
}

extension Room {
    /// Firestore の DocumentSnapshot から Room を生成する
    init?(snapshot: DocumentSnapshot) {
        guard
            let data = snapshot.data(),
            let name = data["name"] as? String,
            let code = data["code"] as? String,
            let memberCount = data["memberCount"] as? Int,
            let ownerUid = data["ownerUid"] as? String,
            let createdAt = data["createdAt"] as? Timestamp,
            let updatedAt = data["updatedAt"] as? Timestamp,
            let isNumberRequired = data["isNumberRequired"] as? Bool,
            let isPhotoRequired = data["isPhotoRequired"] as? Bool,
            let startDate = data["startDate"] as? Timestamp,
            let selectedWeekdays = data["selectedWeekdays"] as? [Bool]
        else { return nil }

        let iconName = data["iconName"] as? String ?? "checkmark.circle"
        let endDate = data["endDate"] as? Timestamp

        self.init(
            id: snapshot.documentID,
            name: name,
            code: code,
            memberCount: memberCount,
            ownerUid: ownerUid,
            createdAt: createdAt,
            updatedAt: updatedAt,
            iconName: iconName,
            isNumberRequired: isNumberRequired,
            isPhotoRequired: isPhotoRequired,
            startDate: startDate,
            endDate: endDate,
            selectedWeekdays: selectedWeekdays,
            progress: 0
        )
    }

    static let preview = Room(
        id: "preview",
        name: "テストルーム",
        code: "ABC12",
        memberCount: 5,
        ownerUid: "preview_uid",
        createdAt: Timestamp(date: Date()),
        updatedAt: Timestamp(date: Date()),
        iconName: "checkmark.circle",
        isNumberRequired: false,
        isPhotoRequired: false,
        startDate: Timestamp(date: Date()),
        endDate: nil,
        selectedWeekdays: [false, true, false, true, false, true, false],
        progress: 0
    )
    
    var progressText: String {
        "達成状況 \(progress)%"
    }
    
    var startDateValue: Date {
        startDate.dateValue()
    }
    
    var endDateValue: Date? {
        endDate?.dateValue()
    }

    /// 指定した日にこの部屋のミッションが実施対象かどうかを判定する
    /// （曜日・開始日・終了日の条件をすべて満たすとき true）
    func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let weekday = calendar.component(.weekday, from: date) - 1 // 日曜=0

        guard weekday < selectedWeekdays.count, selectedWeekdays[weekday] else { return false }

        if startDateValue > date { return false }

        if let end = endDateValue, date > end { return false }

        return true
    }
}
