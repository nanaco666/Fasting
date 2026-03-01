//
//  PlanView.swift
//  Fasting
//
//  A warm companion for your journey — science underneath, care on top
//

import SwiftUI
import SwiftData
import HealthKit

// MARK: - Warm Card Style

private struct WarmCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(colorScheme == .dark
                        ? Color(white: 0.11)
                        : .white
                    )
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.05), radius: 12, x: 0, y: 4)
            }
    }
}

private extension View {
    func warmCard() -> some View { modifier(WarmCard()) }
}

// MARK: - Plan Phase (based on literature timeline)

private enum PlanPhase {
    case adaptation    // Week 1-2
    case fatAdaptation // Week 3-4
    case deepRepair    // Week 5-8
    case consolidation // Week 9+
    
    init(week: Int, totalWeeks: Int) {
        switch week {
        case 1...2: self = .adaptation
        case 3...4: self = .fatAdaptation
        case 5...8: self = .deepRepair
        default: self = .consolidation
        }
    }
    
    var greeting: String {
        switch self {
        case .adaptation: return "plan_phase_adaptation_greeting".localized
        case .fatAdaptation: return "plan_phase_fat_adaptation_greeting".localized
        case .deepRepair: return "plan_phase_deep_repair_greeting".localized
        case .consolidation: return "plan_phase_consolidation_greeting".localized
        }
    }
    
    var insight: String {
        switch self {
        case .adaptation: return "plan_phase_adaptation_insight".localized
        case .fatAdaptation: return "plan_phase_fat_adaptation_insight".localized
        case .deepRepair: return "plan_phase_deep_repair_insight".localized
        case .consolidation: return "plan_phase_consolidation_insight".localized
        }
    }
    
    var exerciseGuidance: (title: String, detail: String, icon: String) {
        switch self {
        case .adaptation:
            return ("plan_exercise_adaptation_title".localized, "plan_exercise_adaptation_detail".localized, "figure.walk")
        case .fatAdaptation:
            return ("plan_exercise_fat_adaptation_title".localized, "plan_exercise_fat_adaptation_detail".localized, "figure.run")
        case .deepRepair:
            return ("plan_exercise_deep_repair_title".localized, "plan_exercise_deep_repair_detail".localized, "dumbbell.fill")
        case .consolidation:
            return ("plan_exercise_consolidation_title".localized, "plan_exercise_consolidation_detail".localized, "figure.strengthtraining.traditional")
        }
    }
}

// MARK: - Food Pyramid Data (from 2025-2030 Dietary Guidelines)

private struct FoodGroup: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let servings: String
    let servingCount: Int      // for emoji repetition
    let servingUnit: String
    let servingSize: String    // e.g. "1 serving = 85g cooked meat"
    let detail: String
    let scienceNote: String
    let phaseTip: String?      // phase-specific advice
}

// MARK: - DGA 2025-2030 Serving Table (by calorie level)

private struct DGAServings {
    let protein: (String, Int)
    let seafood: (String, Int)
    let dairy: (String, Int)
    let vegetables: (String, Int)
    let fruit: (String, Int)
    let fats: (String, Int)
    let grains: (String, Int)
    
    /// Based on DGA 2025-2030 Daily Serving Sizes tables
    init(tdee: Double) {
        switch tdee {
        case ..<1400:
            protein = ("2\u{2013}3", 2); seafood = ("2+", 2); dairy = ("2\u{2013}3", 2)
            vegetables = ("2", 2); fruit = ("1\u{2013}2", 1); fats = ("3", 3); grains = ("1\u{2013}2", 1)
        case 1400..<1800:
            protein = ("3", 3); seafood = ("2\u{2013}3", 2); dairy = ("3", 3)
            vegetables = ("2\u{2013}3", 2); fruit = ("1\u{2013}2", 2); fats = ("3\u{2013}4", 3); grains = ("2\u{2013}3", 2)
        case 1800..<2200:
            protein = ("3\u{2013}4", 3); seafood = ("3+", 3); dairy = ("3", 3)
            vegetables = ("3", 3); fruit = ("2", 2); fats = ("4\u{2013}5", 4); grains = ("2\u{2013}4", 3)
        case 2200..<2600:
            protein = ("4\u{2013}5", 4); seafood = ("3\u{2013}4", 3); dairy = ("3", 3)
            vegetables = ("3\u{2013}4", 3); fruit = ("2\u{2013}3", 2); fats = ("5\u{2013}6", 5); grains = ("3\u{2013}4", 3)
        default: // 2600+
            protein = ("5\u{2013}6", 5); seafood = ("4+", 4); dairy = ("3", 3)
            vegetables = ("4", 4); fruit = ("3", 3); fats = ("6\u{2013}7", 6); grains = ("4\u{2013}5", 4)
        }
    }
}

