//
//  RoomCreateView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/07.
//

import SwiftUI

struct RoomCreateView: View {
    
    let onCreate: (Room) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName: String = ""
    @State private var selectedIconName: String = "checkmark.circle"
    @State private var isNumberRequired = false
    @State private var isPhotoRequired = false
    @State private var startDate = Date()
    @State private var isShowingStartDatePicker = false
    @State private var endDate: Date? = nil
    @State private var isShowingEndDatePicker = false
    @State private var selectedWeekdays: [Bool] = Array(repeating: false, count: 7)
    
    private let roomService = RoomService()

    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    private var hasSelectedWeekday: Bool {
        selectedWeekdays.contains(true)
    }
    
    private var endDateTextColor: Color {
        if isShowingEndDatePicker {
            return .orange
        } else if endDate == nil {
            return .gray
        } else {
            return .black
        }
    }
    
    
    var body: some View {
        
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            ScrollView {
                VStack {
                    TextField("ルーム名を入力", text: $roomName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    
                    NavigationLink {
                        RoomIconListView(selectedIconName: $selectedIconName)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedIconName)
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                                .frame(width: 32, height: 32)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Circle())
                            
                            Text("アイコン")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Toggle(isOn: $isNumberRequired) {
                        Text("数値入力の義務化")
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // firebase storageの登録ができないためこの写真機能は保留
                    /*
                    Toggle(isOn: $isPhotoRequired) {
                        Text("写真撮影の義務化")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                     */
                    
                    VStack(spacing: 0) {
                        Button {
                            withAnimation {
                                isShowingStartDatePicker.toggle()
                            }
                        } label: {
                            HStack {
                                Text("開始日")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text(formattedStartDate)
                                    .foregroundStyle(isShowingStartDatePicker ? .orange : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(20)
                            }
                            .frame(height: 28)
                            .padding()
                            .background(Color(.systemGray6))
                        }
                        .buttonStyle(.plain)
                        
                        if isShowingStartDatePicker {
                            Divider()
                            
                            DatePicker(
                                "",
                                selection: $startDate,
                                in: today...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(.orange)
                            .padding()
                            .background(Color(.systemGray6))
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack(spacing: 0) {
                        Button {
                            withAnimation {
                                isShowingEndDatePicker.toggle()
                            }
                        } label: {
                            HStack {
                                Text("終了日")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text(formattedEndDate)
                                    .foregroundStyle(endDateTextColor)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(20)
                            }
                            .frame(height: 28)
                            .padding()
                            .background(Color(.systemGray6))
                        }
                        .buttonStyle(.plain)
                        
                        if isShowingEndDatePicker {
                            Divider()
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { endDate ?? Date() },
                                    set: { endDate = $0 }
                                ),
                                in: startDate...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .tint(.orange)
                            .padding()
                            .background(Color(.systemGray6))
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("曜日の設定")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(0..<weekdaySymbols.count, id: \.self) { index in
                                Button {
                                    selectedWeekdays[index].toggle()
                                } label: {
                                    Text(weekdaySymbols[index])
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(selectedWeekdays[index] ? .white : .primary)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            selectedWeekdays[index]
                                            ? Color.orange
                                            : Color(.systemGray5)
                                        )
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        if !hasSelectedWeekday {
                            HStack {
                                Text("曜日を1つ以上選択してください")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top)
                }
                .padding(.top)
                
                
            }
        }
        .navigationTitle("新規ルーム")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    let trimmedRoomName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !trimmedRoomName.isEmpty else { return }
                    
                    isSaving = true
                    
                    roomService.createRoom(
                        name: trimmedRoomName,
                        iconName: selectedIconName,
                        isNumberRequired: isNumberRequired,
                        isPhotoRequired: isPhotoRequired,
                        startDate: startDate,
                        endDate: endDate,
                        selectedWeekdays: selectedWeekdays
                    ) { result in
                        DispatchQueue.main.async {
                            isSaving = false
                            
                            switch result {
                            case .success(let createdRoom):
                                print("✅ createRoom success")
                                print("createdRoom.id = \(createdRoom.id)")
                                print("createdRoom.name = \(createdRoom.name)")
                                print("createdRoom.code = \(createdRoom.code)")
                                onCreate(createdRoom)
                                
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                                showErrorAlert = true
                            }
                        }
                    }
                } label: {
                    Text("作成")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(
                    roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !hasSelectedWeekday
                    || isSaving
                )
            }
        }
        .onChange(of: startDate) {
            if let currentEndDate = endDate, currentEndDate < startDate {
                endDate = startDate
            }
        }
        .alert("ルーム作成に失敗しました", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        
    }
    
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: startDate)
    }
    
    private var formattedEndDate: String {
        guard let endDate else { return "未設定" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        
        return formatter.string(from: endDate)
    }
}

#Preview {
    NavigationStack {
        RoomCreateView(onCreate: { _ in })
    }
}
