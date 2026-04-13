//
//  FriendView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI
import FirebaseAuth

struct FriendView: View {
    
    @State private var searchText = ""
    @State private var searchedUser: User?
    @State private var relationState: FriendRelationState = .none
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let userService = UserService()
    private let friendService = FriendService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let user = searchedUser {
                            HStack {
                                NavigationLink {
                                    FriendProfileView(user: user)
                                } label: {
                                    HStack {
                                        UserCellView(user: user)
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                relationButton(for: user)
                            }
                        } else if !searchText.isEmpty && !isSearching {
                            Text("ユーザーが見つかりません")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundStyle(.secondary)
                                .padding(.top)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                }
                .padding(.horizontal)
            }
            .navigationTitle("フレンド")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "ユーザーIDを検索"
            )
            .onSubmit(of: .search) {
                searchUser()
            }
            .onChange(of: searchText) { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmed.isEmpty {
                    searchedUser = nil
                    relationState = .none
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    FriendRequestBellButtonView()
                }
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func relationButton(for user: User) -> some View {
        switch relationState {
        case .none:
            Button {
                sendFriendRequest(to: user)
            } label: {
                Text("フレンド申請")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange))
            }
            .buttonStyle(.plain)
            
        case .outgoingPending:
            Text("申請済み")
                .font(.headline)
                .foregroundStyle(.orange)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
            
        case .incomingPending:
            Text("申請が届いています")
                .font(.headline)
                .foregroundStyle(.orange)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
            
        case .friend:
            Text("フレンド")
                .font(.headline)
                .foregroundStyle(.orange)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
        }
    }
    
    private func searchUser() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        relationState = .none
        
        guard !trimmed.isEmpty else {
            searchedUser = nil
            return
        }
        
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isSearching = true
        
        userService.fetchUserByUsernameKey(trimmed) { result in
            DispatchQueue.main.async {
                isSearching = false
                
                switch result {
                case .success(let user):
                    guard let user else {
                        searchedUser = nil
                        return
                    }
                    
                    if user.id == myUid {
                        searchedUser = nil
                        return
                    }
                    
                    searchedUser = user
                    fetchRelationState(for: user)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func fetchRelationState(for user: User) {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        
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
    
    private func sendFriendRequest(to user: User) {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        friendService.sendFriendRequest(fromUid: myUid, toUid: user.id) { result in
            DispatchQueue.main.async {
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
}
