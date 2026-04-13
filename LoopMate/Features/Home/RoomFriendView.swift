//
//  RoomFriendView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/18.
//

import SwiftUI

struct RoomFriendView: View {
    
    let roomId: String
    let targetUser: User
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var room: Room?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let roomService = RoomService()
    private let missionService = MissionService()
    
    @State private var selectedDate: Date = .now
    @State private var displayYear = Calendar.current.component(.year, from: .now)
    @State private var displayMonth = Calendar.current.component(.month, from: .now)
    @State private var recordDateKeys: Set<String> = []
    @State private var selectedRecord: MissionRecord?
    @State private var isLoadingSelectedRecord = false
    
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    private let calendarColumns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 0) {
                loadingView
                calendarSection
                Divider()
                recordSection
                Spacer()
            }
        }
        .navigationTitle(targetUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
        }
        .onAppear {
            loadRoom()
            loadSelectedRecord()
        }
        .onChange(of: selectedDate) { _, _ in
            loadSelectedRecord()
        }
        .alert("記録の取得に失敗しました", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - View Components
private extension RoomFriendView {
    
    var backgroundView: some View {
        Color(.orange)
            .opacity(Theme.backgroundOpacity)
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    var loadingView: some View {
        if isLoading {
            ProgressView("ルーム情報を読み込み中...")
                .padding(.top)
        }
    }
    
    var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
        }
    }
    
    var calendarSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            calendarHeaderView
            weekdayHeaderView
            calendarGridView
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var calendarHeaderView: some View {
        HStack {
            Text(monthTitle(year: displayYear, month: displayMonth))
                .font(.headline)
            
            Spacer()
            
            Button("今日", action: goToToday)
                .buttonStyle(.plain)
                .padding(.trailing)
            
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            
            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
    
    var weekdayHeaderView: some View {
        LazyVGrid(columns: calendarColumns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    var calendarGridView: some View {
        LazyVGrid(columns: calendarColumns, spacing: 8) {
            ForEach(emptyCellIDs, id: \.self) { _ in
                Color.clear
                    .frame(width: 44, height: 44)
            }
            
            ForEach(monthDays, id: \.self) { day in
                let date = makeDate(year: displayYear, month: displayMonth, day: day)
                
                DayCellView(
                    day: day,
                    date: date,
                    status: status(for: date),
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    onTap: {
                        selectedDate = date
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    var recordSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                selectedDateHeaderView
                selectedDateDetailView
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }
    
    var selectedDateHeaderView: some View {
        HStack {
            Button {
                moveSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(selectedDateTitle(selectedDate))
                .font(.title3)
                .bold()
            
            Spacer()
            
            Button {
                moveSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    var selectedDateDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            statusHeaderView
            selectedRecordContentView
        }
        .padding(.horizontal)
    }
    
    var statusHeaderView: some View {
        HStack(spacing: 8) {
            Text(dailyStatusText(for: selectedDate))
                .font(.title3)
                .bold()
            
            if let room, isScheduledDate(selectedDate, room: room) {
                if selectedRecord != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    var selectedRecordContentView: some View {
        if isLoadingSelectedRecord {
            ProgressView()
                .padding(.top, 4)
        } else if let room, isScheduledDate(selectedDate, room: room), let record = selectedRecord {
            if room.isNumberRequired {
                recordNumberView(record)
            }
            
            recordCommentView(record)
        }
    }
    
    func recordNumberView(_ record: MissionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("数値")
                .font(.headline)
            
            Text(record.value.map { String($0) } ?? "")
                .font(.body)
        }
    }
    
    func recordCommentView(_ record: MissionRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("コメント")
                .font(.headline)
            
            Text(record.comment)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Computed Properties
private extension RoomFriendView {
    
    var emptyCellIDs: [String] {
        (0..<firstWeekdayOffset(year: displayYear, month: displayMonth)).map { "empty-\($0)" }
    }
    
    var monthDays: [Int] {
        daysInMonth(year: displayYear, month: displayMonth)
    }
}

// MARK: - Actions
private extension RoomFriendView {
    
    func goToToday() {
        let today = Date()
        let calendar = Calendar.current
        displayYear = calendar.component(.year, from: today)
        displayMonth = calendar.component(.month, from: today)
        selectedDate = today
    }
    
    func moveMonth(by value: Int) {
        displayMonth += value
        
        if displayMonth == 0 {
            displayMonth = 12
            displayYear -= 1
        } else if displayMonth == 13 {
            displayMonth = 1
            displayYear += 1
        }
    }
}

// MARK: - Helpers
private extension RoomFriendView {
    
    func makeDate(year: Int, month: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day)
        return calendar.date(from: components) ?? Date()
    }
    
    func daysInMonth(year: Int, month: Int) -> [Int] {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month)
        
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }
        
        return Array(range)
    }
    
    func firstWeekdayOffset(year: Int, month: Int) -> Int {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: 1)
        
        guard let date = calendar.date(from: components) else {
            return 0
        }
        
        let weekday = calendar.component(.weekday, from: date)
        return weekday - 1
    }
    
    func monthTitle(year: Int, month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        
        let date = makeDate(year: year, month: month, day: 1)
        return formatter.string(from: date)
    }
    
    func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    func isScheduledDate(_ date: Date, room: Room) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: room.startDateValue)
        
        if targetDate < startDate {
            return false
        }
        
        if let endDate = room.endDateValue {
            let endDay = calendar.startOfDay(for: endDate)
            if targetDate > endDay {
                return false
            }
        }
        
        let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
        
        guard room.selectedWeekdays.indices.contains(weekdayIndex) else {
            return false
        }
        
        return room.selectedWeekdays[weekdayIndex]
    }
    
    func status(for date: Date) -> DayStatus? {
        guard let room else {
            return nil
        }
        
        guard isScheduledDate(date, room: room) else {
            return nil
        }
        
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        if recordDateKeys.contains(dateKey(from: targetDate)) {
            return .done
        }
        
        if targetDate <= today {
            return .notDone
        }
        
        return nil
    }
    
    func selectedDateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    func moveSelectedDate(by days: Int) {
        let calendar = Calendar(identifier: .gregorian)
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }
        selectedDate = newDate
    }
    
    func dailyStatusText(for date: Date) -> String {
        guard let room else {
            return ""
        }
        
        if !isScheduledDate(date, room: room) {
            return "休み"
        }
        
        return selectedRecord == nil ? "未実施" : "実施済み"
    }
}

// MARK: - API
private extension RoomFriendView {
    
    func loadRoom() {
        isLoading = true
        
        roomService.fetchRoom(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedRoom):
                    room = fetchedRoom
                    loadRecordDateKeys()
                    
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func loadRecordDateKeys() {
        missionService.fetchRecordDateKeys(roomId: roomId, userId: targetUser.id) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let keys):
                    recordDateKeys = keys
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func loadSelectedRecord() {
        isLoadingSelectedRecord = true
        
        missionService.fetchRecord(roomId: roomId, userId: targetUser.id, date: selectedDate) { result in
            DispatchQueue.main.async {
                isLoadingSelectedRecord = false
                
                switch result {
                case .success(let record):
                    selectedRecord = record
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
