//
//  WeekScheduleView.swift
//  Fasting
//
//  "This Week" — Plan tab 核心子模块
//  看着你的日历说"这周这样安排比较好"
//

import SwiftUI

struct WeekScheduleView: View {
    @StateObject private var calendarService = CalendarService.shared
    let basePlan: FastingPreset
    let profile: UserProfile?
    
    @State private var expandedDayId: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("This Week".localized)
                    .font(.title3.bold())
                Spacer()
                if calendarService.isLoading {
                    ProgressView().scaleEffect(0.8)
                }
            }
            
            if calendarService.isAuthorized {
                if calendarService.weekSchedule.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                } else {
                    weekContent
                }
            } else {
                connectPrompt
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
        .task {
            if calendarService.isAuthorized {
                await calendarService.generateWeekSchedule(basePlan: basePlan, profile: profile)
            }
        }
    }
    
    // MARK: - Week Content
    
    private var weekContent: some View {
        VStack(spacing: 0) {
            ForEach(calendarService.weekSchedule) { day in
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.fastSpring) {
                            expandedDayId = expandedDayId == day.id ? nil : day.id
                        }
                    } label: {
                        dayRow(day)
                    }
                    .buttonStyle(.plain)
                    
                    if expandedDayId == day.id {
                        dayDetail(day)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    if day.id != calendarService.weekSchedule.last?.id {
                        Divider().padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private func dayRow(_ day: DaySchedule) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(spacing: 0) {
                Text(day.shortDate)
                    .font(.caption.bold())
                    .foregroundStyle(day.isToday ? Color.fastingGreen : .primary)
                Text(day.dayOfWeek)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                if day.events.isEmpty {
                    Text("Free".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    let mealCount = day.events.filter { $0.isMealRelated || $0.isSocialEvent }.count
                    if mealCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.caption2)
                                .foregroundStyle(Color.fastingOrange)
                            Text("\(mealCount)")
                                .font(.caption)
                                .foregroundStyle(Color.fastingOrange)
                        }
                    }
                    Text("\(day.events.count) " + "events".localized)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(day.suggestion.eatingWindowDescription)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(day.hasConflicts ? Color.fastingOrange : Color.fastingGreen)
                Text(day.suggestion.preset.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: expandedDayId == day.id ? "chevron.up" : "chevron.down")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .background(day.isToday ? Color.fastingGreen.opacity(0.04) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func dayDetail(_ day: DaySchedule) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !day.events.isEmpty {
                ForEach(day.events.prefix(4)) { event in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(event.isMealRelated ? Color.fastingOrange : Color.fastingTeal)
                            .frame(width: 8, height: 8)
                        Text(event.title).font(.caption).lineLimit(1)
                        Spacer()
                        Text(event.timeRange).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(Color.fastingGreen)
                Text(day.suggestion.reason.localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.leading, 52)
        .padding(.bottom, 8)
    }
    
    // MARK: - Connect Prompt
    
    private var connectPrompt: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "calendar.badge.plus")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.fastingTeal)
            
            Text("calendar_connect_plan_desc".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    let granted = await calendarService.requestAccess()
                    if granted {
                        await calendarService.generateWeekSchedule(basePlan: basePlan, profile: profile)
                    }
                }
            } label: {
                Text("Connect Calendar".localized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, 8)
                    .background(Color.fastingTeal, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }
}

#Preview {
    ScrollView {
        WeekScheduleView(basePlan: .sixteen8, profile: nil).padding()
    }
    .background(Color(.systemGroupedBackground))
}
