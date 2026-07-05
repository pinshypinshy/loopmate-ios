//
//  FriendRequestsView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI

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
        isLoading = true
        
        Task {
            defer { isLoading = false }
            do {
                requests = try await friendService.fetchIncomingFriendRequests()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func accept(_ request: FriendRequest) {
        Task {
            do {
                try await friendService.acceptFriendRequest(otherUid: request.fromUid)
                requests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func reject(_ request: FriendRequest) {
        Task {
            do {
                try await friendService.rejectFriendRequest(otherUid: request.fromUid)
                requests.removeAll { $0.id == request.id }
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
