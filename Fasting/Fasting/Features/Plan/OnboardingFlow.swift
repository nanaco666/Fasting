//
//  OnboardingFlow.swift
//  Fasting
//
//  用户资料收集 — 分步引导
//

import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onComplete: (UserProfile, FastingPlan) -> Void
    
    @State private var step = 0
    @State private var age: Double = 30
    @State private var sex: BiologicalSex = .male
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var goal: FastingGoal = .fatLoss
    @State private var dietPreference: DietPreference = .omnivore
    
    private let totalSteps = 4
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index <= step ? Color.fastingGreen : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index == step ? 1.2 : 1.0)
                            .animation(.smoothSpring, value: step)
                    }
                }
                .padding(.horizontal)
                .padding(.top, Spacing.md)
                
                // Step content
                TabView(selection: $step) {
                    bodyInfoStep.tag(0)
                        .transition(.slide.combined(with: .opacity))
                    activityStep.tag(1)
                        .transition(.slide.combined(with: .opacity))
                    goalStep.tag(2)
                        .transition(.slide.combined(with: .opacity))
                    summaryStep.tag(3)
                        .transition(.slide.combined(with: .opacity))
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.smoothSpring, value: step)
                
                // Navigation buttons
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
                            withAnimation { step += 1 }
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Text("Next".localized)
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
            .navigationTitle("Your Plan".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel".localized) { dismiss() }
                }
            }
        }
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
    
    // MARK: - Step 2: Activity & Diet
    
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
    
    // MARK: - Step 3: Goal
    
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
    
    // MARK: - Step 4: Summary
    
    private var summaryStep: some View {
        let profile = buildProfile()
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
            dietPreference: dietPreference
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
