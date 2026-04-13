//
//  FriendRequestCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI

struct FriendRequestCellView: View {
    
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                UserCellView(user: request.user)
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    onAccept()
                } label: {
                    Text("承認")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange)
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    onReject()
                } label: {
                    Text("拒否")
                        .font(.subheadline)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}
