//
//  FriendRequestBellButtonView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/04/10.
//

import SwiftUI
import FirebaseAuth

struct FriendRequestBellButtonView: View {
    
    @State private var requestCount: Int = 0
    
    private let friendService = FriendService()
    
    var previewCount: Int? = nil
    
    var body: some View {
        NavigationLink {
            FriendRequestsView()
        } label: {
            ZStack(alignment: .topTrailing) {
                
                ZStack {
                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                if displayCount > 0 {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.23, blue: 0.19))
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .offset(x: -8, y: 8)
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .task {
            fetchRequestCount()
        }
        .onAppear {
            fetchRequestCount()
        }
    }
    
    private var displayCount: Int {
        previewCount ?? requestCount
    }
    
    private func fetchRequestCount() {
        if previewCount != nil { return }
        
        guard let myUid = Auth.auth().currentUser?.uid else {
            requestCount = 0
            return
        }
        
        friendService.fetchIncomingFriendRequests(myUid: myUid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let requests):
                    requestCount = requests.count
                case .failure:
                    requestCount = 0
                }
            }
        }
    }
}

#Preview("リクエストなし") {
    NavigationStack {
        FriendRequestBellButtonView(previewCount: 0)
            .padding()
    }
}

#Preview("リクエストあり") {
    NavigationStack {
        FriendRequestBellButtonView(previewCount: 3)
            .padding()
    }
}
