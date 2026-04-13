//
//  HomeView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

private enum AppRoute: Hashable {
    case roomCreationFlow
    case roomEnter
    case room(roomId: String, completionRoom: Room?)
    case roomMenu(room: Room)
}

struct HomeView: View {
    
    @State private var rooms: [Room] = []
    @State private var isFabMenuOpen = false
    @State private var path: [AppRoute] = []
    @State private var isLoadingRooms = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    //@State private var recentlyCreatedRoom: Room? = nil
    @State private var progressMap: [String: String] = [:]

    private let progressService = ProgressService()
    private let roomService = RoomService()
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
                
                
                ScrollView {
                    if isLoadingRooms {
                        ProgressView("読み込み中...")
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else if rooms.isEmpty {
                        Text("参加中のルームはまだありません")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 18) {
                            ForEach(rooms) { room in
                                Button {
                                    path.append(.room(roomId: room.id, completionRoom: nil))
                                } label: {
                                    HomeRoomCellView(
                                        room: room,
                                        progressText: progressMap[room.id] ?? "達成状況 0%"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                
                
                if isFabMenuOpen {
                    RoomAddMenuView(
                        onCreate: {
                            isFabMenuOpen = false
                            path.append(.roomCreationFlow)
                        },
                        onJoin: {
                            isFabMenuOpen = false
                            print("ルームに入る")
                            path.append(.roomEnter)
                        }
                    )
                    .padding(.trailing, 20)
                    .padding(.bottom, 20 + 80)
                }
                
                FloatingPlusButton {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        isFabMenuOpen.toggle()
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isFabMenuOpen {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isFabMenuOpen = false
                    }
                }
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FriendRequestBellButtonView()
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .roomCreationFlow:
                    RoomCreationFlowHostView(
                        onCreateCompleted: { createdRoom in
                            path = [.room(roomId: createdRoom.id, completionRoom: createdRoom)]
                        }
                    )

                case .roomEnter:
                    RoomEnterView(
                        onJoin: { roomId in
                            path = [.room(roomId: roomId, completionRoom: nil)]
                        }
                    )

                case .room(let roomId, let completionRoom):
                    RoomView(
                        roomId: roomId,
                        onBack: {
                            path.removeAll()
                            loadRooms()
                        },
                        onLeaveRoom: {
                            path.removeAll()
                            loadRooms()
                        },
                        onOpenMenu: { room in
                            path.append(.roomMenu(room: room))
                        },
                        completionRoom: completionRoom
                    )
                case .roomMenu(let room):
                    RoomMenuView(
                        room: room,
                        onLeaveCompleted: {
                            path.removeAll()
                            loadRooms()
                        }
                    )
                }
            }
            .onAppear {
                loadRooms()
            }
        }
        .alert("ルーム一覧の取得に失敗しました", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadRooms() {
        isLoadingRooms = true
        
        roomService.fetchMyRooms { result in
            DispatchQueue.main.async {
                isLoadingRooms = false
                
                switch result {
                case .success(let fetchedRooms):
                    rooms = fetchedRooms
                    loadProgresses(for: fetchedRooms)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadProgresses(for rooms: [Room]) {
        progressMap = [:]
        
        for room in rooms {
            progressService.fetchMyProgressRate(room: room) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let rate):
                        let percent = Int((rate * 100).rounded())
                        progressMap[room.id] = "達成状況 \(percent)%"
                        
                    case .failure:
                        progressMap[room.id] = "達成状況 --%"
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
