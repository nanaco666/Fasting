//
//  CalendarHelpers.swift
//  Fasting
//
//  Shared calendar utilities used by HistoryView and PlanView
//

import SwiftUI

enum CalendarHelpers {

    /// Build an array of optional dates for a month grid (nil = blank leading cells)
    static func daysInMonth(for displayedMonth: Date) -> [Date?] {
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

    /// Best completion progress (0-1) for a given day
    static func dayProgress(on date: Date, records: [FastingRecord]) -> Double {
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

    /// All records on a given day
    static func records(on date: Date, from records: [FastingRecord]) -> [FastingRecord] {
        let cal = Calendar.current
        return records.filter { cal.isDate($0.startTime, inSameDayAs: date) }
    }

    /// Display title for a day ("Today", "Yesterday", or formatted)
    static func dayTitle(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today".localized }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday".localized }
        return HistoryFormatters.dayDetail.string(from: date)
    }
}

// MARK: - Preset Badge

struct PresetBadge: View {
    let preset: SuggestedPreset

    var body: some View {
        let (text, color): (String, Color) = switch preset {
        case .normal: ("Normal".localized, .fastingGreen)
        case .shorter: ("14:10", .fastingOrange)
        case .skip: ("Skip".localized, .gray)
        case .flexible: ("Flexible".localized, .fastingTeal)
        case .extended: ("Extended".localized, .fastingOrange)
        }
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }
}
