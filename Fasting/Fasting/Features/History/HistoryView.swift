//
//  HistoryView.swift
//  Fasting
//
//  History page with calendar view
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var selectedDate = Date()
    @State private var selectedRecord: FastingRecord?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Calendar
                        calendarCard
                            .padding(.horizontal, Spacing.lg)
                        
                        // Monthly stats
                        monthlyStatsRow
                            .padding(.horizontal, Spacing.lg)
                        
                        // Recent records
                        recentRecordsSection
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(L10n.Tab.history)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Calendar Card
    
    private var calendarCard: some View {
        VStack(spacing: Spacing.lg) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Spacing.sm)
            
            // Weekday headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.sm) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            hasRecord: hasRecord(on: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        ) {
                            withAnimation(.fastSpring) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    // MARK: - Monthly Stats Row
    
    private var monthlyStatsRow: some View {
        HStack(spacing: Spacing.md) {
            MiniStatPill(
                title: L10n.History.completed,
                value: "\(monthlyCompletedCount)",
                unit: L10n.History.times,
                color: Color.fastingGreen
            )
            
            MiniStatPill(
                title: L10n.History.totalHours,
                value: "\(Int(monthlyTotalHours))",
                unit: "h",
                color: Color.fastingBlue
            )
            
            MiniStatPill(
                title: L10n.History.streak,
                value: "\(currentStreak)",
                unit: L10n.Timer.days,
                color: Color.fastingOrange
            )
        }
    }
    
    // MARK: - Recent Records Section
    
    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.History.recentFasts)
                .font(.headline)
                .padding(.horizontal, Spacing.xs)
            
            if filteredRecords.isEmpty {
                // Empty state
                VStack(spacing: Spacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text(L10n.History.noRecords)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(L10n.History.noRecordsDesc)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxxl)
                .glassCard()
            } else {
                ForEach(filteredRecords.prefix(10)) { record in
                    RecordRowCard(record: record) {
                        selectedRecord = record
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end)!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [Date?] = []
        
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        var currentDate = firstDay
        while currentDate <= lastDay {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private var filteredRecords: [FastingRecord] {
        let calendar = Calendar.current
        return records.filter { record in
            calendar.isDate(record.startTime, equalTo: selectedDate, toGranularity: .month)
        }
    }
    
    private var monthlyCompletedCount: Int {
        filteredRecords.filter { $0.status == .completed }.count
    }
    
    private var monthlyTotalHours: Double {
        filteredRecords
            .compactMap { $0.actualDuration }
            .reduce(0, +) / 3600
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let completedRecords = records.filter { $0.status == .completed }
        
        while true {
            let hasRecord = completedRecords.contains { record in
                calendar.isDate(record.startTime, inSameDayAs: checkDate)
            }
            
            if hasRecord {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Actions
    
    private func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func hasRecord(on date: Date) -> Bool {
        records.contains { record in
            Calendar.current.isDate(record.startTime, inSameDayAs: date)
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let hasRecord: Bool
    let isToday: Bool
    let isSelected: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                if isSelected {
                    Circle()
                        .fill(Color.fastingBlue)
                } else if isToday {
                    Circle()
                        .stroke(Color.fastingBlue, lineWidth: 2)
                }
                
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.subheadline.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    // Record indicator
                    if hasRecord && !isSelected {
                        Circle()
                            .fill(Color.fastingGreen)
                            .frame(width: 6, height: 6)
                    } else if hasRecord && isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Stat Pill

struct MiniStatPill: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.1))
        .glassCard(cornerRadius: CornerRadius.medium)
    }
}

// MARK: - Record Row Card

struct RecordRowCard: View {
    let record: FastingRecord
    let action: () -> Void
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: record.startTime)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Status icon
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 40, height: 40)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.presetType.displayName)
                        .font(.subheadline.weight(.medium))
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Duration
                Text(FastingRecord.formatShortDuration(record.actualDuration ?? record.currentDuration))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.md)
            .glassCard(cornerRadius: CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
    
    private var statusIcon: String {
        switch record.status {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "clock.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch record.status {
        case .completed: return Color.fastingGreen
        case .inProgress: return Color.fastingBlue
        case .cancelled: return .gray
        }
    }
}

// MARK: - Record Detail Sheet

struct RecordDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: FastingRecord
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Plan", value: record.presetType.displayName)
                    LabeledContent("Status", value: record.status.displayName)
                }
                
                Section("Time") {
                    LabeledContent("Started", value: formatDate(record.startTime))
                    if let endTime = record.endTime {
                        LabeledContent("Ended", value: formatDate(endTime))
                    }
                    LabeledContent("Target", value: formatDuration(record.targetDuration))
                    if let actual = record.actualDuration {
                        LabeledContent("Actual", value: formatDuration(actual))
                    }
                }
                
                if record.isGoalAchieved {
                    Section {
                        Label(L10n.Timer.goalReached, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.fastingGreen)
                    }
                }
            }
            .navigationTitle("Fast Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.General.done) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
