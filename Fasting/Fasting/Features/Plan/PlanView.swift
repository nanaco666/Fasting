//
//  PlanView.swift
//  Fasting
//
//  Plan = 日历(过去记录+未来events) + 方案 + 营养 + 运动
//  "重新获得控制感"
//

import SwiftUI
import SwiftData
import HealthKit

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.createdAt, order: .reverse) private var plans: [FastingPlan]
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @Query private var profiles: [UserProfile]
    
    @State private var showOnboarding = false
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var selectedRecord: FastingRecord?
    
    private var healthService: HealthKitService { HealthKitService.shared }
    
    private var activePlan: FastingPlan? {
        plans.first(where: { $0.isActive })
    }
    
    private var profile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                if let plan = activePlan, let profile = profile {
                    activePlanContent(plan: plan, profile: profile)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Plan".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if activePlan != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit Profile".localized) { showOnboarding = true }
                            Button("Reset Plan".localized, role: .destructive) { resetPlan() }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingFlow { _, _ in
                    showOnboarding = false
                }
            }
            .sheet(item: $selectedRecord) { record in
                RecordDetailSheet(record: record)
                    .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.fastingGreen)
            
            Text("No Plan Yet".localized)
                .font(.title.bold())
            
            Text("Create a personalized fasting plan\nbased on your body and goals.".localized)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showOnboarding = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                    Text("Create Plan".localized)
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(colors: [Color.fastingGreen, Color.fastingTeal], startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .shadow(color: Color.fastingGreen.opacity(0.3), radius: 16, y: 8)
            }
            .padding(.top, 12)
            
            Spacer()
        }
    }
    
    // MARK: - Active Plan Content
    
    private func activePlanContent(plan: FastingPlan, profile: UserProfile) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // 1. Progress + Milestones
                overviewCard(plan: plan)
                    .padding(.horizontal, Spacing.lg)
                
                milestonesSection(plan: plan)
                    .padding(.horizontal, Spacing.lg)
                
                // 2. Calendar
                calendarSection
                    .padding(.horizontal, Spacing.lg)
                
                dayDetailSection
                    .padding(.horizontal, Spacing.lg)
                
                statsRow
                    .padding(.horizontal, Spacing.lg)
                
                WeekScheduleView(basePlan: plan.recommendedPreset, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // 3. Nutrition
                nutritionCard(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // 4. Fitness
                activitySection(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                fitnessAdviceSection(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task {
            if healthService.isAuthorized {
                await healthService.fetchTodayData()
                await healthService.fetchWeekData()
            }
        }
    }
    
    // MARK: - Calendar Section (from History)
    
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
            
            // Day grid
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
            ForEach(HistoryFormatters.weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Day Detail
    
    private var dayDetailSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let date = selectedDate {
                let dayRecords = recordsOn(date)
                let isFuture = date > Calendar.current.startOfDay(for: Date())
                
                Text(dayTitle(date))
                    .font(.title3.bold())
                    .padding(.horizontal, Spacing.xs)
                
                // Holiday advice
                if let h = HolidayService.holiday(on: date) {
                    holidayAdviceCard(h)
                }
                
                if isFuture {
                    // Future: show calendar events + suggestion
                    futureDayCard(date)
                } else if dayRecords.isEmpty {
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
    
    private func futureDayCard(_ date: Date) -> some View {
        let schedule = CalendarService.shared.weekSchedule.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        })
        
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if let schedule, !schedule.events.isEmpty {
                ForEach(schedule.events.prefix(4)) { event in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(event.isMealRelated ? Color.fastingOrange : Color.fastingTeal)
                            .frame(width: 8, height: 8)
                        Text(event.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(event.timeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if schedule.hasConflicts {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(Color.fastingOrange)
                        Text(schedule.suggestion.reason.localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundStyle(Color.fastingGreen)
                    Text(String(format: "plan_suggested_window".localized,
                               schedule.suggestion.preset.displayName,
                               schedule.suggestion.eatingWindowDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.fastingGreen)
                    Text("plan_free_day".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .glassCard(cornerRadius: CornerRadius.medium)
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
        case .normal: ("Normal".localized, Color.fastingGreen)
        case .shorter: ("14:10", Color.fastingOrange)
        case .skip: ("Skip".localized, Color.gray)
        case .flexible: ("Flexible".localized, Color.fastingTeal)
        case .extended: ("Extended".localized, Color.fastingOrange)
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
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            statCard(title: "Completed".localized, value: "\(monthCompleted)", unit: L10n.History.times, color: Color.fastingGreen)
            statCard(title: "Current Streak".localized, value: "\(currentStreak)", unit: L10n.Timer.days, color: Color.fastingOrange)
            statCard(title: "Longest Streak".localized, value: "\(longestStreak)", unit: L10n.Timer.days, color: Color.fastingTeal)
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
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.medium)
    }
    
    // MARK: - Overview Card
    
    private func overviewCard(plan: FastingPlan) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.fastingGreen.opacity(0.12), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: plan.progress)
                    .stroke(Color.fastingGreen, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text(String(format: "week_number".localized, min(plan.weeksElapsed + 1, plan.durationWeeks)))
                        .font(.title3.bold())
                    Text("/\(plan.durationWeeks)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.smoothSpring, value: plan.progress)
            
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(plan.recommendedPreset.displayName)
                        .font(.title2.bold())
                    Text("Fasting Plan".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                if plan.expectedWeeklyLossKg > 0 {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f kg", plan.expectedWeeklyLossKg))
                            .font(.title2.bold())
                            .foregroundStyle(Color.fastingGreen)
                        Text("per week".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                VStack(spacing: 4) {
                    let remaining = max(plan.durationWeeks - plan.weeksElapsed, 0)
                    Text("\(remaining)")
                        .font(.title2.bold())
                    Text("weeks left".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 24)
    }
    
    // MARK: - Nutrition Card
    
    private func nutritionCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Nutrition".localized)
                .font(.title3.bold())
            
            HStack(spacing: Spacing.md) {
                nutritionPill(label: "Calories".localized, value: "\(plan.dailyCalorieTarget)", unit: "kcal", color: Color.fastingOrange)
                nutritionPill(label: "Protein".localized, value: "\(plan.proteinTargetGrams)", unit: "g", color: Color.fastingGreen)
                nutritionPill(label: "Carb:Fiber ratio".localized, value: "≤8", unit: ":1", color: Color.fastingTeal)
            }
            
            if plan.calorieDeficit > 0 {
                Text("Deficit".localized + ": -\(plan.calorieDeficit) kcal (TDEE \(Int(profile.tdee)) kcal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func nutritionPill(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title2.bold())
                Text(unit).font(.subheadline).foregroundStyle(.secondary)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Activity Section
    
    private func activitySection(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Activity".localized)
                .font(.title3.bold())
            
            if healthService.isAuthorized {
                HStack(spacing: Spacing.md) {
                    activityPill(label: "Active Calories".localized, value: "\(Int(healthService.todayActiveCalories))", unit: "kcal", color: Color.fastingOrange)
                    activityPill(label: "Steps".localized, value: "\(healthService.todaySteps)", unit: "", color: Color.fastingGreen)
                }
                
                if !healthService.weekWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("This Week's Workouts".localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, Spacing.sm)
                        
                        ForEach(healthService.weekWorkouts.prefix(5)) { workout in
                            HStack(spacing: Spacing.md) {
                                Image(systemName: workout.typeIcon)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.fastingTeal)
                                    .frame(width: 24)
                                Text(workout.typeName).font(.subheadline)
                                Spacer()
                                Text(workout.durationFormatted).font(.caption).foregroundStyle(.secondary)
                                Text("\(Int(workout.calories)) kcal").font(.caption.weight(.medium)).foregroundStyle(Color.fastingOrange)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundStyle(Color.fastingOrange)
                    Text("Connect Apple Health to track your exercise and calorie burn.".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        Task {
                            let authorized = await healthService.requestAuthorization()
                            if authorized {
                                await healthService.fetchTodayData()
                                await healthService.fetchWeekData()
                            }
                        }
                    } label: {
                        Text("Connect Health".localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.fastingTeal, in: Capsule())
                    }
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func activityPill(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title3.bold())
                if !unit.isEmpty { Text(unit).font(.caption).foregroundStyle(.secondary) }
            }
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Fitness Advice
    
    private func fitnessAdviceSection(plan: FastingPlan, profile: UserProfile) -> some View {
        let recommendations = FitnessAdvisor.recommendations(for: profile, plan: plan)
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Fitness Advice".localized)
                .font(.title3.bold())
            
            ForEach(recommendations) { rec in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: rec.icon)
                        .font(.subheadline)
                        .foregroundStyle(priorityColor(rec.priority))
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Spacing.sm) {
                            Text(rec.title).font(.subheadline.weight(.semibold))
                            if rec.priority == .critical {
                                Text("!")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.fastingOrange, in: Circle())
                            }
                        }
                        Text(rec.description).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func priorityColor(_ priority: FitnessRecommendation.Priority) -> Color {
        switch priority {
        case .critical: return Color.fastingOrange
        case .important: return Color.fastingTeal
        case .optional: return Color.fastingGreen
        }
    }
    
    // MARK: - Milestones
    
    private func milestonesSection(plan: FastingPlan) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Milestones".localized)
                .font(.title3.bold())
            
            ForEach(plan.milestones) { milestone in
                let isReached = plan.weeksElapsed >= milestone.weekNumber
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: isReached ? "checkmark.circle.fill" : milestone.icon)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isReached ? Color.fastingGreen : .secondary)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(milestone.title.localized).font(.body.weight(.semibold)).foregroundStyle(isReached ? .primary : .secondary)
                            Spacer()
                            Text("Week \(milestone.weekNumber)").font(.caption).foregroundStyle(.tertiary)
                        }
                        Text(milestone.localizedDescription).font(.subheadline).foregroundStyle(isReached ? .secondary : .tertiary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.md)
                .background(isReached ? Color.fastingGreen.opacity(0.05) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }
    
    // MARK: - Calendar Data
    
    private var monthTitle: String {
        HistoryFormatters.monthYear.string(from: displayedMonth)
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
        guard let best = dayRecords.max(by: { ($0.actualDuration ?? 0) < ($1.actualDuration ?? 0) }) else { return 0 }
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
        return HistoryFormatters.dayDetail.string(from: date)
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
                $0.status == .completed && ($0.actualDuration ?? 0) >= $0.targetDuration && cal.isDate($0.startTime, inSameDayAs: check)
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
            } else { current = 1 }
        }
        return longest
    }
    
    private func changeMonth(_ delta: Int) {
        withAnimation(.fastSpring) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
            selectedDate = nil
        }
    }
    
    // MARK: - Actions
    
    private func resetPlan() {
        for plan in plans { modelContext.delete(plan) }
        for profile in profiles { modelContext.delete(profile) }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    PlanView()
        .modelContainer(for: [FastingPlan.self, UserProfile.self, FastingRecord.self, MoodRecord.self], inMemory: true)
}
