//
//  RoomView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/05.
//

import SwiftUI

private enum RoomSegment: String, CaseIterable {
    case dailyRecord = "毎日の記録"
    case ranking = "ランキング"
}

struct RoomView: View {
    
    let roomId: String
    
    @Environment(\.dismiss) private var dismiss
    var onBack: (() -> Void)? = nil
    var onLeaveRoom: (() -> Void)? = nil
    var onOpenMenu: ((Room) -> Void)? = nil
    var completionRoom: Room? = nil
    
    @State private var completionCoverRoom: Room? = nil
    @State private var hasShownCompletionOnce = false
    @State private var room: Room?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let roomService = RoomService()
    private let missionService = MissionService()
    private let userService = UserService()
    
    @State private var selectedDate: Date = .now
    @State private var displayYear = Calendar.current.component(.year, from: Date())
    @State private var displayMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedTab: RoomSegment = .dailyRecord
    @State private var recordDateKeys: Set<String> = []
    @State private var ranking: [(user: User, rate: Double)] = []
    @State private var members: [RoomMember] = []
    @State private var users: [User] = []
    @State private var selectedRecord: MissionRecord?
    @State private var isLoadingSelectedRecord = false
    let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            VStack {
                if isLoading {
                    ProgressView("ルーム情報を読み込み中...")
                        .padding(.top)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(monthTitle(year: displayYear, month: displayMonth))
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("今日") {
                            let today = Date()
                            let calendar = Calendar.current
                            displayYear = calendar.component(.year, from: today)
                            displayMonth = calendar.component(.month, from: today)
                            selectedDate = today
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing)
                        
                        Button {
                            displayMonth -= 1
                            if displayMonth == 0 {
                                displayMonth = 12
                                displayYear -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            displayMonth += 1
                            if displayMonth == 13 {
                                displayMonth = 1
                                displayYear += 1
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.caption2)
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    let emptyCellIDs = (0..<firstWeekdayOffset(year: displayYear, month: displayMonth)).map { "empty-\($0)" }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(emptyCellIDs, id: \.self) { _ in
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        
                        ForEach(daysInMonth(year: displayYear, month: displayMonth), id: \.self) { day in
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
                .padding(12)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Picker("", selection: $selectedTab) {
                        ForEach(RoomSegment.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 12)
                    
                    if selectedTab == .dailyRecord {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                
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
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    
                                    HStack(spacing: 8) {
                                        Text(dailyStatusText(for: selectedDate))
                                            .font(.title3)
                                            .bold()
                                        
                                        if let room {
                                            if isScheduledDate(selectedDate, room: room) {
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
                                    
                                    if isLoadingSelectedRecord {
                                        ProgressView()
                                            .padding(.top, 4)
                                    } else if let room, isScheduledDate(selectedDate, room: room), let record = selectedRecord {
                                        
                                        if room.isNumberRequired {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("数値")
                                                    .font(.headline)
                                                
                                                Text(record.value.map { String($0) } ?? "")
                                                    .font(.body)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("コメント")
                                                .font(.headline)
                                            
                                            Text(record.comment)
                                                .font(.body)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(Array(ranking.enumerated()), id: \.element.user.id) { index, item in
                                    NavigationLink {
                                        RoomFriendView(
                                            roomId: roomId,
                                            targetUser: item.user
                                        )
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text("\(displayRank(at: index))")
                                                .font(.title3)
                                                .bold()
                                                .frame(width: 32)
                                            
                                            UserCellView(user: item.user)
                                            
                                            Spacer()
                                            
                                            Text(progressText(rate: item.rate))
                                                .font(.subheadline)
                                                .foregroundStyle(.gray)
                                        }
                                        .padding(.horizontal)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                
                Spacer()
            }
        }
        .navigationTitle(room?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if let onBack {
                        print("use onBack")
                        onBack()
                    } else {
                        print("use dismiss")
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let room {
                    Button {
                        onOpenMenu?(room)
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
        }
        .onAppear {
            loadRoom()
            loadMembers()
            loadSelectedRecord()

            if !hasShownCompletionOnce, let completionRoom {
                hasShownCompletionOnce = true
                completionCoverRoom = completionRoom
            }
        }
        .onChange(of: selectedDate) { _, _ in
            loadSelectedRecord()
        }
        .fullScreenCover(item: $completionCoverRoom) { room in
            RoomCreateCompleteView(
                room: room,
                onClose: {
                    completionCoverRoom = nil
                }
            )
        }
        .alert("ルーム情報の取得に失敗しました", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        
        
    }
    
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
    
    private func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }

    private func isScheduledDate(_ date: Date, room: Room) -> Bool {
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

    private func status(for date: Date) -> DayStatus? {
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
    
    private func loadRoom() {
        isLoading = true
        
        roomService.fetchRoom(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedRoom):
                    room = fetchedRoom
                    loadRecordDateKeys()
                    loadRankingIfPossible()
                    
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadRecordDateKeys() {
        missionService.fetchMyRecordDateKeys(roomId: roomId) { result in
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
    
    // MARK: ランキング
    private func loadMembers() {
        roomService.fetchRoomMembers(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let members):
                    self.members = members
                    
                    let uids = members.map { $0.id }
                    loadUsers(uids: uids)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func loadUsers(uids: [String]) {
        userService.fetchUsers(uids: uids) { users in
            self.users = users
            loadRankingIfPossible()
        }
    }
    
    private func loadRanking() {
        guard let room else {
            return
        }
        
        missionService.fetchRecordsForRoom(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    var items: [(user: User, rate: Double)] = []
                    
                    for member in members {
                        guard let user = users.first(where: { $0.id == member.id }) else {
                            continue
                        }
                        
                        let rate = calculateRate(
                            member: member,
                            records: records,
                            room: room
                        )
                        
                        items.append((user: user, rate: rate))
                    }
                    
                    ranking = items.sorted {
                        if $0.rate == $1.rate {
                            return $0.user.id < $1.user.id
                        }
                        return $0.rate > $1.rate
                    }
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func calculateRate(
        member: RoomMember,
        records: [MissionRecord],
        room: Room
    ) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: max(member.joinedAt, room.startDateValue))
        
        if start > today {
            return 0
        }
        
        let memberRecordKeys = Set(
            records
                .filter { $0.userId == member.id }
                .map { $0.dateKey }
        )
        
        var totalCount = 0
        var doneCount = 0
        var currentDate = start
        
        while currentDate <= today {
            if isScheduledDate(currentDate, room: room) {
                totalCount += 1
                
                let key = dateKey(from: currentDate)
                if memberRecordKeys.contains(key) {
                    doneCount += 1
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        if totalCount == 0 {
            return 0
        }
        
        return Double(doneCount) / Double(totalCount)
    }
    
    private func displayRank(at index: Int) -> Int {
        guard ranking.indices.contains(index) else {
            return index + 1
        }
        
        let currentRate = ranking[index].rate
        var rank = 1
        
        for i in 0..<index {
            if ranking[i].rate > currentRate {
                rank += 1
            }
        }
        
        return rank
    }
    
    private func progressText(rate: Double) -> String {
        let percent = Int((rate * 100).rounded())
        return "\(percent)%"
    }
    
    private func loadRankingIfPossible() {
        guard room != nil else { return }
        guard !members.isEmpty else { return }
        guard !users.isEmpty else { return }
        
        loadRanking()
    }
    
    // MARK: 毎日の記録
    private func selectedDateTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private func moveSelectedDate(by days: Int) {
        let calendar = Calendar(identifier: .gregorian)
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else {
            return
        }
        selectedDate = newDate
    }

    private func dailyStatusText(for date: Date) -> String {
        guard let room else {
            return ""
        }
        
        if !isScheduledDate(date, room: room) {
            return "休み"
        }
        
        return selectedRecord == nil ? "未実施" : "実施済み"
    }

    private func loadSelectedRecord() {
        isLoadingSelectedRecord = true
        
        missionService.fetchMyRecord(roomId: roomId, date: selectedDate) { result in
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

#Preview {
    NavigationStack {
        RoomView(roomId: "preview_room_id", onBack: {})
    }
}
