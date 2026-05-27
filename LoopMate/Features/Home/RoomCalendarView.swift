//
//  RoomCalendarView.swift
//  LoopMate
//
//  Created by 平石悠生 on 2026/03/05.
//

import SwiftUI

// MARK: - CalendarHelper

enum CalendarHelper {

    static let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return f
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年 M月"
        return f
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日"
        return f
    }()

    static func makeDate(year: Int, month: Int, day: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        return Calendar.current.date(from: components) ?? Date()
    }

    static func daysInMonth(year: Int, month: Int) -> [Int] {
        let components = DateComponents(year: year, month: month)
        guard let date = Calendar.current.date(from: components),
              let range = Calendar.current.range(of: .day, in: .month, for: date) else {
            return []
        }
        return Array(range)
    }

    static func firstWeekdayOffset(year: Int, month: Int) -> Int {
        let components = DateComponents(year: year, month: month, day: 1)
        guard let date = Calendar.current.date(from: components) else { return 0 }
        return Calendar.current.component(.weekday, from: date) - 1
    }

    static func monthTitle(year: Int, month: Int) -> String {
        let date = makeDate(year: year, month: month, day: 1)
        return monthTitleFormatter.string(from: date)
    }

    static func dateKey(from date: Date) -> String {
        dateKeyFormatter.string(from: date)
    }

    static func selectedDateTitle(_ date: Date) -> String {
        selectedDateFormatter.string(from: date)
    }

    static func isScheduledDate(_ date: Date, room: Room) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let targetDate = calendar.startOfDay(for: date)
        let startDate = calendar.startOfDay(for: room.startDateValue)

        if targetDate < startDate { return false }

        if let endDate = room.endDateValue {
            if targetDate > calendar.startOfDay(for: endDate) { return false }
        }

        let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
        guard room.selectedWeekdays.indices.contains(weekdayIndex) else { return false }
        return room.selectedWeekdays[weekdayIndex]
    }
}

// MARK: - RoomCalendarView

struct RoomCalendarView: View {

    @Binding var selectedDate: Date
    @Binding var displayYear: Int
    @Binding var displayMonth: Int
    let status: (Date) -> DayStatus?

    private let calendarColumns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            weekdayHeaderView
            gridView
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var headerView: some View {
        HStack {
            Text(CalendarHelper.monthTitle(year: displayYear, month: displayMonth))
                .font(.headline)

            Spacer()

            Button("今日", action: goToToday)
                .buttonStyle(.plain)
                .padding(.trailing)

            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var weekdayHeaderView: some View {
        LazyVGrid(columns: calendarColumns, spacing: 8) {
            ForEach(CalendarHelper.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var gridView: some View {
        let emptyCellIDs = (0..<CalendarHelper.firstWeekdayOffset(year: displayYear, month: displayMonth))
            .map { "empty-\($0)" }
        let days = CalendarHelper.daysInMonth(year: displayYear, month: displayMonth)

        return LazyVGrid(columns: calendarColumns, spacing: 8) {
            ForEach(emptyCellIDs, id: \.self) { _ in
                Color.clear.frame(width: 44, height: 44)
            }
            ForEach(days, id: \.self) { day in
                let date = CalendarHelper.makeDate(year: displayYear, month: displayMonth, day: day)
                DayCellView(
                    day: day,
                    date: date,
                    status: status(date),
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    onTap: { selectedDate = date }
                )
            }
        }
        .padding(.horizontal)
    }

    private func goToToday() {
        let today = Date()
        let calendar = Calendar.current
        displayYear = calendar.component(.year, from: today)
        displayMonth = calendar.component(.month, from: today)
        selectedDate = today
    }

    private func moveMonth(by value: Int) {
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
