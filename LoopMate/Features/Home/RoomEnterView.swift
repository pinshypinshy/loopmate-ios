//
//  RoomEnterView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/12.
//

import SwiftUI

struct RoomEnterView: View {
    
    let onJoin: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var foundRoom: Room? = nil
    @State private var isSearching = false
    @State private var isJoining = false
    @State private var hasSearched = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var isMember = false
    
    private let roomService = RoomService()
    
    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            ScrollView {
                VStack {
                    if isSearching {
                        ProgressView("検索中...")
                            .padding(.top, 40)
                    } else if let foundRoom {
                        SearchRoomCellView(
                            room: foundRoom,
                            isMember: isMember,
                            join: {
                                joinRoom(foundRoom)
                            }
                        )
                        .disabled(isJoining)
                        .padding(.top)
                    } else if hasSearched {
                        Text("該当するルームは見つかりませんでした")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    } else {
                        Text("ルームコードを入力して検索してください")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("ルームに参加")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "ルームコードを検索"
        )
        .onSubmit(of: .search) {
            searchRoom()
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func searchRoom() {
        let normalizedCode = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !normalizedCode.isEmpty else {
            foundRoom = nil
            hasSearched = false
            return
        }
        
        searchText = normalizedCode
        isSearching = true
        hasSearched = true
        foundRoom = nil
        
        roomService.searchRoom(byCode: normalizedCode) { result in
            DispatchQueue.main.async {
                isSearching = false
                
                switch result {
                case .success(let room):
                    roomService.isUserMember(of: room.id) { member in
                        DispatchQueue.main.async {
                            foundRoom = room
                            isMember = member
                        }
                    }
                    
                case .failure(let error):
                    if let roomError = error as? RoomServiceError,
                       roomError == .roomNotFound {
                        foundRoom = nil
                    } else {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func joinRoom(_ room: Room) {
        isJoining = true
        
        roomService.joinRoom(roomId: room.id) { result in
            DispatchQueue.main.async {
                isJoining = false
                
                switch result {
                case .success(let roomId):
                    isMember = true
                    onJoin(roomId)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RoomEnterView(onJoin: { _ in })
    }
}