private func foodPyramid(plan: FastingPlan, profile: UserProfile, phase: PlanPhase? = nil) -> [FoodGroup] {
    let isVegan = profile.dietPreference == .vegan
    let s = DGAServings(tdee: profile.tdee)
    
    // Phase-specific tips
    let proteinPhaseTip: String? = switch phase {
    case .adaptation: "plan_food_protein_phase_adaptation".localized
    case .deepRepair: "plan_food_protein_phase_repair".localized
    default: nil
    }
    
    let fatsPhaseTip: String? = switch phase {
    case .fatAdaptation: "plan_food_fats_phase_fat_adapt".localized
    default: nil
    }
    
    var groups = [
        FoodGroup(name: "plan_food_protein".localized, icon: "\u{1F969}", color: Color(red: 0.85, green: 0.35, blue: 0.25),
                  servings: s.protein.0, servingCount: s.protein.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_protein_serving_size".localized,
                  detail: isVegan ? "plan_food_protein_detail_vegan".localized : "plan_food_protein_detail".localized,
                  scienceNote: isVegan ? "plan_food_protein_science_vegan".localized : "plan_food_protein_science".localized,
                  phaseTip: proteinPhaseTip),
        FoodGroup(name: "plan_food_seafood".localized, icon: "\u{1F41F}", color: Color(red: 0.3, green: 0.6, blue: 0.75),
                  servings: s.seafood.0, servingCount: s.seafood.1, servingUnit: "plan_servings_per_week".localized,
                  servingSize: "plan_food_seafood_serving_size".localized,
                  detail: "plan_food_seafood_detail".localized, scienceNote: "plan_food_seafood_science".localized,
                  phaseTip: nil),
        FoodGroup(name: "plan_food_dairy".localized, icon: "\u{1F95B}", color: Color(red: 0.95, green: 0.9, blue: 0.75),
                  servings: s.dairy.0, servingCount: s.dairy.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_dairy_serving_size".localized,
                  detail: "plan_food_dairy_detail".localized, scienceNote: "plan_food_dairy_science".localized,
                  phaseTip: nil),
        FoodGroup(name: "plan_food_vegetables".localized, icon: "\u{1F96C}", color: Color(red: 0.4, green: 0.7, blue: 0.35),
                  servings: s.vegetables.0, servingCount: s.vegetables.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_vegetables_serving_size".localized,
                  detail: "plan_food_vegetables_detail".localized, scienceNote: "plan_food_vegetables_science".localized,
                  phaseTip: nil),
        FoodGroup(name: "plan_food_fruit".localized, icon: "\u{1FAD0}", color: Color(red: 0.55, green: 0.35, blue: 0.7),
                  servings: s.fruit.0, servingCount: s.fruit.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_fruit_serving_size".localized,
                  detail: "plan_food_fruit_detail".localized, scienceNote: "plan_food_fruit_science".localized,
                  phaseTip: nil),
        FoodGroup(name: "plan_food_healthy_fats".localized, icon: "\u{1FAD2}", color: Color(red: 0.7, green: 0.65, blue: 0.3),
                  servings: s.fats.0, servingCount: s.fats.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_fats_serving_size".localized,
                  detail: "plan_food_fats_detail".localized, scienceNote: "plan_food_fats_science".localized,
                  phaseTip: fatsPhaseTip),
        FoodGroup(name: "plan_food_whole_grains".localized, icon: "\u{1F33E}", color: Color(red: 0.75, green: 0.6, blue: 0.4),
                  servings: s.grains.0, servingCount: s.grains.1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_grains_serving_size".localized,
                  detail: "plan_food_grains_detail".localized,
                  scienceNote: String(format: "plan_food_grains_science".localized, String(format: "%.0f", plan.carbFiberRatio)),
                  phaseTip: nil),
    ]
    
    // Fermented foods bonus row
    groups.append(
        FoodGroup(name: "plan_food_fermented".localized, icon: "\u{1FAD9}", color: Color(red: 0.6, green: 0.5, blue: 0.7),
                  servings: "1\u{2013}2", servingCount: 1, servingUnit: "plan_servings_per_day".localized,
                  servingSize: "plan_food_fermented_serving_size".localized,
                  detail: "plan_food_fermented_detail".localized, scienceNote: "plan_food_fermented_science".localized,
                  phaseTip: nil)
    )
    
    return groups
}

