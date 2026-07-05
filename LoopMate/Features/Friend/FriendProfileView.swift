//
//  FriendProfileView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import SwiftUI

struct FriendProfileView: View {
    
    let user: User
    
    @State private var relationState: FriendRelationState = .none
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    @State private var isProcessing = false
    
    private let friendService = FriendService()
    
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
                if relationState == .friend {
                    Menu {
                        Button(role: .destructive) {
                            removeFriend()
                        } label: {
                            Text("フレンド解除")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
        }
        .onAppear {
            fetchRelationState()
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
}
