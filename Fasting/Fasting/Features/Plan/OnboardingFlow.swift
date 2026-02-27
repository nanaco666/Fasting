//
//  OnboardingFlow.swift
//  Fasting
//
//  个性化方案引导 — 温暖陪伴式
//  7步：身体 → 健康 → 生活方式 → 身心 → 目标 → 日历 → 总结
//

import SwiftUI
import SwiftData
import EventKit

// MARK: - Cached Formatters

private enum OnboardingFormatters {
    static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E M/d"
        return f
    }()
}

// MARK: - OnboardingFlow

struct OnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onComplete: (UserProfile, FastingPlan) -> Void
    
    // MARK: - State
    
    @State private var step = 0
    @State private var animateIn = false
    
    // Step 1: Body
    @State private var age: Double = 30
    @State private var sex: BiologicalSex = .female
    @State private var heightCm: Double = 165
    @State private var weightKg: Double = 58
    
    // Step 2: Health
    @State private var selectedConditions: Set<HealthCondition> = []
    @State private var showSafetyAlert = false
    @State private var safetyBlockReason = ""
    
    // Step 3: Activity & Diet
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var dietPreference: DietPreference = .omnivore
    
    // Step 4: Mood & Stress
    @State private var stressLevel: StressLevel = .moderate
    @State private var sleepQuality: SleepQuality = .fair
    
    // Step 5: Goal
    @State private var goal: FastingGoal = .fatLoss
    
    // Step 6: Calendar
    @State private var calendarAuthorized = false
    @State private var weekEvents: [[EKEvent]] = []
    
    private let totalSteps = 7
    private let eventStore = EKEventStore()
    
    // Computed
    private var bmi: Double {
        let h = heightCm / 100
        guard h > 0 else { return 0 }
        return weightKg / (h * h)
    }
    
    private var proteinRange: String {
        let low = Int(weightKg * 1.2)
        let high = Int(weightKg * 1.6)
        return "\(low)-\(high)g"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fastingGreen.opacity(0.04)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    progressBar
                    
                    Group {
                        switch step {
                        case 0: bodyInfoStep
                        case 1: healthStep
                        case 2: activityStep
                        case 3: moodStep
                        case 4: goalStep
                        case 5: calendarStep
                        case 6: summaryStep
                        default: bodyInfoStep
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.smoothSpring, value: step)
                    
                    navigationButtons
                }
            }
            .navigationTitle("onboarding_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("safety_blocked_title".localized, isPresented: $showSafetyAlert) {
                Button("OK".localized) { dismiss() }
            } message: {
                Text(safetyBlockReason.localized)
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.fastingGreen.opacity(0.12))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.fastingGreen)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 4)
                    .animation(.smoothSpring, value: step)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
    
    // MARK: - Navigation
    
    private var navigationButtons: some View {
        VStack(spacing: Spacing.sm) {
            if step < totalSteps - 1 {
                Button {
                    Haptic.selection()
                    advanceStep()
                } label: {
                    Text(step == 5 ? "onboarding_skip".localized : "onboarding_next".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.fastingGreen.gradient, in: RoundedRectangle(cornerRadius: 20))
                }
            } else {
                Button {
                    Haptic.success()
                    createPlan()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark")
                        Text("onboarding_create".localized)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.fastingGreen.gradient, in: RoundedRectangle(cornerRadius: 20))
                }
            }
            
            if step > 0 {
                Button {
                    withAnimation(.smoothSpring) { step -= 1 }
                } label: {
                    Text("onboarding_back".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }
    
    private func advanceStep() {
        if step == 1 {
            let profile = buildProfile()
            let safety = PlanCalculator.safetyCheck(for: profile)
            if case .blocked(let reason) = safety {
                safetyBlockReason = reason
                showSafetyAlert = true
                return
            }
        }
        withAnimation(.smoothSpring) { step += 1 }
    }
    
    // MARK: - Step Header (reusable)
    
    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.fastingGreen)
            Text(title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }
    
    // MARK: - Science Tip (reusable)
    
    private func scienceTip(_ text: String, icon: String = "sparkles") -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.fastingTeal)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fastingTeal.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Step 1: Body Info
    
    private var bodyInfoStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "figure.stand",
                    title: "onboarding_body_title".localized,
                    subtitle: "onboarding_body_subtitle".localized
                )
                
                // Sex
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("onboarding_sex".localized)
                        .font(.subheadline.weight(.semibold))
                    
                    HStack(spacing: Spacing.sm) {
                        ForEach(BiologicalSex.allCases) { s in
                            Button {
                                sex = s
                                Haptic.selection()
                            } label: {
                                Text(s.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(sex == s ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        sex == s ? Color.fastingGreen : Color.gray.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: CornerRadius.small)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Age
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("onboarding_age".localized)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(Int(age))")
                            .font(AppFont.stat(28))
                            .foregroundStyle(Color.fastingGreen)
                            .contentTransition(.numericText())
                    }
                    Slider(value: $age, in: 16...90, step: 1)
                        .tint(Color.fastingGreen)
                    
                    if age >= 65 {
                        scienceTip("onboarding_elderly_tip".localized, icon: "heart.fill")
                    }
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Height & Weight
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("onboarding_height".localized)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(Int(heightCm)) cm")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $heightCm, in: 140...220, step: 1)
                        .tint(Color.fastingGreen)
                    
                    Divider()
                    
                    HStack {
                        Text("onboarding_weight".localized)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1f kg", weightKg))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $weightKg, in: 40...200, step: 0.5)
                        .tint(Color.fastingGreen)
                    
                    // BMI feedback
                    HStack {
                        Text("BMI")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", bmi))
                            .font(.headline)
                            .foregroundStyle(bmi < 25 ? Color.fastingGreen : bmi < 30 ? Color.fastingOrange : Color.fastingOrange)
                        Text(bmiLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: CornerRadius.small))
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Protein preview
                scienceTip(String(format: "onboarding_protein_preview".localized, proteinRange), icon: "fork.knife")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private var bmiLabel: String {
        switch bmi {
        case ..<18.5: return "onboarding_bmi_under".localized
        case 18.5..<25: return "onboarding_bmi_normal".localized
        case 25..<30: return "onboarding_bmi_over".localized
        default: return "onboarding_bmi_obese".localized
        }
    }
    
    // MARK: - Step 2: Health
    
    private var healthStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "heart.text.square",
                    title: "onboarding_health_title".localized,
                    subtitle: "onboarding_health_subtitle".localized
                )
                
                VStack(spacing: Spacing.sm) {
                    ForEach(HealthCondition.allCases.filter { $0 != .none }) { condition in
                        let selected = selectedConditions.contains(condition)
                        Button {
                            toggleCondition(condition)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: condition.icon)
                                    .font(.body)
                                    .foregroundStyle(condition.isFastingContraindication ? Color.fastingOrange : Color.fastingTeal)
                                    .frame(width: 28)
                                
                                Text(condition.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected ? Color.fastingGreen : Color.gray.opacity(0.3))
                            }
                            .padding(Spacing.md)
                            .background(
                                selected ? Color.fastingGreen.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Dynamic feedback
                if selectedConditions.contains(where: { $0.isFastingContraindication }) {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.fastingOrange)
                        Text("onboarding_contraindication_note".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.md)
                    .background(Color.fastingOrange.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                } else if selectedConditions.contains(where: { $0.requiresReducedIntensity }) {
                    scienceTip("onboarding_reduced_note".localized, icon: "heart.fill")
                } else if selectedConditions.isEmpty {
                    scienceTip("onboarding_health_clear".localized, icon: "checkmark.seal")
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private func toggleCondition(_ condition: HealthCondition) {
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            selectedConditions.insert(condition)
        }
        Haptic.selection()
    }
    
    // MARK: - Step 3: Activity & Diet
    
    private var activityStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "figure.run",
                    title: "onboarding_lifestyle_title".localized,
                    subtitle: "onboarding_lifestyle_subtitle".localized
                )
                
                // Activity
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("onboarding_activity".localized)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.sm)
                    
                    ForEach(ActivityLevel.allCases) { level in
                        let selected = activityLevel == level
                        Button {
                            activityLevel = level
                            Haptic.selection()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.displayName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.fastingGreen)
                                }
                            }
                            .padding(Spacing.md)
                            .background(
                                selected ? Color.fastingGreen.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Activity feedback
                if activityLevel == .active || activityLevel == .intense {
                    scienceTip("onboarding_active_tip".localized, icon: "bolt.fill")
                }
                
                // Diet
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("onboarding_diet".localized)
                        .font(.subheadline.weight(.semibold))
                    
                    HStack(spacing: Spacing.sm) {
                        ForEach(DietPreference.allCases) { pref in
                            Button {
                                dietPreference = pref
                                Haptic.selection()
                            } label: {
                                Text(pref.displayName)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(dietPreference == pref ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        dietPreference == pref ? Color.fastingGreen : Color.gray.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: CornerRadius.small)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if dietPreference == .vegan {
                        scienceTip("onboarding_vegan_tip".localized, icon: "leaf.fill")
                    }
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    // MARK: - Step 4: Mood & Stress
    
    private var moodStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "brain.head.profile",
                    title: "onboarding_mood_title".localized,
                    subtitle: "onboarding_mood_subtitle".localized
                )
                
                // Stress
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("onboarding_stress".localized)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.sm)
                    
                    ForEach(StressLevel.allCases) { level in
                        let selected = stressLevel == level
                        Button {
                            stressLevel = level
                            Haptic.selection()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: stressIcon(level))
                                    .font(.body)
                                    .foregroundStyle(stressColor(level))
                                    .frame(width: 28)
                                Text(level.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.fastingGreen)
                                }
                            }
                            .padding(Spacing.md)
                            .background(
                                selected ? Color.fastingGreen.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Sleep
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("onboarding_sleep".localized)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, Spacing.sm)
                    
                    ForEach(SleepQuality.allCases) { level in
                        let selected = sleepQuality == level
                        Button {
                            sleepQuality = level
                            Haptic.selection()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: sleepIcon(level))
                                    .font(.body)
                                    .foregroundStyle(sleepColor(level))
                                    .frame(width: 28)
                                Text(level.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.fastingGreen)
                                }
                            }
                            .padding(Spacing.md)
                            .background(
                                selected ? Color.fastingGreen.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Dynamic feedback
                if stressLevel == .high || sleepQuality == .poor {
                    scienceTip("onboarding_stress_sleep_tip".localized, icon: "heart.fill")
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private func stressIcon(_ level: StressLevel) -> String {
        switch level {
        case .low: return "leaf.fill"
        case .moderate: return "wind"
        case .high: return "flame.fill"
        }
    }
    
    private func stressColor(_ level: StressLevel) -> Color {
        switch level {
        case .low: return Color.fastingGreen
        case .moderate: return Color.fastingTeal
        case .high: return Color.fastingOrange
        }
    }
    
    private func sleepIcon(_ level: SleepQuality) -> String {
        switch level {
        case .good: return "moon.stars.fill"
        case .fair: return "moon.fill"
        case .poor: return "moon.haze.fill"
        }
    }
    
    private func sleepColor(_ level: SleepQuality) -> Color {
        switch level {
        case .good: return Color.fastingGreen
        case .fair: return Color.fastingTeal
        case .poor: return Color.fastingOrange
        }
    }
    
    // MARK: - Step 5: Goal
    
    private var goalStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "target",
                    title: "onboarding_goal_title".localized,
                    subtitle: "onboarding_goal_subtitle".localized
                )
                
                VStack(spacing: Spacing.sm) {
                    ForEach(FastingGoal.allCases) { g in
                        let selected = goal == g
                        Button {
                            goal = g
                            Haptic.selection()
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: g.icon)
                                    .font(.title3)
                                    .foregroundStyle(Color.fastingGreen)
                                    .frame(width: 36)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(g.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.fastingGreen)
                                }
                            }
                            .padding(Spacing.md)
                            .background(
                                selected ? Color.fastingGreen.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: CornerRadius.medium)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.sm)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Goal-specific science tip
                scienceTip(goalTip, icon: "lightbulb.fill")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private var goalTip: String {
        switch goal {
        case .fatLoss: return "onboarding_goal_fatloss_tip".localized
        case .maintenance: return "onboarding_goal_metabolic_tip".localized
        case .metabolicReset: return "onboarding_goal_clarity_tip".localized
        }
    }
    
    // MARK: - Step 6: Calendar
    
    private var calendarStep: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "calendar",
                    title: "onboarding_calendar_title".localized,
                    subtitle: "onboarding_calendar_subtitle".localized
                )
                
                if calendarAuthorized {
                    // Week preview
                    VStack(spacing: Spacing.sm) {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let events = dayOffset < weekEvents.count ? weekEvents[dayOffset] : []
                            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: Date()))!
                            calendarDayRow(date: date, events: events)
                        }
                    }
                    .padding(Spacing.md)
                    .glassCard(cornerRadius: CornerRadius.large)
                    
                    scienceTip("onboarding_calendar_connected_tip".localized, icon: "sparkles")
                } else {
                    // Connect CTA
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.fastingTeal)
                        
                        Text("onboarding_calendar_desc".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            requestCalendarAccess()
                        } label: {
                            Text("onboarding_calendar_connect".localized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.fastingTeal, in: Capsule())
                        }
                        
                        Text("onboarding_calendar_privacy".localized)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Spacing.xl)
                    .glassCard(cornerRadius: CornerRadius.large)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private func calendarDayRow(date: Date, events: [EKEvent]) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        
        return HStack(spacing: Spacing.md) {
            Text(OnboardingFormatters.dayShort.string(from: date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isToday ? Color.fastingGreen : .primary)
                .frame(width: 56, alignment: .leading)
            
            if events.isEmpty {
                Text("Free".localized)
                    .font(.caption)
                    .foregroundStyle(Color.fastingGreen.opacity(0.6))
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(events.prefix(2), id: \.eventIdentifier) { event in
                        Text(event.title ?? "")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    if events.count > 2 {
                        Text("+\(events.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func requestCalendarAccess() {
        Task {
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await eventStore.requestAccess(to: .event)
                }
                await MainActor.run {
                    calendarAuthorized = granted
                    if granted { loadWeekEvents() }
                }
            } catch {
                // Silent — user can skip this step
            }
        }
    }
    
    private func loadWeekEvents() {
        Task.detached {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            var result: [[EKEvent]] = []
            
            for dayOffset in 0..<7 {
                guard let start = calendar.date(byAdding: .day, value: dayOffset, to: today),
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                    result.append([])
                    continue
                }
                let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
                result.append(self.eventStore.events(matching: predicate))
            }
            
            await MainActor.run {
                weekEvents = result
            }
        }
    }
    
    // MARK: - Step 7: Summary
    
    private var summaryStep: some View {
        let profile = buildProfile()
        let safety = PlanCalculator.safetyCheck(for: profile)
        let plan = PlanCalculator.generatePlan(from: profile)
        
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                stepHeader(
                    icon: "checkmark.seal",
                    title: "onboarding_summary_title".localized,
                    subtitle: "onboarding_summary_subtitle".localized
                )
                
                // Safety warnings
                if case .caution(let reasons) = safety {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(reasons, id: \.self) { reason in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.fastingOrange)
                                Text(reason.localized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.fastingOrange.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                
                // Fasting plan card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "timer")
                            .foregroundStyle(Color.fastingGreen)
                        Text("onboarding_your_plan".localized)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.recommendedPreset.displayName)
                                .font(.title.weight(.bold))
                                .foregroundStyle(Color.fastingGreen)
                            Text(String(format: "onboarding_plan_duration".localized, plan.durationWeeks))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if plan.expectedWeeklyLossKg > 0 {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "~%.1f kg", plan.expectedWeeklyLossKg))
                                    .font(.headline)
                                Text("onboarding_per_week".localized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Nutrition card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(Color.fastingTeal)
                        Text("onboarding_nutrition".localized)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    summaryRow("onboarding_calories".localized, value: "\(plan.dailyCalorieTarget) kcal")
                    if plan.calorieDeficit > 0 {
                        summaryRow("onboarding_deficit".localized, value: "-\(plan.calorieDeficit) kcal")
                    }
                    summaryRow("onboarding_protein".localized, value: plan.proteinDescription)
                    summaryRow("onboarding_carb_fiber".localized, value: "≤ 8:1")
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Profile card
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        Text("onboarding_your_profile".localized)
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    summaryRow("BMI", value: String(format: "%.1f — %@", profile.bmi, bmiLabel))
                    summaryRow("TDEE", value: "\(Int(profile.tdee)) kcal")
                    summaryRow("BMR", value: "\(Int(profile.bmr)) kcal")
                }
                .padding(Spacing.md)
                .glassCard(cornerRadius: CornerRadius.large)
                
                // Warm closing message
                scienceTip("onboarding_closing_message".localized, icon: "heart.fill")
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
        }
    }
    
    // MARK: - Actions
    
    private func buildProfile() -> UserProfile {
        UserProfile(
            age: Int(age),
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            activityLevel: activityLevel,
            goal: goal,
            dietPreference: dietPreference,
            healthConditions: Array(selectedConditions),
            stressLevel: stressLevel,
            sleepQuality: sleepQuality
        )
    }
    
    private func createPlan() {
        let profile = buildProfile()
        let plan = PlanCalculator.generatePlan(from: profile)
        
        modelContext.insert(profile)
        modelContext.insert(plan)
        try? modelContext.save()
        
        onComplete(profile, plan)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow { _, _ in }
        .modelContainer(for: [UserProfile.self, FastingPlan.self], inMemory: true)
}
