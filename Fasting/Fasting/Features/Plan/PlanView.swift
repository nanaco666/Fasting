//
//  PlanView.swift
//  Fasting
//
//  5 cards: Overview+Milestones → Nutrition → Calendar → Activity → Fitness
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
    @State private var showFullCalendar = false
    @State private var selectedRecord: FastingRecord?
    
    // Full calendar state
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    
    @StateObject private var calendarService = CalendarService.shared
    
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
                OnboardingFlow { _, _ in showOnboarding = false }
            }
            .sheet(isPresented: $showFullCalendar) {
                fullCalendarSheet
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
            
            Text("plan_empty_desc".localized)
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
                // Card 1: Plan Overview + Milestones
                planOverviewCard(plan: plan)
                    .padding(.horizontal, Spacing.lg)
                
                // Card 2: Daily Nutrition
                nutritionCard(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Card 3: Calendar (2-week preview, tap for full)
                calendarPreviewCard(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Card 4: Today's Activity
                activityCard(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Card 5: Fitness Advice
                fitnessAdviceCard(plan: plan, profile: profile)
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
            if calendarService.isAuthorized {
                await calendarService.generateWeekSchedule(basePlan: plan.recommendedPreset, profile: profile)
            }
        }
    }
    
    // ┌─────────────────────────────────────────────────┐
    // │  Card 1: Plan Overview + Stage Progress Bar     │
    // └─────────────────────────────────────────────────┘
    
    private func planOverviewCard(plan: FastingPlan) -> some View {
        let milestones = plan.milestones
        let totalWeeks = max(plan.durationWeeks, 1)
        let currentWeek = min(plan.weeksElapsed + 1, totalWeeks)
        
        return VStack(spacing: Spacing.lg) {
            // Header: plan name + stats
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.recommendedPreset.displayName)
                        .font(.title2.bold())
                    Text("plan_week_of".localized(currentWeek, totalWeeks))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if plan.expectedWeeklyLossKg > 0 {
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", plan.expectedWeeklyLossKg))
                                .font(.title3.bold())
                                .foregroundStyle(Color.fastingGreen)
                            Text("kg/wk".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    let remaining = max(totalWeeks - plan.weeksElapsed, 0)
                    Text("plan_weeks_left".localized(remaining))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            // Stage progress bar with milestones
            stageProgressBar(
                milestones: milestones,
                totalWeeks: totalWeeks,
                currentWeek: currentWeek
            )
            
            // Current milestone description
            if let current = milestones.last(where: { $0.weekNumber <= currentWeek }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: current.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color.fastingGreen)
                    Text(current.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.xl)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func stageProgressBar(milestones: [PlanMilestone], totalWeeks: Int, currentWeek: Int) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = CGFloat(currentWeek) / CGFloat(totalWeeks)
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 8)
                
                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.fastingGreen, Color.fastingTeal],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: width * progress, height: 8)
                    .animation(.smoothSpring, value: progress)
                
                // Milestone markers
                ForEach(milestones) { m in
                    let x = width * CGFloat(m.weekNumber) / CGFloat(totalWeeks)
                    let reached = currentWeek >= m.weekNumber
                    
                    Circle()
                        .fill(reached ? Color.fastingGreen : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Group {
                                if reached {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        )
                        .position(x: min(max(x, 8), width - 8), y: 4)
                }
            }
        }
        .frame(height: 16)
        
        // Milestone labels below bar
        if !milestones.isEmpty {
            GeometryReader { geo in
                let width = geo.size.width
                ForEach(milestones) { m in
                    let x = width * CGFloat(m.weekNumber) / CGFloat(max(totalWeeks, 1))
                    Text(m.title.localized)
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .position(x: min(max(x, 20), width - 20), y: 8)
                }
            }
            .frame(height: 16)
        }
    }
    
    // ┌─────────────────────────────────────────────────┐
    // │  Card 2: Daily Nutrition                        │
    // └─────────────────────────────────────────────────┘
    
    private func nutritionCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
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
    
    // ┌─────────────────────────────────────────────────┐
    // │  Card 3: Calendar Preview (next 14 days)        │
    // └─────────────────────────────────────────────────┘
    
    private func calendarPreviewCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Upcoming".localized)
                    .font(.title3.bold())
                Spacer()
                
                if calendarService.isAuthorized {
                    Button {
                        showFullCalendar = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("plan_view_all".localized)
                                .font(.caption.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.fastingTeal)
                    }
                }
            }
            
            if calendarService.isAuthorized {
                if calendarService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                } else {
                    upcomingDaysList
                }
            } else {
                calendarConnectPrompt(plan: plan, profile: profile)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    /// Show next 14 days with events or holidays
    private var upcomingDaysList: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Build 14-day list: merge weekSchedule (7 days) + holidays
        let days: [(date: Date, events: [CalendarEvent], holiday: Holiday?, suggestion: DaySuggestion?)] = (0..<14).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            let schedule = calendarService.weekSchedule.first(where: { cal.isDate($0.date, inSameDayAs: date) })
            let holiday = HolidayService.holiday(on: date)
            // Only show days with events or holidays
            if schedule?.events.isEmpty ?? true, holiday == nil { return nil }
            return (date, schedule?.events ?? [], holiday, schedule?.suggestion)
        }
        
        return VStack(spacing: 0) {
            if days.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(Color.fastingGreen)
                    Text("plan_clear_schedule".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    upcomingDayRow(day.date, events: day.events, holiday: day.holiday, suggestion: day.suggestion)
                    
                    if idx < days.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
        }
    }
    
    private func upcomingDayRow(_ date: Date, events: [CalendarEvent], holiday: Holiday?, suggestion: DaySuggestion?) -> some View {
        let cal = Calendar.current
        
        return HStack(alignment: .top, spacing: Spacing.md) {
            // Date column
            VStack(spacing: 0) {
                Text(HistoryFormatters.dayOfWeekShort(date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(cal.component(.day, from: date))")
                    .font(.headline.weight(cal.isDateInToday(date) ? .black : .medium))
                    .foregroundStyle(cal.isDateInToday(date) ? Color.fastingGreen : .primary)
            }
            .frame(width: 36)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Holiday
                if let h = holiday {
                    HStack(spacing: 4) {
                        Text(h.fastingAdvice.emoji).font(.caption)
                        Text(h.localizedName).font(.subheadline.weight(.medium))
                        Spacer()
                        presetBadge(h.fastingAdvice.suggestedPreset)
                    }
                }
                
                // Events
                ForEach(events.prefix(3)) { event in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(event.isMealRelated ? Color.fastingOrange : Color.fastingTeal)
                            .frame(width: 6, height: 6)
                        Text(event.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(event.timeRange)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Suggestion
                if let s = suggestion, events.contains(where: { $0.isMealRelated || $0.isSocialEvent }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.fastingOrange)
                        Text(s.eatingWindowDescription + " " + s.preset.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
    }
    
    private func calendarConnectPrompt(plan: FastingPlan, profile: UserProfile) -> some View {
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
                        await calendarService.generateWeekSchedule(basePlan: plan.recommendedPreset, profile: profile)
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
    
    // MARK: - Full Calendar Sheet
    
    private var fullCalendarSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    calendarGrid
                    
                    // Day detail
                    if let date = selectedDate {
                        dayDetailView(date)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.General.done) { showFullCalendar = false }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private var calendarGrid: some View {
        VStack(spacing: Spacing.md) {
            // Month nav
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(HistoryFormatters.monthYear.string(from: displayedMonth))
                    .font(.title3.bold())
                Spacer()
                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").font(.headline).foregroundStyle(.secondary)
                }
            }
            
            // Weekday headers
            HStack {
                ForEach(HistoryFormatters.weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.large))
    }
    
    private func dayDetailView(_ date: Date) -> some View {
        let dayRecords = recordsOn(date)
        let isFuture = date > Calendar.current.startOfDay(for: Date())
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text(dayTitle(date))
                .font(.title3.bold())
            
            if let h = HolidayService.holiday(on: date) {
                holidayAdviceCard(h)
            }
            
            if isFuture {
                futureDayDetail(date)
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
    
    private func futureDayDetail(_ date: Date) -> some View {
        let schedule = calendarService.weekSchedule.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        })
        
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if let schedule, !schedule.events.isEmpty {
                ForEach(schedule.events.prefix(6)) { event in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(event.isMealRelated ? Color.fastingOrange : Color.fastingTeal)
                            .frame(width: 8, height: 8)
                        Text(event.title).font(.subheadline).lineLimit(1)
                        Spacer()
                        Text(event.timeRange).font(.caption).foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(Color.fastingOrange)
                    Text(schedule.suggestion.reason.localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    private func holidayAdviceCard(_ h: Holiday) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(h.fastingAdvice.emoji).font(.title2)
                Text(h.localizedName).font(.headline)
                Spacer()
                presetBadge(h.fastingAdvice.suggestedPreset)
            }
            Text(h.fastingAdvice.localizedDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // ┌─────────────────────────────────────────────────┐
    // │  Card 4: Today's Activity                       │
    // └─────────────────────────────────────────────────┘
    
    private func activityCard(plan: FastingPlan, profile: UserProfile) -> some View {
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
                    Text("health_connect_desc".localized)
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
    
    // ┌─────────────────────────────────────────────────┐
    // │  Card 5: Fitness Advice                         │
    // └─────────────────────────────────────────────────┘
    
    private func fitnessAdviceCard(plan: FastingPlan, profile: UserProfile) -> some View {
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
    
    // MARK: - Calendar Helpers
    
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
        let dayRecords = records.filter { $0.status == .completed && cal.isDate($0.startTime, inSameDayAs: date) }
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
