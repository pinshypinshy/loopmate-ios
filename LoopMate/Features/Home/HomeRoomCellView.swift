//
//  HomeRoomCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/15.
//

import SwiftUI

struct HomeRoomCellView: View {
    let room: Room
    let progressText: String
    var join: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: room.iconName)
                .font(.system(size: 28))
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(room.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(room.code)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 8) {
                    Text("メンバー")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<min(room.memberCount, 3), id: \.self) { _ in
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        if room.memberCount > 3 {
                            Text("+\(room.memberCount - 3)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 2)
                        }
                    }
                }
                Text(progressText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    HomeRoomCellView(room: Room.preview, progressText: "達成状況 75%")
}
