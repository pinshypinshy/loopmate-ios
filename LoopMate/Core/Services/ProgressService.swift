//
//  ProgressService.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import Foundation
import FirebaseAuth

final class ProgressService {
    
    private let roomService = RoomService()
    private let missionService = MissionService()
    
    func fetchMyProgressRate(
        room: Room,
        completion: @escaping (Result<Double, Error>) -> Void
    ) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(RoomServiceError.userNotSignedIn))
            return
        }
        
        roomService.fetchRoomMembers(roomId: room.id) { memberResult in
            switch memberResult {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let members):
                guard let me = members.first(where: { $0.id == uid }) else {
                    completion(.success(0))
                    return
                }
                
                self.missionService.fetchRecordsForRoom(roomId: room.id) { recordResult in
                    switch recordResult {
                    case .failure(let error):
                        completion(.failure(error))
                        
                    case .success(let records):
                        let rate = self.calculateRate(
                            member: me,
                            records: records,
                            room: room
                        )
                        completion(.success(rate))
                    }
                }
            }
        }
    }
    
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
    
    private func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
