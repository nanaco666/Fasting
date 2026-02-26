//
//  HistoryView.swift
//  Fasting
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedRecord: FastingRecord?
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        calendarSection
                            .padding(.horizontal, Spacing.lg)
                        
                        statsRow
                            .padding(.horizontal, Spacing.lg)
                        
                        dayDetailSection
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
    
    // MARK: - Calendar
    
    private var calendarSection: some View {
        VStack(spacing: Spacing.lg) {
            // Month nav
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(monthTitle)
                    .font(.title2.bold())
                
                Spacer()
                
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Weekday headers
            weekdayHeader
            
            // Day grid with rings
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: Spacing.md) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, item in
                    if let date = item {
                        DayRingCell(
                            date: date,
                            progress: dayProgress(date),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                            holiday: HolidayService.holiday(on: date)
                        ) {
                            withAnimation(.fastSpring) { selectedDate = date }
                        }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Stats
    
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            statCard(
                title: "Completed".localized,
                value: "\(monthCompleted)",
                unit: L10n.History.times,
                color: .fastingGreen
            )
            statCard(
                title: "Current Streak".localized,
                value: "\(currentStreak)",
                unit: L10n.Timer.days,
                color: .fastingOrange
            )
            statCard(
                title: "Longest Streak".localized,
                value: "\(longestStreak)",
                unit: L10n.Timer.days,
                color: .fastingTeal
            )
        }
    }
    
    private func statCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.medium)
    }
    
    // MARK: - Day Detail
    
    private var dayDetailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let date = selectedDate {
                let dayRecords = recordsOn(date)
                
                Text(dayTitle(date))
                    .font(.title3.bold())
                    .padding(.horizontal, Spacing.xs)
                
                // Holiday advice card
                if let h = HolidayService.holiday(on: date) {
                    holidayAdviceCard(h)
                }
                
                if dayRecords.isEmpty {
                    emptyDayCard
                } else {
                    ForEach(dayRecords) { record in
                        RecordRowCard(record: record) {
                            selectedRecord = record
                        }
                    }
                }
            }
        }
    }
    
    private func holidayAdviceCard(_ h: Holiday) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(h.fastingAdvice.emoji)
                    .font(.title2)
                Text(h.localizedName)
                    .font(.headline)
                Spacer()
                presetBadge(h.fastingAdvice.suggestedPreset)
            }
            
            Text(h.fastingAdvice.localizedDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.medium)
    }
    
    private func presetBadge(_ preset: SuggestedPreset) -> some View {
        let (text, color): (String, Color) = switch preset {
        case .normal: ("Normal".localized, .fastingGreen)
        case .shorter: ("14:10", .fastingOrange)
        case .skip: ("Skip".localized, .gray)
        case .flexible: ("Flexible".localized, .fastingTeal)
        case .extended: ("Extended".localized, .fastingOrange)
        }
        return Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }
    
    private var emptyDayCard: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "moon.zzz")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No fasts this day".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .glassCard(cornerRadius: CornerRadius.medium)
    }
    
    // MARK: - Data
    
    private var weekdaySymbols: [String] {
        let f = DateFormatter()
        f.locale = Locale.current
        return f.veryShortWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
    }
    
    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: .current)
        return f.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        let interval = cal.dateInterval(of: .month, for: displayedMonth)!
        let firstWeekday = cal.component(.weekday, from: interval.start)
        let lastDay = cal.date(byAdding: .day, value: -1, to: interval.end)!
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        var d = interval.start
        while d <= lastDay {
            days.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return days
    }
    
    private func dayProgress(_ date: Date) -> Double {
        let cal = Calendar.current
        let dayRecords = records.filter {
            $0.status == .completed && cal.isDate($0.startTime, inSameDayAs: date)
        }
        guard let best = dayRecords.max(by: { ($0.actualDuration ?? 0) < ($1.actualDuration ?? 0) }) else {
            return 0
        }
        guard best.targetDuration > 0 else { return 0 }
        return min((best.actualDuration ?? 0) / best.targetDuration, 1.0)
    }
    
    private func recordsOn(_ date: Date) -> [FastingRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDate($0.startTime, inSameDayAs: date) }
    }
    
    private func dayTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today".localized }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday".localized }
        let f = DateFormatter()
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMd EEEE", options: 0, locale: .current)
        return f.string(from: date)
    }
    
    private var monthCompleted: Int {
        let cal = Calendar.current
        return records.filter {
            $0.status == .completed
            && ($0.actualDuration ?? 0) >= $0.targetDuration
            && cal.isDate($0.startTime, equalTo: displayedMonth, toGranularity: .month)
        }.count
    }
    
    private var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var check = cal.startOfDay(for: Date())
        while true {
            let has = records.contains {
                $0.status == .completed
                && ($0.actualDuration ?? 0) >= $0.targetDuration
                && cal.isDate($0.startTime, inSameDayAs: check)
            }
            if has {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else { break }
        }
        return streak
    }
    
    private var longestStreak: Int {
        let cal = Calendar.current
        let completedDays = Set(records.filter {
            $0.status == .completed && ($0.actualDuration ?? 0) >= $0.targetDuration
        }.map { cal.startOfDay(for: $0.startTime) })
        
        guard !completedDays.isEmpty else { return 0 }
        let sorted = completedDays.sorted()
        var longest = 1, current = 1
        for i in 1..<sorted.count {
            if cal.date(byAdding: .day, value: 1, to: sorted[i-1]) == sorted[i] {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
    
    private func changeMonth(_ delta: Int) {
        withAnimation(.fastSpring) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
            selectedDate = nil
        }
    }
}

// MARK: - Day Ring Cell

struct DayRingCell: View {
    let date: Date
    let progress: Double
    let isToday: Bool
    let isSelected: Bool
    let holiday: Holiday?
    let onTap: () -> Void
    
    private var day: String {
        "\(Calendar.current.component(.day, from: date))"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 1) {
                Text(day)
                    .font(.caption.weight(isToday ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.fastingGreen : isToday ? .primary : .secondary)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 4)
                    
                    if progress > 0 {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                progress >= 1.0 ? Color.fastingGreen : Color.fastingOrange,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    
                    if progress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.fastingGreen)
                    } else if let h = holiday {
                        Text(h.fastingAdvice.emoji)
                            .font(.system(size: 12))
                    }
                }
                .frame(width: 36, height: 36)
                
                // Holiday name — fixed space, always present
                Text(holiday?.localizedName ?? " ")
                    .font(.system(size: 7))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(height: 62)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(day), \(progress >= 1.0 ? "completed" : progress > 0 ? "\(Int(progress * 100)) percent" : "no fast")\(holiday.map { ", \($0.localizedName)" } ?? "")")
    }
}

