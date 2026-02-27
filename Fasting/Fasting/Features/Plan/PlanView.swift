//
//  PlanView.swift
//  Fasting
//
//  5 cards: Overview → Nutrition → Calendar → Activity → Fitness
//  ADA: 3 typography levels, spring animations, haptics, one hero per card
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
    @State private var expandedMilestone: Int?
    
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
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 64))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.fastingGreen)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(spacing: Spacing.sm) {
                Text("No Plan Yet".localized)
                    .font(.title2.bold())
                
                Text("plan_empty_desc".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showOnboarding = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Create Plan".localized)
                }
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, 18)
                .background(Color.fastingGreen, in: Capsule())
                .shadow(color: Color.fastingGreen.opacity(0.3), radius: 16, y: 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Active Plan
    
    private func activePlanContent(plan: FastingPlan, profile: UserProfile) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                // Card 1: Plan Overview + Milestones
                planOverviewCard(plan: plan)
                
                // Card 2: Daily Nutrition
                nutritionCard(plan: plan, profile: profile)
                
                // Card 3: Calendar
                calendarPreviewCard(plan: plan, profile: profile)
                
                // Card 4: Today's Activity
                activityCard(plan: plan, profile: profile)
                
                // Card 5: Fitness Advice
                fitnessAdviceCard(plan: plan, profile: profile)
            }
            .padding(.horizontal, Spacing.lg)
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
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 1: Plan Overview — Hero progress + milestones
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func planOverviewCard(plan: FastingPlan) -> some View {
        let milestones = plan.milestones
        let totalWeeks = max(plan.durationWeeks, 1)
        let currentWeek = min(plan.weeksElapsed + 1, totalWeeks)
        let remaining = max(totalWeeks - plan.weeksElapsed, 0)
        
        return VStack(spacing: Spacing.lg) {
            // Header row
            HStack(alignment: .firstTextBaseline) {
                Text(plan.recommendedPreset.displayName)
                    .font(.title2.bold())
                
                Spacer()
                
                if plan.expectedWeeklyLossKg > 0 {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(String(format: "-%.1f", plan.expectedWeeklyLossKg))
                            .font(.title3.bold())
                            .foregroundStyle(Color.fastingGreen)
                        Text("kg/wk".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Stage progress bar
            stageProgressBar(
                milestones: milestones,
                totalWeeks: totalWeeks,
                currentWeek: currentWeek
            )
            
            // Week indicator
            HStack {
                Text("plan_week_of".localized(currentWeek, totalWeeks))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("plan_weeks_left".localized(remaining))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Tapped milestone detail (progressive disclosure)
            if let idx = expandedMilestone,
               let milestone = milestones.first(where: { $0.id == idx }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: milestone.icon)
                        .font(.subheadline)
                        .foregroundStyle(plan.weeksElapsed >= milestone.weekNumber ? Color.fastingGreen : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(milestone.title.localized)
                            .font(.subheadline.weight(.semibold))
                        Text(milestone.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.large)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: expandedMilestone)
    }
    
    private func stageProgressBar(milestones: [PlanMilestone], totalWeeks: Int, currentWeek: Int) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let progress = CGFloat(currentWeek) / CGFloat(totalWeeks)
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 6)
                
                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.fastingGreen, Color.fastingTeal],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(w * progress, 6), height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                
                // Milestone nodes — 22pt tappable circles
                ForEach(milestones) { m in
                    let frac = CGFloat(m.weekNumber) / CGFloat(totalWeeks)
                    let x = min(max(w * frac, 11), w - 11)
                    let reached = currentWeek >= m.weekNumber
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        expandedMilestone = expandedMilestone == m.id ? nil : m.id
                    } label: {
                        ZStack {
                            Circle()
                                .fill(reached ? Color.fastingGreen : Color(.systemBackground))
                                .frame(width: 22, height: 22)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                            
                            if reached {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: m.icon)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle().scale(1.5))
                    .position(x: x, y: 3)
                }
            }
        }
        .frame(height: 22)
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 2: Daily Nutrition
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func nutritionCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Daily Nutrition".localized)
                .font(.title3.bold())
            
            HStack(spacing: Spacing.sm) {
                nutritionPill(label: "Calories".localized, value: "\(plan.dailyCalorieTarget)", unit: "kcal", color: Color.fastingOrange)
                nutritionPill(label: "Protein".localized, value: "\(plan.proteinTargetGrams)", unit: "g", color: Color.fastingGreen)
                nutritionPill(label: "Carb:Fiber ratio".localized, value: "≤8", unit: ":1", color: Color.fastingTeal)
            }
            
            if plan.calorieDeficit > 0 {
                Text("Deficit".localized + ": -\(plan.calorieDeficit) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func nutritionPill(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.title3.bold())
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 3: Calendar — 14-day preview, tap for full
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func calendarPreviewCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Upcoming".localized)
                    .font(.title3.bold())
                Spacer()
                
                if calendarService.isAuthorized {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    
    private var upcomingDaysList: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        // Build 14-day list, dedup: if a holiday matches an event title, skip the event
        let days: [(date: Date, events: [CalendarEvent], holiday: Holiday?, suggestion: FastingSuggestion?)] = (0..<14).compactMap { offset -> (date: Date, events: [CalendarEvent], holiday: Holiday?, suggestion: FastingSuggestion?)? in
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            let schedule = calendarService.weekSchedule.first(where: { cal.isDate($0.date, inSameDayAs: date) })
            let holiday = HolidayService.holiday(on: date)
            
            // Filter out events that duplicate the holiday name
            let events = (schedule?.events ?? []).filter { event in
                guard let h = holiday else { return true }
                return !event.title.localizedCaseInsensitiveContains(h.localizedName)
                    && !event.title.localizedCaseInsensitiveContains(h.englishName)
            }
            
            if events.isEmpty && holiday == nil { return nil }
            return (date, events, holiday, schedule?.suggestion)
        }
        
        return VStack(spacing: 0) {
            if days.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(Color.fastingGreen)
                    Text("plan_clear_schedule".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            } else {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    upcomingDayRow(day.date, events: day.events, holiday: day.holiday, suggestion: day.suggestion)
                    
                    if idx < days.count - 1 {
                        Divider().padding(.leading, 48)
                    }
                }
            }
        }
    }
    
    private func upcomingDayRow(_ date: Date, events: [CalendarEvent], holiday: Holiday?, suggestion: FastingSuggestion?) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        
        return HStack(alignment: .top, spacing: Spacing.md) {
            // Date badge
            VStack(spacing: 0) {
                Text(HistoryFormatters.dayOfWeekShort(date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(cal.component(.day, from: date))")
                    .font(.subheadline.weight(isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Color.fastingGreen : .primary)
            }
            .frame(width: 36)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Holiday
                if let h = holiday {
                    HStack(spacing: Spacing.xs) {
                        Text(h.fastingAdvice.emoji).font(.caption)
                        Text(h.localizedName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        presetBadge(h.fastingAdvice.suggestedPreset)
                    }
                }
                
                // Events (deduped)
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
                
                // Fasting suggestion for social/meal days
                if let s = suggestion, events.contains(where: { $0.isMealRelated || $0.isSocialEvent }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.fastingOrange)
                        Text(s.eatingWindowDescription + " " + s.preset.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                    .padding(.vertical, Spacing.sm)
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
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
    
    private var calendarGrid: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    changeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left").font(.headline).foregroundStyle(.secondary)
                }
                Spacer()
                Text(HistoryFormatters.monthYear.string(from: displayedMonth))
                    .font(.title3.bold())
                    .contentTransition(.interpolate)
                Spacer()
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    changeMonth(1)
                } label: {
                    Image(systemName: "chevron.right").font(.headline).foregroundStyle(.secondary)
                }
            }
            
            HStack {
                ForEach(HistoryFormatters.weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
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
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.large))
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
        .transition(.opacity)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    private func holidayAdviceCard(_ h: Holiday) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(h.fastingAdvice.emoji).font(.title3)
                Text(h.localizedName).font(.subheadline.weight(.semibold))
                Spacer()
                presetBadge(h.fastingAdvice.suggestedPreset)
            }
            Text(h.fastingAdvice.localizedDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    private var emptyDayCard: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "moon.zzz")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text("No fasts this day".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 4: Today's Activity
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func activityCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Activity".localized)
                .font(.title3.bold())
            
            if healthService.isAuthorized {
                HStack(spacing: Spacing.sm) {
                    activityPill(label: "Active Calories".localized, value: "\(Int(healthService.todayActiveCalories))", unit: "kcal", color: Color.fastingOrange)
                    activityPill(label: "Steps".localized, value: "\(healthService.todaySteps)", unit: "", color: Color.fastingGreen)
                }
                
                if !healthService.weekWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("This Week's Workouts".localized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, Spacing.xs)
                        
                        ForEach(healthService.weekWorkouts.prefix(4)) { workout in
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: workout.typeIcon)
                                    .font(.caption)
                                    .foregroundStyle(Color.fastingTeal)
                                    .frame(width: 20)
                                Text(workout.typeName).font(.caption)
                                Spacer()
                                Text(workout.durationFormatted).font(.caption2).foregroundStyle(.tertiary)
                                Text("\(Int(workout.calories)) kcal").font(.caption2.weight(.medium)).foregroundStyle(Color.fastingOrange)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(Color.fastingOrange)
                    Text("health_connect_desc".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            let authorized = await healthService.requestAuthorization()
                            if authorized {
                                await healthService.fetchTodayData()
                                await healthService.fetchWeekData()
                            }
                        }
                    } label: {
                        Text("Connect Health".localized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.fastingTeal, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
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
                if !unit.isEmpty { Text(unit).font(.caption2).foregroundStyle(.secondary) }
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.small))
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 5: Fitness Advice
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func fitnessAdviceCard(plan: FastingPlan, profile: UserProfile) -> some View {
        let recommendations = FitnessAdvisor.recommendations(for: profile, plan: plan)
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Fitness Advice".localized)
                .font(.title3.bold())
            
            ForEach(recommendations) { rec in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: rec.icon)
                        .font(.caption)
                        .foregroundStyle(priorityColor(rec.priority))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rec.title)
                            .font(.subheadline.weight(.semibold))
                        Text(rec.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
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
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
