//
//  RoomAddMenuView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/04.
//

import SwiftUI

struct RoomAddMenuView: View {
    let onCreate: () -> Void
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            Button(action: onCreate) {
                Text("ルームを作る")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .bold()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button(action: onJoin) {
                Text("ルームに入る")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .bold()
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
        }
        .fixedSize()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    RoomAddMenuView (
        onCreate: {
            print("ルームを作る")
        },
        onJoin: {
            print("ルームに入る")
        }
    )
}
