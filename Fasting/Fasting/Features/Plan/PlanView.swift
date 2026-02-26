//
//  PlanView.swift
//  Fasting
//
//  计划主页 — 显示当前计划、进度、里程碑
//

import SwiftUI
import SwiftData
import HealthKit

struct PlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingPlan.createdAt, order: .reverse) private var plans: [FastingPlan]
    @Query private var profiles: [UserProfile]
    
    @State private var showOnboarding = false
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
            .sheet(isPresented: $showOnboarding) {
                OnboardingFlow { _, _ in
                    showOnboarding = false
                }
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
                    LinearGradient(colors: [Color.fastingGreen, .fastingTeal], startPoint: .leading, endPoint: .trailing),
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
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Overview card
                overviewCard(plan: plan)
                    .padding(.horizontal, Spacing.lg)
                
                // Nutrition card
                nutritionCard(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Activity & Exercise
                activitySection(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Fitness advice
                fitnessAdviceSection(plan: plan, profile: profile)
                    .padding(.horizontal, Spacing.lg)
                
                // Milestones
                milestonesSection(plan: plan)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .task {
            if healthService.isAuthorized {
                await healthService.fetchTodayData()
                await healthService.fetchWeekData()
            }
        }
    }
    
    // MARK: - Overview Card
    
    private func overviewCard(plan: FastingPlan) -> some View {
        VStack(spacing: 24) {
            // Progress ring — larger, bolder
            ZStack {
                Circle()
                    .stroke(Color.fastingGreen.opacity(0.12), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: plan.progress)
                    .stroke(
                        Color.fastingGreen,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
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
            
            // Plan info — bigger numbers
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
                nutritionPill(
                    label: "Calories".localized,
                    value: "\(plan.dailyCalorieTarget)",
                    unit: "kcal",
                    color: Color.fastingOrange
                )
                
                nutritionPill(
                    label: "Protein".localized,
                    value: "\(plan.proteinTargetGrams)",
                    unit: "g",
                    color: Color.fastingGreen
                )
                
                nutritionPill(
                    label: "Carb:Fiber ratio".localized,
                    value: "≤8",
                    unit: ":1",
                    color: Color.fastingTeal
                )
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
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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
                // Today's stats
                HStack(spacing: Spacing.md) {
                    activityPill(
                        label: "Active Calories".localized,
                        value: "\(Int(healthService.todayActiveCalories))",
                        unit: "kcal",
                        color: Color.fastingOrange
                    )
                    
                    activityPill(
                        label: "Steps".localized,
                        value: "\(healthService.todaySteps)",
                        unit: "",
                        color: Color.fastingGreen
                    )
                }
                
                // Week workouts
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
                                
                                Text(workout.typeName)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(workout.durationFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text("\(Int(workout.calories)) kcal")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.fastingOrange)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            } else {
                // Connect HealthKit prompt
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
                            print("[HealthKit] Requesting authorization...")
                            let authorized = await healthService.requestAuthorization()
                            print("[HealthKit] Authorization result: \(authorized)")
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
                Text(value)
                    .font(.title3.bold())
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
    
    // MARK: - Fitness Advice Section
    
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
                            Text(rec.title)
                                .font(.subheadline.weight(.semibold))
                            
                            if rec.priority == .critical {
                                Text("!")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.fastingOrange, in: Circle())
                            }
                        }
                        
                        Text(rec.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
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
                    // Icon
                    Image(systemName: isReached ? "checkmark.circle.fill" : milestone.icon)
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isReached ? Color.fastingGreen : .secondary)
                        .frame(width: 36)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(milestone.title.localized)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isReached ? .primary : .secondary)
                            
                            Spacer()
                            
                            Text("Week \(milestone.weekNumber)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Text(milestone.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(isReached ? .secondary : .tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.md)
                .background(isReached ? Color.fastingGreen.opacity(0.05) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            }
        }
    }
    
    // MARK: - Actions
    
    private func resetPlan() {
        for plan in plans {
            modelContext.delete(plan)
        }
        for profile in profiles {
            modelContext.delete(profile)
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    PlanView()
        .modelContainer(for: [FastingPlan.self, UserProfile.self, FastingRecord.self], inMemory: true)
}
