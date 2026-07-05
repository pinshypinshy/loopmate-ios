//
//  BlockedUsersView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/07/05.
//

import SwiftUI

/// ブロックしたユーザーの一覧と解除を行う画面。
struct BlockedUsersView: View {

    @State private var blockedUsers: [User] = []
    @State private var isLoading = false
    @State private var processingUid: String?
    @State private var errorMessage = ""
    @State private var showErrorAlert = false

    private let blockService = BlockService()

    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()

            Group {
                if isLoading {
                    ProgressView()
                } else if blockedUsers.isEmpty {
                    Text("ブロックしたユーザーはいません")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(blockedUsers) { user in
                                HStack {
                                    UserCellView(user: user)

                                    Button {
                                        unblock(user)
                                    } label: {
                                        if processingUid == user.id {
                                            ProgressView()
                                        } else {
                                            Text("解除")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundStyle(.orange)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule().fill(Color.gray.opacity(0.2))
                                                )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(processingUid != nil)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("ブロックしたユーザー")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBlockedUsers()
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func loadBlockedUsers() {
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                blockedUsers = try await blockService.fetchBlockedUsers()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func unblock(_ user: User) {
        processingUid = user.id

        Task {
            defer { processingUid = nil }
            do {
                try await blockService.unblockUser(user.id)
                blockedUsers.removeAll { $0.id == user.id }
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        BlockedUsersView()
    }
}
