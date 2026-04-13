//
//  RoomMenuView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/15.
//

import SwiftUI

struct RoomMenuView: View {
    
    let room: Room
    var onLeaveCompleted: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLeaveAlertPresented = false
    
    private let roomService = RoomService()
    
    var body: some View {
        ZStack {
            Color.orange.opacity(Theme.backgroundOpacity).ignoresSafeArea()
            
            ScrollView {
                VStack {
                    VStack(spacing: 12) {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text(room.name)
                                .font(.headline)
                            
                            Divider()
                            
                            HStack {
                                Text("ルームコード")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(room.code)
                            }
                            
                            HStack {
                                Text("メンバー数")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(room.memberCount)人")
                            }
                            
                            HStack {
                                Text("数値入力")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(room.isNumberRequired ? "必須" : "任意")
                            }
                            
                            HStack {
                                Text("開始日")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(formatDate(room.startDateValue))
                            }
                            
                            HStack {
                                Text("終了日")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(room.endDateValue.map { formatDate($0) } ?? "なし")
                            }
                            
                            HStack(alignment: .top) {
                                Text("曜日")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(formatWeekdays(room.selectedWeekdays))
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button {
                        isLeaveAlertPresented = true
                    } label : {
                        Text("ルームを退会")
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .padding(.top)
                    .cornerRadius(12)
                }
                .padding()
                .alert("ルームを退会しますか？", isPresented: $isLeaveAlertPresented) {
                    Button("キャンセル", role: .cancel) {
                    }
                    
                    Button("退会する", role: .destructive) {
                        roomService.leaveRoom(room: room) { result in
                            switch result {
                            case .success:
                                onLeaveCompleted?()
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("メニュー")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    private func formatWeekdays(_ selectedWeekdays: [Bool]) -> String {
        let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
        
        let selected = selectedWeekdays.enumerated().compactMap { index, isSelected in
            isSelected ? weekdaySymbols[index] : nil
        }
        
        return selected.isEmpty ? "指定なし" : selected.joined(separator: "・")
    }
}

#Preview {
    NavigationStack {
        RoomMenuView(room: .preview, onLeaveCompleted: {})
    }
}
