//
//  ProgressService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import Foundation

final class ProgressService {

    private let roomService = RoomService()
    private let missionService = MissionService()
    private let authService = AuthService()

    /// 指定ルームにおける自分の達成率を取得する。
    /// - Parameter room: 対象ルーム。
    /// - Returns: 予定日に対する達成日の割合（0.0〜1.0）。未参加や予定日ゼロの場合は 0。
    /// - Throws: 未認証の場合は `AuthError.notAuthenticated`、取得失敗時は Firestore エラー。
    func fetchMyProgressRate(room: Room) async throws -> Double {
        guard let uid = authService.currentUid else {
            throw AuthError.notAuthenticated
        }

        let members = try await roomService.fetchRoomMembers(roomId: room.id)

        guard let me = members.first(where: { $0.id == uid }) else {
            return 0
        }

        let records = try await missionService.fetchRecordsForRoom(roomId: room.id)

        return calculateRate(member: me, records: records, room: room)
    }

    /// メンバーの参加日から今日までの予定日を数え、記録済み日との比率で達成率を算出する。
    /// - Parameters:
    ///   - member: 対象メンバー（参加日を達成期間の起点に使用）。
    ///   - records: ルーム全体のミッション記録（内部でメンバー分に絞り込む）。
    ///   - room: 開始日・終了日・曜日設定を参照する対象ルーム。
    /// - Returns: 達成率（0.0〜1.0）。予定日が存在しない場合は 0。
    private func calculateRate(
        member: RoomMember,
        records: [MissionRecord],
        room: Room
    ) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: max(member.joinedAt, room.startDateValue))

        if start > today {
            return 0
        }

        let memberRecordKeys = Set(
            records
                .filter { $0.userId == member.id }
                .map { $0.dateKey }
        )

        var totalCount = 0
        var doneCount = 0
        var currentDate = start

        while currentDate <= today {
            if isScheduledDate(currentDate, room: room) {
                totalCount += 1

                let key = dateKey(from: currentDate)
                if memberRecordKeys.contains(key) {
                    doneCount += 1
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        if totalCount == 0 {
            return 0
        }

        return Double(doneCount) / Double(totalCount)
    }

    /// 指定日がルームのミッション予定日かどうかを判定する。
    /// - Parameters:
    ///   - date: 判定対象の日付。
    ///   - room: 開始日・終了日・曜日設定を参照する対象ルーム。
    /// - Returns: 期間内かつ該当曜日が有効なら `true`。
    private func isScheduledDate(_ date: Date, room: Room) -> Bool {
        let calendar = Calendar(identifier: .gregorian)

        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: room.startDateValue)

        if targetDate < startDate {
            return false
        }

        if let endDate = room.endDateValue {
            let endDay = calendar.startOfDay(for: endDate)
            if targetDate > endDay {
                return false
            }
        }

        let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1

        guard room.selectedWeekdays.indices.contains(weekdayIndex) else {
            return false
        }

        return room.selectedWeekdays[weekdayIndex]
    }

    /// 日付を記録照合用のキー文字列（`yyyy-MM-dd`、Asia/Tokyo 基準）に変換する。
    /// - Parameter date: 変換対象の日付。
    /// - Returns: `yyyy-MM-dd` 形式の日付キー。
    private func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
