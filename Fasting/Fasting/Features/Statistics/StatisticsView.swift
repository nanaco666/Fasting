//
//  StatisticsView.swift
//  Fasting
//
//  Insights page - Inspired by Apple Journal Insights
//

import SwiftUI
import SwiftData
import Charts

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
                    VStack(spacing: Spacing.xxl) {
                        // Hero streak card
                        streakHeroCard
                            .padding(.horizontal, Spacing.lg)
                        
                        // Period selector
                        periodSelector
                            .padding(.horizontal, Spacing.lg)
                        
                        // Trend chart
                        trendChartCard
                            .padding(.horizontal, Spacing.lg)
                        
                        // Stats grid
                        statsGridSection
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle(L10n.Tab.insights)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Hero Streak Card
    
    private var streakHeroCard: some View {
        VStack(spacing: Spacing.lg) {
            // Flame icon with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.fastingOrange.opacity(0.4), .fastingOrange.opacity(0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [.fastingOrange, .fastingPink], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .fastingOrange.opacity(0.5), radius: 10)
            }
            
            // Streak number
            VStack(spacing: Spacing.xs) {
                Text("\(currentStreak)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.fastingOrange, .fastingPink], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text(L10n.Insights.currentStreak)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            // Encouragement
            if currentStreak > 0 {
                Text(L10n.Insights.keepItUp)
                    .font(.subheadline)
                    .foregroundStyle(Color.fastingOrange)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.fastingOrange.opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .background(AppGradients.streakCard)
        .glassCard(cornerRadius: CornerRadius.extraLarge)
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
        .background(.ultraThinMaterial)
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
                    Text("\(Int(periodTotalHours))h")
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
        .background(AppGradients.statsCard)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    // MARK: - Stats Grid Section
    
    private var statsGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.Insights.details)
                .font(.headline)
                .padding(.horizontal, Spacing.xs)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                InsightStatCard(
                    title: L10n.Insights.totalFasts,
                    value: "\(totalFasts)",
                    icon: "number.circle.fill",
                    color: Color.fastingPurple
                )
                
                InsightStatCard(
                    title: L10n.Insights.totalTime,
                    value: "\(Int(totalHours))h",
                    icon: "hourglass.circle.fill",
                    color: Color.fastingBlue
                )
                
                InsightStatCard(
                    title: L10n.Insights.avgDuration,
                    value: String(format: "%.1fh", averageHours),
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    color: Color.fastingGreen
                )
                
                InsightStatCard(
                    title: L10n.Insights.completionRate,
                    value: "\(Int(completionRate * 100))%",
                    icon: "percent",
                    color: Color.fastingOrange
                )
                
                InsightStatCard(
                    title: L10n.Insights.longestFast,
                    value: "\(Int(longestFast))h",
                    icon: "trophy.circle.fill",
                    color: .yellow
                )
                
                InsightStatCard(
                    title: L10n.Insights.longestStreak,
                    value: "\(longestStreak)d",
                    icon: "flame.circle.fill",
                    color: Color.fastingPink
                )
            }
        }
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
    
    private var averageHours: Double {
        guard !completedRecords.isEmpty else { return 0 }
        return totalHours / Double(completedRecords.count)
    }
    
    private var completionRate: Double {
        guard !records.isEmpty else { return 0 }
        let completed = records.filter { $0.status == .completed }.count
        return Double(completed) / Double(records.count)
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
    
    private var periodData: [ChartData] {
        generatePeriodData()
    }
    
    private var periodTotalHours: Double {
        periodData.reduce(0) { $0 + $1.hours }
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

// MARK: - Insight Stat Card

struct InsightStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background(color.opacity(0.08))
        .glassCard(cornerRadius: CornerRadius.medium)
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
