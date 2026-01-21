//
//  HistoryView.swift
//  Fasting
//
//  断食历史记录页面
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var selectedDate = Date()
    @State private var selectedRecord: FastingRecord?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 日历视图
                    calendarSection
                    
                    // 月度统计
                    monthlyStatsSection
                    
                    // 记录列表
                    recordsListSection
                }
                .padding()
            }
            .navigationTitle("历史记录")
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Views
    
    /// 日历区域
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 月份导航
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.headline)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 8)
            
            // 星期标题
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            hasRecord: hasRecord(on: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    /// 月度统计区域
    private var monthlyStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月统计")
                .font(.headline)
            
            HStack(spacing: 12) {
                MiniStatCard(
                    title: "完成",
                    value: "\(monthlyCompletedCount)",
                    unit: "次",
                    color: .green
                )
                
                MiniStatCard(
                    title: "总时长",
                    value: "\(Int(monthlyTotalHours))",
                    unit: "小时",
                    color: .blue
                )
                
                MiniStatCard(
                    title: "连续",
                    value: "7",  // TODO: 实际计算
                    unit: "天",
                    color: .orange
                )
            }
        }
    }
    
    /// 记录列表区域
    private var recordsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近记录")
                .font(.headline)
            
            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "暂无记录",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("开始你的第一次断食吧")
                )
                .frame(height: 200)
            } else {
                ForEach(filteredRecords.prefix(10)) { record in
                    RecordRow(record: record) {
                        selectedRecord = record
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end)!
        
        // 获取月份第一天是星期几
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var days: [Date?] = []
        
        // 添加空白天数
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // 添加实际天数
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

// MARK: - Supporting Views

/// 日历日期单元格
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
                // 背景
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                } else if isToday {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                
                VStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    // 记录指示点
                    if hasRecord {
                        Circle()
                            .fill(isSelected ? .white : .green)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 迷你统计卡片
struct MiniStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// 记录行
struct RecordRow: View {
    let record: FastingRecord
    let action: () -> Void
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: record.startTime)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                // 状态图标
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .frame(width: 32, height: 32)
                    .background(statusColor.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.presetType.displayName)
                        .font(.subheadline.weight(.medium))
                    
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 时长
                Text(FastingRecord.formatShortDuration(record.actualDuration ?? record.currentDuration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
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
        case .completed: return .green
        case .inProgress: return .blue
        case .cancelled: return .gray
        }
    }
}

/// 记录详情 Sheet
struct RecordDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: FastingRecord
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("方案", value: record.presetType.displayName)
                    LabeledContent("状态", value: record.status.displayName)
                }
                
                Section("时间") {
                    LabeledContent("开始时间", value: formatDate(record.startTime))
                    if let endTime = record.endTime {
                        LabeledContent("结束时间", value: formatDate(endTime))
                    }
                    LabeledContent("目标时长", value: formatDuration(record.targetDuration))
                    if let actual = record.actualDuration {
                        LabeledContent("实际时长", value: formatDuration(actual))
                    }
                }
                
                if record.isGoalAchieved {
                    Section {
                        Label("已达成目标", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("断食详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