// MARK: - Plan View

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.createdAt, order: .reverse) private var plans: [FastingPlan]
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @Query private var profiles: [UserProfile]
    
    @State private var showOnboarding = false
    @State private var showFullCalendar = false
    @State private var selectedRecord: FastingRecord?
    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var expandedFoodGroup: UUID?
    @State private var showAllFoodGroups = false
    
    private var calendarService: CalendarService { CalendarService.shared }
    private var healthService: HealthKitService { HealthKitService.shared }
    
    private var themeColor: Color { ThemeManager.shared.currentTheme.progressColor }
    private var activePlan: FastingPlan? { plans.first(where: { $0.isActive }) }
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                if let plan = activePlan, let profile = profile {
                    planContent(plan: plan, profile: profile)
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
                .font(.system(size: 56))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(themeColor)
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
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(themeColor.gradient, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: themeColor.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Plan Content (Four Cards)
    
    private func planContent(plan: FastingPlan, profile: UserProfile) -> some View {
        let totalWeeks = max(plan.durationWeeks, 1)
        let currentWeek = min(plan.weeksElapsed + 1, totalWeeks)
        let phase = PlanPhase(week: currentWeek, totalWeeks: totalWeeks)
        
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                goalCard(plan: plan, profile: profile, currentWeek: currentWeek, totalWeeks: totalWeeks, phase: phase)
                foodCard(plan: plan, profile: profile, phase: phase)
                calendarCard(plan: plan, profile: profile)
                movementCard(plan: plan, profile: profile, phase: phase)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .padding(.top, 8)
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
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 1: Goal & Progress
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func goalCard(plan: FastingPlan, profile: UserProfile, currentWeek: Int, totalWeeks: Int, phase: PlanPhase) -> some View {
        let completedThisWeek = weeklyCompletionCount()
        let streak = currentStreak()
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text(phase.greeting)
                .font(.title3.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: Spacing.md) {
                VStack(spacing: 2) {
                    Text("\(currentWeek)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(themeColor)
                    Text("plan_of_weeks".localized(totalWeeks))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 72)
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 6), count: min(totalWeeks, 12)), spacing: 6) {
                        ForEach(1...totalWeeks, id: \.self) { w in
                            Circle()
                                .fill(w <= plan.weeksElapsed
                                    ? themeColor
                                    : w == currentWeek
                                        ? themeColor.opacity(0.4)
                                        : Color.gray.opacity(0.15))
                                .frame(width: 10, height: 10)
                        }
                    }
                    
                    if streak > 0 {
                        Text("plan_streak".localized(streak))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if completedThisWeek > 0 {
                        Text("plan_weekly_completion".localized(completedThisWeek))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(Color.fastingOrange)
                    .padding(.top, 2)
                Text(phase.insight)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.fastingOrange.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.small))
        }
        .warmCard()
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 2: Eat Real Food
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func foodCard(plan: FastingPlan, profile: UserProfile, phase: PlanPhase) -> some View {
        let groups = foodPyramid(plan: plan, profile: profile, phase: phase)
        let displayGroups = showAllFoodGroups ? groups : Array(groups.prefix(4))
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Eat Real Food".localized)
                .font(.title3.weight(.medium))
            
            Text("plan_food_subtitle".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: Spacing.sm) {
                ForEach(displayGroups) { group in
                    foodGroupRow(group)
                }
            }
            
            if groups.count > 4 {
                Button {
                    Haptic.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showAllFoodGroups.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showAllFoodGroups ? "plan_show_less".localized : "plan_show_more".localized)
                            .font(.caption.weight(.medium))
                        Image(systemName: showAllFoodGroups ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.fastingTeal)
                    .frame(maxWidth: .infinity)
                }
            }
            
            HStack(alignment: .top, spacing: 10) {
                Text("8:1")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.fastingTeal)
                Text("plan_carb_fiber_rule".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.fastingTeal.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.small))
            
            // Processed food warning
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.red.opacity(0.7))
                    .padding(.top, 2)
                Text("plan_food_limit_processed".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.red.opacity(0.04), in: RoundedRectangle(cornerRadius: CornerRadius.small))
        }
        .warmCard()
    }
    
    private func foodGroupRow(_ group: FoodGroup) -> some View {
        let isExpanded = expandedFoodGroup == group.id
        
        return VStack(spacing: 0) {
            Button {
                Haptic.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    expandedFoodGroup = isExpanded ? nil : group.id
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(group.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        if !isExpanded {
                            Text(group.detail)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Emoji serving count
                    HStack(spacing: 2) {
                        Text(String(repeating: group.icon, count: group.servingCount))
                            .font(.caption)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(group.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Serving size reference
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(group.servingSize)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.caption2)
                            .foregroundStyle(group.color)
                        Text(group.scienceNote)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    // Phase-specific tip
                    if let tip = group.phaseTip {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkle")
                                .font(.caption2)
                                .foregroundStyle(Color.fastingOrange)
                            Text(tip)
                                .font(.caption)
                                .foregroundStyle(Color.fastingOrange.opacity(0.8))
                        }
                    }
                }
                .padding(.leading, 0)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 3: Calendar (14-day ring view)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func calendarCard(plan: FastingPlan, profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("plan_your_rhythm".localized)
                    .font(.title3.weight(.medium))
                Spacer()
                Button {
                    Haptic.light(); showFullCalendar = true
                } label: {
                    Text("plan_view_all".localized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.fastingTeal)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<14, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Calendar.current.startOfDay(for: Date()))!
                        miniDayCell(date: date)
                    }
                }
            }
            
            // Upcoming holiday alert
            upcomingHolidayAlert

            if calendarService.isAuthorized {
                upcomingEvents(plan: plan, profile: profile)
            } else {
                connectCalendarPrompt(plan: plan, profile: profile)
            }
        }
        .warmCard()
    }
    
    private func miniDayCell(date: Date) -> some View {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(date)
        let progress = dayProgress(date)
        let isFuture = date > Date()
        
        return VStack(spacing: 4) {
            Text(HistoryFormatters.dayOfWeekShort(date))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 2.5)
                    .frame(width: 32, height: 32)
                
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress >= 1.0 ? themeColor : Color.fastingOrange,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("\(cal.component(.day, from: date))")
                    .font(.caption2.weight(isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? AnyShapeStyle(themeColor) : isFuture ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
            }
        }
    }
    
    @ViewBuilder
    private func upcomingEvents(plan: FastingPlan, profile: UserProfile) -> some View {
        let upcoming = calendarService.weekSchedule
            .filter { $0.events.contains(where: { $0.isMealRelated || $0.isSocialEvent }) }
            .prefix(2)
        
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(Array(upcoming), id: \.date) { schedule in
                    if let event = schedule.events.first(where: { $0.isMealRelated || $0.isSocialEvent }) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.fastingOrange.opacity(0.15))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "fork.knife")
                                        .font(.caption2)
                                        .foregroundStyle(Color.fastingOrange)
                                }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title).font(.subheadline).lineLimit(1)
                                Text(schedule.suggestion.eatingWindowDescription + " " + schedule.suggestion.preset.displayName)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func connectCalendarPrompt(plan: FastingPlan, profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.title3).foregroundStyle(Color.fastingTeal.opacity(0.5))
            VStack(alignment: .leading, spacing: 2) {
                Text("plan_calendar_connect_title".localized)
                    .font(.subheadline.weight(.medium))
                Text("plan_calendar_connect_desc".localized)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Haptic.medium()
                Task {
                    let ok = await calendarService.requestAccess()
                    if ok { await calendarService.generateWeekSchedule(basePlan: plan.recommendedPreset, profile: profile) }
                }
            } label: {
                Text("Connect".localized)
                    .font(.caption.weight(.medium)).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.fastingTeal, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }
    
    @ViewBuilder
    private var upcomingHolidayAlert: some View {
        let upcoming = HolidayService.upcomingHolidays(within: 3)
        if let (date, holiday) = upcoming.first {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 10) {
                    Text(holiday.fastingAdvice.emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(holiday.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(daysUntilText(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(holiday.fastingAdvice.localizedSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(Color.fastingOrange)
                        .padding(.top, 2)
                    Text(holiday.fastingAdvice.localizedDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.fastingOrange.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.small))
            }
        }
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "Today".localized }
        if days == 1 { return "Tomorrow".localized }
        return "\(days) " + "days away".localized
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    //  Card 4: Movement
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    private func movementCard(plan: FastingPlan, profile: UserProfile, phase: PlanPhase) -> some View {
        let guidance = phase.exerciseGuidance
        
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("plan_movement_title".localized)
                .font(.title3.weight(.medium))
            
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: guidance.icon)
                    .font(.title3)
                    .foregroundStyle(Color.fastingTeal)
                    .frame(width: 36, height: 36)
                    .background(Color.fastingTeal.opacity(0.1), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(guidance.title)
                        .font(.subheadline.weight(.semibold))
                    Text(guidance.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            if healthService.isAuthorized {
                Divider()
                
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("\(healthService.todaySteps)")
                            .font(.subheadline.bold().monospacedDigit())
                        Text("Steps".localized)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    
                    VStack(spacing: 2) {
                        Text("\(Int(healthService.todayActiveCalories))")
                            .font(.subheadline.bold().monospacedDigit())
                        Text("kcal".localized)
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    
                    if let w = healthService.weekWorkouts.first {
                        VStack(spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: w.typeIcon).font(.caption2).foregroundStyle(Color.fastingTeal)
                                Text(w.durationFormatted).font(.subheadline.bold())
                            }
                            Text(w.typeName).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.fastingTeal)
                    Text("plan_electrolyte_reminder".localized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Button {
                    Haptic.medium()
                    Task {
                        let ok = await healthService.requestAuthorization()
                        if ok { await healthService.fetchTodayData(); await healthService.fetchWeekData() }
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.fill").font(.caption)
                        Text("plan_connect_health".localized).font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.fastingTeal)
                }
            }
        }
        .warmCard()
    }
    
    // MARK: - Helpers
    
    private func weeklyCompletionCount() -> Int {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return records.filter { $0.status == .completed && $0.startTime >= startOfWeek }.count
    }
    
    private func currentStreak() -> Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        for _ in 0..<365 {
            let hasRecord = records.contains { $0.status == .completed && cal.isDate($0.startTime, inSameDayAs: checkDate) }
            if hasRecord { streak += 1; checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)! }
            else { break }
        }
        return streak
    }
    
    
    // MARK: - Full Calendar Sheet
    
    private var fullCalendarSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    calendarGrid
                    if let date = selectedDate { dayDetailView(date) }
                }.padding(20)
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
        .presentationCornerRadius(CornerRadius.large)
    }
    
    private var calendarGrid: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Button { Haptic.selection(); changeMonth(-1) } label: { Image(systemName: "chevron.left").font(.headline).foregroundStyle(.secondary) }
                Spacer()
                Text(HistoryFormatters.monthYear.string(from: displayedMonth))
                    .font(.title3.bold())
                    .contentTransition(.interpolate)
                Spacer()
                Button { Haptic.selection(); changeMonth(1) } label: { Image(systemName: "chevron.right").font(.headline).foregroundStyle(.secondary) }
            }
            
            HStack {
                ForEach(HistoryFormatters.weekdaySymbols, id: \.self) { sym in
                    Text(sym).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: Spacing.md) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, item in
                    if let date = item {
                        DayRingCell(date: date, progress: dayProgress(date),
                                    isToday: Calendar.current.isDateInToday(date),
                                    isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                                    holiday: HolidayService.holiday(on: date)) {
                            Haptic.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedDate = date }
                        }
                    } else {
                        Color.clear.frame(height: 48)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.large))
    }
    
    @ViewBuilder
    private func dayDetailView(_ date: Date) -> some View {
        let dayRecords = recordsOn(date)
        let isFuture = date > Calendar.current.startOfDay(for: Date())
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(dayTitle(date)).font(.subheadline.weight(.semibold))
            if isFuture {
                Text("plan_free_day".localized).font(.subheadline).foregroundStyle(.secondary)
            } else if dayRecords.isEmpty {
                Text("No fasts this day".localized).font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(dayRecords) { record in
                    RecordRowCard(record: record) { selectedRecord = record }
                }
            }
        }
        .transition(.opacity)
    }
    
    // MARK: - Calendar Helpers
    
    private var daysInMonth: [Date?] {
        CalendarHelpers.daysInMonth(for: displayedMonth)
    }

    private func dayProgress(_ date: Date) -> Double {
        CalendarHelpers.dayProgress(on: date, records: records)
    }

    private func recordsOn(_ date: Date) -> [FastingRecord] {
        CalendarHelpers.records(on: date, from: records)
    }

    private func dayTitle(_ date: Date) -> String {
        CalendarHelpers.dayTitle(date)
    }
    
    private func changeMonth(_ delta: Int) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            displayedMonth = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) ?? displayedMonth
            selectedDate = nil
        }
    }
    
    private func resetPlan() {
        for plan in plans { modelContext.delete(plan) }
        for profile in profiles { modelContext.delete(profile) }
        try? modelContext.save()
    }
}

#Preview {
    PlanView()
        .modelContainer(for: [FastingPlan.self, UserProfile.self, FastingRecord.self, MoodRecord.self], inMemory: true)
}
