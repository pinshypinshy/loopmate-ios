//
//  MissionView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

struct MissionView: View {
    
    @State private var missions: [TodayAllRoomsMissionData] = []
    @State private var isLoading = false
    
    private let missionService = MissionService()
    private let roomService = RoomService()
    private let authService = AuthService()
    
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
        guard let uid = try? authService.requireUid() else { return }

        isLoading = true

        Task {
            do {
                let rooms = try await roomService.fetchMyRooms()

                let today = Date()
                let todayRooms = rooms.filter { $0.isScheduled(on: today) }

                let records = try await missionService.fetchTodayRecords(uid: uid)
                isLoading = false
                let completedRoomIds = Set(records.map { $0.roomId })
                self.missions = todayRooms.map { room in
                    TodayAllRoomsMissionData(
                        id: room.id,
                        room: room,
                        isCompleted: completedRoomIds.contains(room.id)
                    )
                }
            } catch {
                isLoading = false
            }
        }
    }
}

#Preview {
    MissionView()
}
