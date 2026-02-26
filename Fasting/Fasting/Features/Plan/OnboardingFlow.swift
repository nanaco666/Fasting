//
//  OnboardingFlow.swift
//  Fasting
//
//  用户资料收集 — 7步引导
//  1: Body Info  2: Health Screening  3: Activity & Diet
//  4: Mood & Stress  5: Goal  6: Smart Schedule (EventKit)  7: Summary
//

import SwiftUI
import SwiftData
import EventKit

struct OnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onComplete: (UserProfile, FastingPlan) -> Void
    
    // MARK: - State
    
    @State private var step = 0
    
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                
                // Step content
                TabView(selection: $step) {
                    bodyInfoStep.tag(0)
                    healthStep.tag(1)
                    activityStep.tag(2)
                    moodStep.tag(3)
                    goalStep.tag(4)
                    calendarStep.tag(5)
                    summaryStep.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smoothSpring, value: step)
                
                navigationButtons
            }
            .navigationTitle("Your Plan".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel".localized) { dismiss() }
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
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        VStack(spacing: Spacing.md) {
            if step > 0 {
                Button("Back".localized) {
                    withAnimation { step -= 1 }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if step < totalSteps - 1 {
                Button {
                    Haptic.selection()
                    advanceStep()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Text(step == 5 ? "Skip".localized : "Next".localized)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.fastingGreen, Color.fastingGreen.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                }
            } else {
                Button {
                    Haptic.success()
                    createPlan()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark")
                        Text("Create Plan".localized)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.fastingGreen, Color.fastingGreen.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                }
            }
        }
        .padding(Spacing.lg)
    }
    
    private func advanceStep() {
        // Safety check after health step
        if step == 1 {
            let profile = buildProfile()
            let safety = PlanCalculator.safetyCheck(for: profile)
            if case .blocked(let reason) = safety {
                safetyBlockReason = reason
                showSafetyAlert = true
                return
            }
        }
        withAnimation { step += 1 }
    }
    
    // MARK: - Step 1: Body Info
    
    private var bodyInfoStep: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Tell us about yourself".localized)
                        .font(.title2.bold())
                    Text("We'll use this to calculate your nutritional needs.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            Section("Basics".localized) {
                Picker("Sex", selection: $sex) {
                    ForEach(BiologicalSex.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                
                HStack {
                    Text("Age".localized)
                    Spacer()
                    Text("\(Int(age))")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $age, in: 16...90, step: 1)
                    .tint(Color.fastingGreen)
            }
            
            Section("Body".localized) {
                HStack {
                    Text("Height".localized)
                    Spacer()
                    Text("\(Int(heightCm)) cm")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $heightCm, in: 140...220, step: 1)
                    .tint(Color.fastingGreen)
                
                HStack {
                    Text("Weight".localized)
                    Spacer()
                    Text("\(Int(weightKg)) kg")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $weightKg, in: 40...200, step: 0.5)
                    .tint(Color.fastingGreen)
                
                HStack {
                    Text("BMI".localized)
                    Spacer()
                    let bmi = weightKg / pow(heightCm / 100, 2)
                    Text(String(format: "%.1f", bmi))
                        .foregroundStyle(bmi < 25 ? .green : bmi < 30 ? .orange : .red)
                        .bold()
                }
            }
        }
    }
    
    // MARK: - Step 2: Health Screening
    
    private var healthStep: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Health Check".localized)
                        .font(.title2.bold())
                    Text("Your safety matters. We'll adjust your plan accordingly.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            Section("Do you have any of these conditions?".localized) {
                ForEach(HealthCondition.allCases.filter { $0 != .none }) { condition in
                    Button {
                        toggleCondition(condition)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: condition.icon)
                                .font(.title3)
                                .foregroundStyle(condition.isFastingContraindication ? Color.fastingOrange : Color.fastingTeal)
                                .frame(width: 32)
                            
                            Text(condition.displayName)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedConditions.contains(condition) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.fastingGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !selectedConditions.isEmpty {
                Section {
                    let contraindicated = selectedConditions.filter(\.isFastingContraindication)
                    let cautionary = selectedConditions.filter(\.requiresReducedIntensity)
                    
                    if !contraindicated.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.fastingOrange)
                            Text("safety_contraindication_warning".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if !cautionary.isEmpty {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.fastingTeal)
                            Text("safety_reduced_intensity_note".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
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
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Lifestyle".localized)
                        .font(.title2.bold())
                    Text("Activity level affects calorie needs and protein targets.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            Section("Activity Level".localized) {
                ForEach(ActivityLevel.allCases) { level in
                    Button {
                        activityLevel = level
                        Haptic.selection()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.fastingGreen)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Diet".localized) {
                Picker("Preference", selection: $dietPreference) {
                    ForEach(DietPreference.allCases) { pref in
                        Text(pref.displayName).tag(pref)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Mood & Stress
    
    private var moodStep: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("How are you doing?".localized)
                        .font(.title2.bold())
                    Text("Stress and sleep affect fasting tolerance. We'll calibrate your plan.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            Section("Stress Level".localized) {
                ForEach(StressLevel.allCases) { level in
                    Button {
                        stressLevel = level
                        Haptic.selection()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(level.emoji)
                                .font(.title2)
                            Text(level.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            if stressLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.fastingGreen)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Sleep Quality".localized) {
                ForEach(SleepQuality.allCases) { level in
                    Button {
                        sleepQuality = level
                        Haptic.selection()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Text(level.emoji)
                                .font(.title2)
                            Text(level.displayName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            if sleepQuality == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.fastingGreen)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if stressLevel == .high || sleepQuality == .poor {
                Section {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(Color.fastingOrange)
                        Text("mood_gentle_note".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 5: Goal
    
    private var goalStep: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Goal".localized)
                        .font(.title2.bold())
                    Text("This determines fasting intensity and plan duration.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            Section {
                ForEach(FastingGoal.allCases) { g in
                    Button {
                        goal = g
                        Haptic.selection()
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: g.icon)
                                .font(.title2)
                                .foregroundStyle(Color.fastingGreen)
                                .frame(width: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(g.displayName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(g.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if goal == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.fastingGreen)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Step 6: Smart Schedule (EventKit)
    
    private var calendarStep: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Smart Schedule".localized)
                        .font(.title2.bold())
                    Text("Connect your calendar for personalized daily suggestions.".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            if calendarAuthorized {
                Section("This Week".localized) {
                    if weekEvents.isEmpty {
                        Text("No events this week".localized)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(0..<7, id: \.self) { dayOffset in
                            let events = dayOffset < weekEvents.count ? weekEvents[dayOffset] : []
                            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: Date()))!
                            calendarDayRow(date: date, events: events)
                        }
                    }
                }
                
                Section {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.fastingGreen)
                        Text("schedule_preview_note".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    VStack(spacing: Spacing.lg) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.fastingTeal)
                        
                        Text("calendar_permission_desc".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            requestCalendarAccess()
                        } label: {
                            Text("Connect Calendar".localized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.fastingTeal, in: Capsule())
                        }
                        
                        Text("calendar_privacy_note".localized)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
        }
    }
    
    private func calendarDayRow(date: Date, events: [EKEvent]) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "E M/d"
        let isToday = Calendar.current.isDateInToday(date)
        
        return HStack(spacing: Spacing.md) {
            Text(formatter.string(from: date))
                .font(.caption.bold())
                .foregroundStyle(isToday ? Color.fastingGreen : .primary)
                .frame(width: 56, alignment: .leading)
            
            if events.isEmpty {
                Text("Free".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .padding(.vertical, 2)
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
                print("[Calendar] Auth error: \(error)")
            }
        }
    }
    
    private func loadWeekEvents() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [[EKEvent]] = []
        
        for dayOffset in 0..<7 {
            guard let start = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else {
                result.append([])
                continue
            }
            let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
            result.append(eventStore.events(matching: predicate))
        }
        
        weekEvents = result
    }
    
    // MARK: - Step 7: Summary
    
    private var summaryStep: some View {
        let profile = buildProfile()
        let safety = PlanCalculator.safetyCheck(for: profile)
        let plan = PlanCalculator.generatePlan(from: profile)
        
        return Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Plan".localized)
                        .font(.title2.bold())
                    Text("Based on your profile, here's what we recommend:".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Spacing.md)
            }
            
            // Safety cautions
            if case .caution(let reasons) = safety {
                Section("⚠️ " + "Safety Notes".localized) {
                    ForEach(reasons, id: \.self) { reason in
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color.fastingOrange)
                                .font(.caption)
                            Text(reason.localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Fasting") {
                LabeledContent("Plan".localized, value: plan.recommendedPreset.displayName)
                LabeledContent("Duration".localized, value: "\(plan.durationWeeks) " + "weeks".localized)
                if plan.expectedWeeklyLossKg > 0 {
                    LabeledContent("Expected loss".localized, value: String(format: "~%.1f kg/week", plan.expectedWeeklyLossKg))
                }
            }
            
            Section("Nutrition".localized) {
                LabeledContent("Daily calories".localized, value: "\(plan.dailyCalorieTarget) kcal")
                if plan.calorieDeficit > 0 {
                    LabeledContent("Deficit".localized, value: "-\(plan.calorieDeficit) kcal")
                }
                LabeledContent("Protein".localized, value: plan.proteinDescription)
                LabeledContent("Carb:Fiber ratio".localized, value: "≤ 8:1")
            }
            
            Section("Profile".localized) {
                LabeledContent("BMI".localized, value: String(format: "%.1f (%@)", profile.bmi, profile.bmiCategory))
                LabeledContent("TDEE".localized, value: "\(Int(profile.tdee)) kcal")
                LabeledContent("BMR".localized, value: "\(Int(profile.bmr)) kcal")
                
                if profile.stressLevel == .high {
                    LabeledContent("Stress".localized, value: "⚠️ " + "High".localized)
                }
                if profile.sleepQuality == .poor {
                    LabeledContent("Sleep".localized, value: "⚠️ " + "Poor".localized)
                }
            }
            
            if profile.isElderly || profile.dietPreference == .vegan {
                Section("⚠️") {
                    if profile.isElderly {
                        Text("Ensure protein ≥ \(plan.proteinTargetGrams)g/day to prevent muscle loss")
                            .font(.caption)
                    }
                    if profile.dietPreference == .vegan {
                        Text("Supplement B12, vitamin D, calcium, iron, zinc, omega-3".localized)
                            .font(.caption)
                    }
                }
            }
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
