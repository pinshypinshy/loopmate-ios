//
//  SearchRoomCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/15.
//

import SwiftUI

struct SearchRoomCellView: View {
    let room: Room
    @State var isMember: Bool
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
            }
            
            Spacer()
            
            Button {
                join?()
            } label: {
                Text(isMember ? "参加済み" : "参加")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isMember ? .orange : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(isMember ? Color(.systemGray6) : Color.orange)
                    )
            }
            .disabled(isMember)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    SearchRoomCellView(room: Room.preview, isMember: false)
}
