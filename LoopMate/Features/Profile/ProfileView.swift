//
//  ProfileView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

struct ProfileView: View {

    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var iconName: String = "person.crop.circle.fill"
    @State private var friendCount: Int = 0
    @State private var errorMessage = ""
    @State private var showErrorAlert = false

    private let userService = UserService()
    private let friendService = FriendService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: iconName)
                                .font(.system(size: 92))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayName.isEmpty ? "表示名未設定" : displayName)
                                    .font(.title2)
                                    .bold()
                                    .padding(.top, 4)
                                Text(username.isEmpty ? "@unknown" : "@\(username)")
                                    .font(.headline)
                                
                                NavigationLink {
                                    FriendListView()
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("\(friendCount)")
                                            .font(.footnote)
                                            .bold()
                                        Text("フレンド")
                                            .font(.footnote)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 12)
                            }
                            Spacer()
                            
                        }
                        .padding(.horizontal)
                        
                        NavigationLink {
                            ProfileEditView(
                                displayName: $displayName,
                                iconName: $iconName
                            )
                        } label: {
                            Text("プロフィールを編集")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                        
                    }
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FriendRequestBellButtonView()
                }
            }
        }
        .onAppear {
            fetchProfile()
            fetchFriendCount()
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func fetchProfile() {
        Task {
            do {
                guard let user = try await userService.fetchCurrentUser() else { return }

                username = user.username
                displayName = user.displayName
                iconName = user.iconName
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func fetchFriendCount() {
        Task {
            do {
                friendCount = try await friendService.fetchFriendIds().count
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    ProfileView()
}
