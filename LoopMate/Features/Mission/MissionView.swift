//
//  MissionView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MissionView: View {
    
    @State private var missions: [TodayAllRoomsMissionData] = []
    @State private var isLoading = false
    
    private let missionService = MissionService()
    private let roomService = RoomService()
    
    var incompleteMissions: [TodayAllRoomsMissionData] {
        missions.filter { !$0.isCompleted }
    }

    var completedMissions: [TodayAllRoomsMissionData] {
        missions.filter { $0.isCompleted }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        
                        Text("未実施")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        VStack(spacing: 18) {
                            ForEach(incompleteMissions) { mission in
                                NavigationLink(destination: MissionCompletionView(room: mission.room)) {
                                    MissionCellView(mission: mission)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Text("実施済み")
                            .font(.headline)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                        
                        VStack(spacing: 18) {
                            ForEach(completedMissions) { mission in
                                MissionCellView(mission: mission)
                                    .opacity(0.6)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("今日のミッション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FriendRequestBellButtonView()
                }
            }
            .onAppear {
                loadMissions()
            }
        }
    }
    
    private func loadMissions() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        roomService.fetchMyRooms { result in
            switch result {
            case .failure:
                isLoading = false
                
            case .success(let rooms):
                
                let todayRooms = filterTodayRooms(rooms)
                
                missionService.fetchTodayRecords(uid: uid) { recordResult in
                    
                    isLoading = false
                    
                    switch recordResult {
                    case .failure:
                        break
                        
                    case .success(let records):
                        
                        let completedRoomIds = Set(records.map { $0.roomId })
                        
                        self.missions = todayRooms.map { room in
                            TodayAllRoomsMissionData(
                                id: room.id,
                                room: room,
                                isCompleted: completedRoomIds.contains(room.id)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func filterTodayRooms(_ rooms: [Room]) -> [Room] {
        
        let calendar = Calendar(identifier: .gregorian)
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today) - 1 // 日曜=0
        
        return rooms.filter { room in
            
            guard room.selectedWeekdays[weekday] else { return false }
            
            if room.startDate.dateValue() > today {
                return false
            }

            if let end = room.endDate, today > end.dateValue() {
                return false
            }
            
            return true
        }
    }
}

#Preview {
    MissionView()
}
