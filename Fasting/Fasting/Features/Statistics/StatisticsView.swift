//
//  StatisticsView.swift
//  Fasting
//
//  统计数据页面
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    // MARK: - Properties
    
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var selectedPeriod: StatsPeriod = .week
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 主要统计卡片
                    mainStatsSection
                    
                    // 周期选择器
                    periodPicker
                    
                    // 断食趋势图表
                    trendChartSection
                    
                    // 详细统计
                    detailedStatsSection
                }
                .padding()
            }
            .navigationTitle("统计")
        }
    }
    
    // MARK: - Views
    
    /// 主要统计区域
    private var mainStatsSection: some View {
        LargeStatCard(
            title: "当前连续天数",
            value: "\(currentStreak)",
            icon: "flame.fill",
            color: .orange,
            trend: streakTrend,
            trendUp: true
        )
    }
    
    /// 周期选择器
    private var periodPicker: some View {
        Picker("周期", selection: $selectedPeriod) {
            ForEach(StatsPeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    /// 趋势图表区域
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("断食趋势")
                .font(.headline)
            
            if periodData.isEmpty {
                ContentUnavailableView(
                    "暂无数据",
                    systemImage: "chart.bar",
                    description: Text("开始断食后这里将显示趋势图")
                )
                .frame(height: 200)
            } else {
                Chart(periodData) { item in
                    BarMark(
                        x: .value("日期", item.label),
                        y: .value("时长", item.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .blue.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hours = value.as(Double.self) {
                                Text("\(Int(hours))h")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    /// 详细统计区域
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细统计")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "总断食次数",
                    value: "\(totalFasts)",
                    icon: "number",
                    color: .purple
                )
                
                StatCard(
                    title: "总断食时长",
                    value: "\(Int(totalHours))h",
                    icon: "hourglass",
                    color: .blue
                )
                
                StatCard(
                    title: "平均时长",
                    value: String(format: "%.1fh", averageHours),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                StatCard(
                    title: "完成率",
                    value: "\(Int(completionRate * 100))%",
                    icon: "percent",
                    color: .orange
                )
                
                StatCard(
                    title: "最长断食",
                    value: "\(Int(longestFast))h",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "最长连续",
                    value: "\(longestStreak)天",
                    icon: "flame.fill",
                    color: .red
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
    
    private var streakTrend: String? {
        guard currentStreak > 0 else { return nil }
        return "保持中"
    }
    
    private var periodData: [ChartData] {
        generatePeriodData()
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
                
                return ChartData(label: "第\(4-weeksAgo)周", hours: hours)
            }
            
        case .year:
            return (0..<12).reversed().map { monthsAgo in
                let monthStart = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
                let monthRecords = completedRecords.filter { record in
                    calendar.isDate(record.startTime, equalTo: monthStart, toGranularity: .month)
                }
                let hours = monthRecords.compactMap { $0.actualDuration }.reduce(0, +) / 3600
                
                let formatter = DateFormatter()
                formatter.dateFormat = "M月"
                
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
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "今年"
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
