//
//  FriendProfileView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/17.
//

import SwiftUI
import FirebaseAuth

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
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        friendService.fetchRelationState(myUid: myUid, otherUid: user.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let state):
                    relationState = state
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func sendFriendRequest() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isProcessing = true
        
        friendService.sendFriendRequest(fromUid: myUid, toUid: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    relationState = .outgoingPending
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func acceptFriendRequest() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isProcessing = true
        
        friendService.acceptFriendRequest(myUid: myUid, otherUid: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    relationState = .friend
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func rejectFriendRequest() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isProcessing = true
        
        friendService.rejectFriendRequest(myUid: myUid, otherUid: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    relationState = .none
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func removeFriend() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isProcessing = true
        
        friendService.removeFriend(myUid: myUid, otherUid: user.id) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success:
                    relationState = .none
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
