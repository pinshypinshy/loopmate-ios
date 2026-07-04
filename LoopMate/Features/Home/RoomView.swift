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

    var body: some View {
        ZStack {
            Color(.orange).opacity(Theme.backgroundOpacity).ignoresSafeArea()
            VStack {
                if isLoading {
                    ProgressView("ルーム情報を読み込み中...")
                        .padding(.top)
                }

                RoomCalendarView(
                    selectedDate: $selectedDate,
                    displayYear: $displayYear,
                    displayMonth: $displayMonth,
                    status: { date in status(for: date) }
                )

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
                                selectedDateHeaderView
                                selectedDateDetailView
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
                        onBack()
                    } else {
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
}

// MARK: - View Components

private extension RoomView {

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

            Text(CalendarHelper.selectedDateTitle(selectedDate))
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

            if let room, CalendarHelper.isScheduledDate(selectedDate, room: room) {
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
        } else if let room, CalendarHelper.isScheduledDate(selectedDate, room: room), let record = selectedRecord {
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
}

// MARK: - Helpers

private extension RoomView {

    func status(for date: Date) -> DayStatus? {
        guard let room else { return nil }
        guard CalendarHelper.isScheduledDate(date, room: room) else { return nil }

        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)

        if recordDateKeys.contains(CalendarHelper.dateKey(from: targetDate)) { return .done }
        if targetDate <= today { return .notDone }
        return nil
    }

    func moveSelectedDate(by days: Int) {
        let calendar = Calendar(identifier: .gregorian)
        guard let newDate = calendar.date(byAdding: .day, value: days, to: selectedDate) else { return }
        selectedDate = newDate
    }

    func dailyStatusText(for date: Date) -> String {
        guard let room else { return "" }
        if !CalendarHelper.isScheduledDate(date, room: room) { return "休み" }
        return selectedRecord == nil ? "未実施" : "実施済み"
    }
}

// MARK: - Ranking

private extension RoomView {

    func displayRank(at index: Int) -> Int {
        guard ranking.indices.contains(index) else { return index + 1 }
        let currentRate = ranking[index].rate
        var rank = 1
        for i in 0..<index {
            if ranking[i].rate > currentRate { rank += 1 }
        }
        return rank
    }

    func progressText(rate: Double) -> String {
        "\(Int((rate * 100).rounded()))%"
    }

    func calculateRate(member: RoomMember, records: [MissionRecord], room: Room) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: max(member.joinedAt, room.startDateValue))

        if start > today { return 0 }

        let memberRecordKeys = Set(
            records.filter { $0.userId == member.id }.map { $0.dateKey }
        )

        var totalCount = 0
        var doneCount = 0
        var currentDate = start

        while currentDate <= today {
            if CalendarHelper.isScheduledDate(currentDate, room: room) {
                totalCount += 1
                if memberRecordKeys.contains(CalendarHelper.dateKey(from: currentDate)) {
                    doneCount += 1
                }
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount)
    }
}

// MARK: - API

private extension RoomView {

    func loadRoom() {
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

    func loadRecordDateKeys() {
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

    func loadMembers() {
        roomService.fetchRoomMembers(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let members):
                    self.members = members
                    loadUsers(uids: members.map { $0.id })

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    func loadUsers(uids: [String]) {
        Task {
            let users = await userService.fetchUsers(uids: uids)
            self.users = users
            loadRankingIfPossible()
        }
    }

    func loadRankingIfPossible() {
        guard room != nil, !members.isEmpty, !users.isEmpty else { return }
        loadRanking()
    }

    func loadRanking() {
        guard let room else { return }

        missionService.fetchRecordsForRoom(roomId: roomId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    var items: [(user: User, rate: Double)] = []

                    for member in members {
                        guard let user = users.first(where: { $0.id == member.id }) else { continue }
                        let rate = calculateRate(member: member, records: records, room: room)
                        items.append((user: user, rate: rate))
                    }

                    ranking = items.sorted {
                        $0.rate == $1.rate ? $0.user.id < $1.user.id : $0.rate > $1.rate
                    }

                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    func loadSelectedRecord() {
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
