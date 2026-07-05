//
//  FriendProfileView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import SwiftUI

struct FriendProfileView: View {
    
    let user: User

    @Environment(\.dismiss) private var dismiss

    @State private var relationState: FriendRelationState = .none
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var isProcessing = false
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false

    private let friendService = FriendService()
    private let blockService = BlockService()
    
    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: user.iconName)
                            .font(.system(size: 92))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.title2)
                                .bold()
                                .padding(.top, 4)
                            
                            Text("@\(user.username)")
                                .font(.headline)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    relationSection
                }
                .padding(.top)
            }
            
            if isProcessing {
                ProgressView()
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    if relationState == .friend {
                        Button(role: .destructive) {
                            removeFriend()
                        } label: {
                            Label("フレンド解除", systemImage: "person.badge.minus")
                        }
                    }

                    Button {
                        showReportSheet = true
                    } label: {
                        Label("通報", systemImage: "exclamationmark.bubble")
                    }

                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("ブロック", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .onAppear {
            fetchRelationState()
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(reportedUid: user.id, contextType: .user)
        }
        .alert("このユーザーをブロックしますか？", isPresented: $showBlockConfirm) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロック", role: .destructive) {
                blockUser()
            }
        } message: {
            Text("ブロックすると、お互いのフレンド関係は解除され、相手のコンテンツは表示されなくなります。")
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var relationSection: some View {
        switch relationState {
        case .none:
            Button {
                sendFriendRequest()
            } label: {
                Text("フレンド申請")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .disabled(isProcessing)
            
        case .outgoingPending:
            Button {
                
            } label: {
                Text("申請済み")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .disabled(true)
            
        case .incomingPending:
            HStack(spacing: 12) {
                Button {
                    acceptFriendRequest()
                } label: {
                    Text("承認")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                
                Button {
                    rejectFriendRequest()
                } label: {
                    Text("拒否")
                        .font(.subheadline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }
            .padding(.horizontal)
            
        case .friend:
            Button {
                
            } label: {
                Text("フレンド")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .disabled(true)
        }
    }
    
    private func fetchRelationState() {
        Task {
            do {
                relationState = try await friendService.fetchRelationState(otherUid: user.id)
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func sendFriendRequest() {
        isProcessing = true
        
        Task {
            defer { isProcessing = false }
            do {
                try await friendService.sendFriendRequest(toUid: user.id)
                relationState = .outgoingPending
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func acceptFriendRequest() {
        isProcessing = true
        
        Task {
            defer { isProcessing = false }
            do {
                try await friendService.acceptFriendRequest(otherUid: user.id)
                relationState = .friend
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func rejectFriendRequest() {
        isProcessing = true
        
        Task {
            defer { isProcessing = false }
            do {
                try await friendService.rejectFriendRequest(otherUid: user.id)
                relationState = .none
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func removeFriend() {
        isProcessing = true

        Task {
            defer { isProcessing = false }
            do {
                try await friendService.removeFriend(otherUid: user.id)
                relationState = .none
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func blockUser() {
        isProcessing = true

        Task {
            defer { isProcessing = false }
            do {
                try await blockService.blockUser(user.id)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
