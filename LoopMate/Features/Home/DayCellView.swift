//
//  DayCellView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/06.
//

import SwiftUI

struct DayCellView: View {
    let day: Int
    let date: Date
    let status: DayStatus?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        
        ZStack(alignment: .topTrailing) {
            Text("\(day)")
                .foregroundStyle(
                    isSelected
                    ? .white
                    : (isToday ? .orange : .primary)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Group {
                        if isSelected {
                            Circle()
                                .fill(.orange)
                                .frame(width: 28, height: 28)
                        }
                    }
                )

            if status == .done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .green)
                    .font(.caption2)
                    .padding(.top, 8)
                    .padding(.trailing, 2)
            } else if status == .notDone {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .red)
                    .font(.caption2)
                    .padding(.top, 8)
                    .padding(.trailing, 2)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    DayCellView(
        day: 15,
        date: Date(),
        status: .done,
        isSelected: true,
        onTap: {}
    )
}
