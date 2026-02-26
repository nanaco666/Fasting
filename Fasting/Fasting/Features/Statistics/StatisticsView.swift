//
//  StatisticsView.swift
//  Fasting
//
//  Insights — ADA-compliant design with glass cards + 3-color palette
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var selectedPeriod: StatsPeriod = .week
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Hero: Current streak
                        streakHero
                            .padding(.horizontal, Spacing.lg)
                        
                        // Stats summary
                        statsRow
                            .padding(.horizontal, Spacing.lg)
                        
                        // Period chart
                        trendCard
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.lg)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle(L10n.Tab.insights)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Streak Hero
    
    private var streakHero: some View {
        VStack(spacing: Spacing.lg) {
            if currentStreak > 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(Color.fastingOrange)
                        .symbolEffect(.pulse, options: .repeating, value: currentStreak > 0)
                    
                    Text("\(currentStreak)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                
                Text("Day Streak".localized)
                    .font(.title3.weight(.semibold))
                
                Text(L10n.Insights.keepItUp)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "flame")
                    .font(.system(size: 44))
                    .foregroundStyle(.tertiary)
                
                Text("No Current Streak".localized)
                    .font(.title3.weight(.semibold))
                
                Text("Fast at least once a day\nto build a streak.".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Mini streak stats
            HStack(spacing: Spacing.lg) {
                streakMini(
                    label: "Longest".localized,
                    value: "\(longestStreak)",
                    unit: L10n.Timer.days
                )
                
                Divider().frame(height: 32)
                
                streakMini(
                    label: "Best".localized + " " + "Weekly".localized,
                    value: "\(bestWeekCount)",
                    unit: "Fasts".localized
                )
                
                Divider().frame(height: 32)
                
                streakMini(
                    label: "Total Fasts".localized,
                    value: "\(completedRecords.count)",
                    unit: "This Year".localized
                )
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: CornerRadius.extraLarge)
    }
    
    private func streakMini(label: String, value: String, unit: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            statCard(
                title: L10n.Insights.totalTime,
                value: formattedTotalTime,
                color: .fastingGreen
            )
            statCard(
                title: "Success".localized,
                value: "\(Int(successRate * 100))%",
                color: .fastingTeal
            )
            statCard(
                title: "Average".localized,
                value: formattedAverageTime,
                color: .fastingOrange
            )
        }
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.medium)
    }
    
    // MARK: - Trend Card
    
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Period selector
            HStack(spacing: 0) {
                ForEach(StatsPeriod.allCases) { period in
                    Button {
                        withAnimation(.fastSpring) { selectedPeriod = period }
                        Haptic.selection()
                    } label: {
                        Text(period.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedPeriod == period
                                    ? AnyShapeStyle(Color.fastingGreen)
                                    : AnyShapeStyle(Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Insights.fastingTrend)
                        .font(.headline)
                    Text(periodDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedPeriodTotal)
                        .font(.title2.bold())
                        .foregroundStyle(Color.fastingGreen)
                        .monospacedDigit()
                    Text("total".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Chart
            if periodData.isEmpty || periodData.allSatisfy({ $0.hours == 0 }) {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                    Text(L10n.Insights.noData)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(L10n.Insights.noDataDesc)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart(periodData) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.fastingGreen, .fastingTeal],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.gray.opacity(0.3))
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    // MARK: - Data
    
    private var completedRecords: [FastingRecord] {
        records.filter { $0.status == .completed }
    }
    
    private var totalHours: Double {
        completedRecords.compactMap { $0.actualDuration }.reduce(0, +) / 3600
    }
    
    private var formattedTotalTime: String {
        totalHours >= 1 ? "\(Int(totalHours))h" : "\(Int(totalHours * 60))m"
    }
    
    private var averageHours: Double {
        guard !completedRecords.isEmpty else { return 0 }
        return totalHours / Double(completedRecords.count)
    }
    
    private var formattedAverageTime: String {
        averageHours >= 1 ? String(format: "%.1fh", averageHours) : "\(Int(averageHours * 60))m"
    }
    
    private var successRate: Double {
        guard !records.isEmpty else { return 0 }
        let successful = records.filter { $0.status == .completed && $0.isGoalAchieved }.count
        return Double(successful) / Double(records.count)
    }
    
    private var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var check = cal.startOfDay(for: Date())
        while true {
            if completedRecords.contains(where: { cal.isDate($0.startTime, inSameDayAs: check) }) {
                streak += 1
                check = cal.date(byAdding: .day, value: -1, to: check)!
            } else { break }
        }
        return streak
    }
    
    private var longestStreak: Int {
        let cal = Calendar.current
        let sorted = Set(completedRecords.map { cal.startOfDay(for: $0.startTime) }).sorted()
        guard !sorted.isEmpty else { return 0 }
        var longest = 1, current = 1
        for i in 1..<sorted.count {
            if cal.date(byAdding: .day, value: 1, to: sorted[i-1]) == sorted[i] {
                current += 1
                longest = max(longest, current)
            } else { current = 1 }
        }
        return longest
    }
    
    private var bestWeekCount: Int {
        guard !completedRecords.isEmpty else { return 0 }
        let cal = Calendar.current
        var best = 0
        for record in completedRecords {
            let start = cal.startOfDay(for: record.startTime)
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            let count = completedRecords.filter { $0.startTime >= start && $0.startTime < end }.count
            best = max(best, count)
        }
        return best
    }
    
    private var periodData: [ChartData] {
        let cal = Calendar.current
        let now = Date()
        switch selectedPeriod {
        case .week:
            return (0..<7).reversed().map { daysAgo in
                let date = cal.date(byAdding: .day, value: -daysAgo, to: now)!
                let hours = completedRecords.filter { cal.isDate($0.startTime, inSameDayAs: date) }
                    .compactMap { $0.actualDuration }.reduce(0, +) / 3600
                let f = DateFormatter(); f.dateFormat = "E"
                return ChartData(label: f.string(from: date), hours: hours)
            }
        case .month:
            return (0..<4).reversed().map { weeksAgo in
                let start = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now)!
                let end = cal.date(byAdding: .day, value: 7, to: start)!
                let hours = completedRecords.filter { $0.startTime >= start && $0.startTime < end }
                    .compactMap { $0.actualDuration }.reduce(0, +) / 3600
                return ChartData(label: "W\(4-weeksAgo)", hours: hours)
            }
        case .year:
            return (0..<12).reversed().map { monthsAgo in
                let month = cal.date(byAdding: .month, value: -monthsAgo, to: now)!
                let hours = completedRecords.filter { cal.isDate($0.startTime, equalTo: month, toGranularity: .month) }
                    .compactMap { $0.actualDuration }.reduce(0, +) / 3600
                let f = DateFormatter(); f.dateFormat = "MMM"
                return ChartData(label: f.string(from: month), hours: hours)
            }
        }
    }
    
    private var periodTotalHours: Double { periodData.reduce(0) { $0 + $1.hours } }
    
    private var formattedPeriodTotal: String {
        periodTotalHours >= 1 ? "\(Int(periodTotalHours))h" : "\(Int(periodTotalHours * 60))m"
    }
    
    private var periodDescription: String {
        switch selectedPeriod {
        case .week: return "Last 7 days".localized
        case .month: return "Last 4 weeks".localized
        case .year: return "Last 12 months".localized
        }
    }
}

// MARK: - Supporting Types

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week, month, year
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .week: return L10n.Insights.week
        case .month: return L10n.Insights.month
        case .year: return L10n.Insights.year
        }
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}

#Preview {
    StatisticsView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
