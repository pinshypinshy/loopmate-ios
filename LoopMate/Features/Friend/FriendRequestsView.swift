//
//  FriendRequestsView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI
import FirebaseAuth

struct FriendRequestsView: View {
    
    @State private var requests: [FriendRequest] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let friendService = FriendService()
    
    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView()
                } else if requests.isEmpty {
                    Text("通知はありません")
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(requests) { request in
                                FriendRequestCellView(
                                    request: request,
                                    onAccept: {
                                        accept(request)
                                    },
                                    onReject: {
                                        reject(request)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchRequests()
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func fetchRequests() {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        friendService.fetchIncomingFriendRequests(myUid: myUid) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let requests):
                    self.requests = requests
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func accept(_ request: FriendRequest) {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        friendService.acceptFriendRequest(
            myUid: myUid,
            otherUid: request.fromUid
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    requests.removeAll { $0.id == request.id }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func reject(_ request: FriendRequest) {
        guard let myUid = Auth.auth().currentUser?.uid else {
            errorMessage = "ログイン状態を確認できませんでした"
            showErrorAlert = true
            return
        }
        
        friendService.rejectFriendRequest(
            myUid: myUid,
            otherUid: request.fromUid
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    requests.removeAll { $0.id == request.id }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
