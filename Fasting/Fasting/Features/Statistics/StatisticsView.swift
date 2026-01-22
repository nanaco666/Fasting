//
//  StatisticsView.swift
//  Fasting
//
//  Insights page - Redesigned based on Apple Journal Insights reference
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Design Constants (based on reference)

private enum InsightColors {
    static let streakCardBg = Color(red: 0.22, green: 0.24, blue: 0.35) // Dark blue-gray
    static let statsChartBg = Color(red: 0.55, green: 0.55, blue: 0.85) // Light purple
    static let totalDaysCard = Color(red: 0.85, green: 0.45, blue: 0.45) // Coral/salmon
    static let visitedCard = Color(red: 0.55, green: 0.55, blue: 0.75) // Light purple-gray
    static let writtenCard = Color(red: 0.75, green: 0.55, blue: 0.55) // Dusty rose
    static let cardCornerRadius: CGFloat = 20
}

struct StatisticsView: View {
    // MARK: - Properties
    
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var selectedPeriod: StatsPeriod = .week
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Streaks Section
                        streaksSection
                            .padding(.horizontal, Spacing.lg)
                        
                        // Stats Section
                        statsSection
                            .padding(.horizontal, Spacing.lg)
                        
                        // Period selector
                        periodSelector
                            .padding(.horizontal, Spacing.lg)
                        
                        // Trend chart
                        trendChartCard
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(L10n.Tab.insights)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Streaks Section (based on reference)
    
    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Streaks")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.md) {
                // Current streak / No streak card (large, left side)
                currentStreakCard
                
