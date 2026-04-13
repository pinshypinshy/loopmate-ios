//
//  FriendListView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI
import FirebaseAuth

struct FriendListView: View {
    
    @State private var friends: [User] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let friendService = FriendService()
    private let userService = UserService()
    
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
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        friendService.fetchFriendIds(uid: myUid) { result in
            switch result {
            case .success(let friendIds):
                if friendIds.isEmpty {
                    DispatchQueue.main.async {
                        isLoading = false
                        friends = []
                    }
                    return
                }
                
                userService.fetchUsers(uids: friendIds) { users in
                    DispatchQueue.main.async {
                        isLoading = false
                        friends = users
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