// MARK: - Record Row Card

struct RecordRowCard: View {
    let record: FastingRecord
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 44, height: 44)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.presetType.displayName)
                        .font(.body.weight(.semibold))
                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(durationString)
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
    
    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        var s = f.string(from: record.startTime)
        if let end = record.endTime {
            s += " → " + f.string(from: end)
        }
        return s
    }
    
    private var durationString: String {
        FastingRecord.formatShortDuration(record.actualDuration ?? record.currentDuration)
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
        case .completed: return .fastingGreen
        case .inProgress: return .fastingTeal
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
                    LabeledContent("Plan".localized, value: record.presetType.displayName)
                    LabeledContent("Status".localized, value: record.status.displayName)
                }
                Section("Time".localized) {
                    LabeledContent("Started".localized, value: formatDate(record.startTime))
                    if let end = record.endTime {
                        LabeledContent("Ended".localized, value: formatDate(end))
                    }
                    LabeledContent("Target".localized, value: formatDur(record.targetDuration))
                    if let actual = record.actualDuration {
                        LabeledContent("Actual".localized, value: formatDur(actual))
                    }
                }
                if record.isGoalAchieved {
                    Section {
                        Label(L10n.Timer.goalReached, systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.fastingGreen)
                    }
                }
            }
            .navigationTitle("Fast Details".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.General.done) { dismiss() }
                }
            }
        }
    }
    
    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f.string(from: d)
    }
    
    private func formatDur(_ t: TimeInterval) -> String {
        "\(Int(t) / 3600)h \((Int(t) % 3600) / 60)m"
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