                // Right side cards
                VStack(spacing: Spacing.md) {
                    // Longest daily streak
                    miniStreakCard(
                        label: "Longest",
                        title: "Daily",
                        subtitle: "Streak",
                        value: "\(longestStreak)",
                        unit: "Days"
                    )
                    
                    // Best week
                    miniStreakCard(
                        label: "Best",
                        title: "Weekly",
                        subtitle: "Record",
                        value: "\(bestWeekCount)",
                        unit: "Fasts"
                    )
                }
            }
            .frame(height: 180)
        }
    }
    
    private var currentStreakCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if currentStreak > 0 {
                // Has streak
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                    Text("\(currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                
                Text("Day Streak")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Text(L10n.Insights.keepItUp)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                // No streak
                Spacer()
                
                Text("No Current Streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Fast at least once a day\nto build a streak.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(InsightColors.streakCardBg)
        .clipShape(RoundedRectangle(cornerRadius: InsightColors.cardCornerRadius))
    }
    
    private func miniStreakCard(label: String, title: String, subtitle: String, value: String, unit: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 0) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.fastingOrange)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Color.fastingOrange)
            }
        }
        .padding(Spacing.md)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: InsightColors.cardCornerRadius))
    }
    
    // MARK: - Stats Section (based on reference)
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            // Main chart card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("\(totalFasts)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Fasts")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Text("This Year")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                // Mini chart
                if !periodData.isEmpty {
                    Chart(periodData) { item in
                        BarMark(
                            x: .value("Day", item.label),
                            y: .value("Hours", item.hours)
                        )
                        .foregroundStyle(.white.opacity(0.4))
                        .cornerRadius(2)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 50)
                    .padding(.top, Spacing.sm)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(InsightColors.statsChartBg)
            .clipShape(RoundedRectangle(cornerRadius: InsightColors.cardCornerRadius))
            
            // Three stat cards in a row
            HStack(spacing: Spacing.md) {
                // Total time
                solidStatCard(
                    title: "Total Time",
                    value: formattedTotalTime,
                    subtitle: nil,
                    backgroundColor: InsightColors.totalDaysCard
                )
                
                // Success rate
                solidStatCard(
                    title: "Success",
                    value: "\(Int(successRate * 100))%",
                    subtitle: "Rate",
                    backgroundColor: InsightColors.visitedCard
                )
                
                // Average
                solidStatCard(
                    title: "Average",
                    value: formattedAverageTime,
                    subtitle: "Duration",
                    backgroundColor: InsightColors.writtenCard
                )
            }
            .frame(height: 100)
        }
    }
    
    private func solidStatCard(title: String, value: String, subtitle: String?, backgroundColor: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: InsightColors.cardCornerRadius))
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases) { period in
                Button {
                    withAnimation(.fastSpring) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedPeriod == period ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            selectedPeriod == period
                                ? AnyShapeStyle(Color.fastingBlue)
                                : AnyShapeStyle(Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Trend Chart Card
    
    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
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
                
                // Total for period
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedPeriodTotal)
                        .font(.title2.bold())
                        .foregroundStyle(Color.fastingBlue)
                    Text("total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Chart
            if periodData.isEmpty || periodData.allSatisfy({ $0.hours == 0 }) {
                // Empty state
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
                            colors: [.fastingBlue, .fastingTeal],
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: InsightColors.cardCornerRadius))
    }
    
    // MARK: - Computed Properties
    
    private var completedRecords: [FastingRecord] {
        records.filter { $0.status == .completed }
    }
    
    private var totalFasts: Int {
        completedRecords.count
    }
    
    private var totalHours: Double {
        completedRecords
            .compactMap { $0.actualDuration }
            .reduce(0, +) / 3600
    }
    
    private var totalMinutes: Double {
        completedRecords
            .compactMap { $0.actualDuration }
            .reduce(0, +) / 60
    }
    
    /// Formatted total time - shows hours if >= 1h, otherwise minutes
    private var formattedTotalTime: String {
        if totalHours >= 1 {
            return "\(Int(totalHours))h"
        } else {
            return "\(Int(totalMinutes))m"
        }
    }
    
    private var averageHours: Double {
        guard !completedRecords.isEmpty else { return 0 }
        return totalHours / Double(completedRecords.count)
    }
    
    private var averageMinutes: Double {
        guard !completedRecords.isEmpty else { return 0 }
        return totalMinutes / Double(completedRecords.count)
    }
    
    /// Formatted average time - shows hours if >= 1h, otherwise minutes
    private var formattedAverageTime: String {
        if averageHours >= 1 {
            return String(format: "%.1fh", averageHours)
        } else {
            return "\(Int(averageMinutes))m"
        }
    }
    
    /// Success rate: fasts that achieved their target / total fasts
    private var successRate: Double {
        guard !records.isEmpty else { return 0 }
        let successful = records.filter { record in
            // A fast is successful if completed AND achieved the target duration
            record.status == .completed && record.isGoalAchieved
        }.count
        let totalAttempts = records.count
        return Double(successful) / Double(totalAttempts)
    }
    
    private var longestFast: Double {
        (completedRecords.compactMap { $0.actualDuration }.max() ?? 0) / 3600
    }
    
    private var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    private var longestStreak: Int {
        calculateLongestStreak()
    }
    
    private var bestWeekCount: Int {
        // Calculate the best number of fasts in any 7-day period
        guard !completedRecords.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var bestCount = 0
        
        // Check each possible 7-day window
        for record in completedRecords {
            let weekStart = calendar.startOfDay(for: record.startTime)
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            
            let countInWeek = completedRecords.filter { r in
                r.startTime >= weekStart && r.startTime < weekEnd
            }.count
            
            bestCount = max(bestCount, countInWeek)
        }
        
        return bestCount
    }
    
    private var periodData: [ChartData] {
        generatePeriodData()
    }
    
    private var periodTotalHours: Double {
        periodData.reduce(0) { $0 + $1.hours }
    }
    
    private var formattedPeriodTotal: String {
        if periodTotalHours >= 1 {
            return "\(Int(periodTotalHours))h"
        } else {
            let minutes = periodTotalHours * 60
            return "\(Int(minutes))m"
        }
    }
    
    private var periodDescription: String {
        switch selectedPeriod {
        case .week: return "Last 7 days"
        case .month: return "Last 4 weeks"
        case .year: return "Last 12 months"
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
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
    
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let sortedDates = completedRecords
            .map { calendar.startOfDay(for: $0.startTime) }
            .sorted()
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var longest = 1
        var current = 1
        
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            
            if daysBetween == 1 {
                current += 1
                longest = max(longest, current)
            } else if daysBetween > 1 {
                current = 1
            }
        }
        
        return longest
    }
    
    private func generatePeriodData() -> [ChartData] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            return (0..<7).reversed().map { daysAgo in
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
                let dayRecords = completedRecords.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
                let hours = dayRecords.compactMap { $0.actualDuration }.reduce(0, +) / 3600
                
                let formatter = DateFormatter()
                formatter.dateFormat = "E"
                
                return ChartData(label: formatter.string(from: date), hours: hours)
            }
            
        case .month:
            return (0..<4).reversed().map { weeksAgo in
                let weekStart = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: now)!
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                
                let weekRecords = completedRecords.filter { record in
                    record.startTime >= weekStart && record.startTime < weekEnd
                }
                let hours = weekRecords.compactMap { $0.actualDuration }.reduce(0, +) / 3600
                
                return ChartData(label: "W\(4-weeksAgo)", hours: hours)
            }
            
        case .year:
            return (0..<12).reversed().map { monthsAgo in
                let monthStart = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
                let monthRecords = completedRecords.filter { record in
                    calendar.isDate(record.startTime, equalTo: monthStart, toGranularity: .month)
                }
                let hours = monthRecords.compactMap { $0.actualDuration }.reduce(0, +) / 3600
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                
                return ChartData(label: formatter.string(from: monthStart), hours: hours)
            }
        }
    }
}

// MARK: - Supporting Types

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    
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

// MARK: - Preview

#Preview {
    StatisticsView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
