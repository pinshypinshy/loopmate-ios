//
//  FriendListView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI

struct FriendListView: View {
    
    @State private var friends: [User] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let friendService = FriendService()
    private let userService = UserService()
    private let blockService = BlockService()
    
    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView()
                } else if friends.isEmpty {
                    Text("フレンドはいません")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(friends) { user in
                                NavigationLink {
                                    FriendProfileView(user: user)
                                } label: {
                                    HStack {
                                        UserCellView(user: user)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("フレンド")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchFriends()
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func fetchFriends() {
        isLoading = true
        
        Task {
            defer { isLoading = false }
            do {
                let friendIds = try await friendService.fetchFriendIds()

                guard !friendIds.isEmpty else {
                    friends = []
                    return
                }

                let blockedUids = try await blockService.fetchBlockedUids()
                let visibleIds = friendIds.filter { !blockedUids.contains($0) }

                friends = await userService.fetchUsers(uids: visibleIds)
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
