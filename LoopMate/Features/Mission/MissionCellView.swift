//
//  MissionCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/03.
//

import SwiftUI

struct MissionCellView: View {
    
    let mission: TodayAllRoomsMissionData
    
    var body: some View {
        HStack {
            Image(systemName: mission.room.iconName)
                .font(.system(size: 28))
                .foregroundStyle(.orange)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())
            
            Text(mission.roomName)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MissionCellView(mission: TodayAllRoomsMissionData.preview)
}
