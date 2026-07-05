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

    var body: some View {
        ZStack {
            Color(.orange)
                .opacity(Theme.backgroundOpacity)
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                recordSection
                Spacer()
            }
        }
        .navigationTitle(targetUser.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
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

private extension RoomFriendView {

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

// MARK: - API

private extension RoomFriendView {

    func loadRoom() {
        isLoading = true

        Task {
            do {
                let fetchedRoom = try await roomService.fetchRoom(roomId: roomId)
                room = fetchedRoom
                loadRecordDateKeys()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    func loadRecordDateKeys() {
        Task {
            do {
                let keys = try await missionService.fetchRecordDateKeys(roomId: roomId, userId: targetUser.id)
                isLoading = false
                recordDateKeys = keys
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    func loadSelectedRecord() {
        isLoadingSelectedRecord = true

        Task {
            do {
                let record = try await missionService.fetchRecord(roomId: roomId, userId: targetUser.id, date: selectedDate)
                isLoadingSelectedRecord = false
                selectedRecord = record
            } catch {
                isLoadingSelectedRecord = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
