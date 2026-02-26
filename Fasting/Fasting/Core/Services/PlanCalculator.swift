//
//  PlanCalculator.swift
//  Fasting
//
//  科学计算引擎 — 基于2025-2030膳食指南+断食减重研究
//  v2: 健康状况安全检查 + 压力/睡眠调节
//

import Foundation

// MARK: - Safety Result

enum PlanSafetyResult {
    case safe
    case caution(reasons: [String])   // localization keys
    case blocked(reason: String)       // localization key
    
    var isBlocked: Bool {
        if case .blocked = self { return true }
        return false
    }
    
    var cautionReasons: [String] {
        if case .caution(let reasons) = self { return reasons }
        return []
    }
}

enum PlanCalculator {
    
    // MARK: - Safety Check
    
    static func safetyCheck(for profile: UserProfile) -> PlanSafetyResult {
        if profile.hasFastingContraindication {
            let conditions = profile.healthConditions.filter(\.isFastingContraindication)
            if conditions.contains(.eatingDisorder) {
                return .blocked(reason: "safety_eating_disorder")
            }
            if conditions.contains(.pregnant) {
                return .blocked(reason: "safety_pregnant")
            }
        }
        
        var reasons: [String] = []
        if profile.healthConditions.contains(.diabetes) { reasons.append("safety_diabetes") }
        if profile.healthConditions.contains(.thyroid) { reasons.append("safety_thyroid") }
        if profile.healthConditions.contains(.heartDisease) { reasons.append("safety_heart") }
        if profile.healthConditions.contains(.medication) { reasons.append("safety_medication") }
        if profile.isElderly { reasons.append("safety_elderly") }
        if profile.bmi < 18.5 { reasons.append("safety_underweight") }
        if profile.stressLevel == .high && profile.sleepQuality == .poor {
            reasons.append("safety_stress_sleep")
        }
        
        return reasons.isEmpty ? .safe : .caution(reasons: reasons)
    }
    
    // MARK: - Generate Plan
    
    static func generatePlan(from profile: UserProfile) -> FastingPlan {
        let preset = recommendPreset(for: profile)
        let durationWeeks = recommendDuration(for: profile)
        let proteinPerKg = calculateProteinPerKg(for: profile)
        let proteinGrams = Int(profile.weightKg * proteinPerKg * profile.dietPreference.proteinMultiplier)
        let calorieDeficit = calculateCalorieDeficit(for: profile)
        let dailyCalories = max(Int(profile.tdee) - calorieDeficit, 1200)
        let weeklyLoss = estimateWeeklyLoss(deficit: calorieDeficit, preset: preset)
        let milestones = generateMilestones(
            durationWeeks: durationWeeks,
            goal: profile.goal,
            weeklyLoss: weeklyLoss
        )
        
        return FastingPlan(
            recommendedPreset: preset,
            durationWeeks: durationWeeks,
            dailyCalorieTarget: dailyCalories,
            calorieDeficit: calorieDeficit,
            proteinTargetGrams: proteinGrams,
            proteinPerKg: proteinPerKg,
            carbFiberRatio: 8.0,
            expectedWeeklyLossKg: weeklyLoss,
            milestones: milestones
        )
    }
    
    // MARK: - Preset Recommendation
    
    static func recommendPreset(for profile: UserProfile) -> FastingPreset {
        // Safety cap
        let maxAllowed: FastingPreset = profile.needsReducedIntensity ? .sixteen8 : .omad
        
        var recommended: FastingPreset
        
        switch profile.goal {
        case .fatLoss:
            recommended = profile.bmi >= 30 ? .eighteen6 : .sixteen8
        case .maintenance:
            recommended = .sixteen8
        case .metabolicReset:
            recommended = profile.isElderly ? .sixteen8 : .twenty4
        }
        
        // Cap by safety
        if recommended.fastingHours > maxAllowed.fastingHours {
            recommended = maxAllowed
        }
        
        // Stress/sleep downgrade
        if profile.stressLevel == .high || profile.sleepQuality == .poor {
            if recommended.fastingHours > 16 {
                recommended = .sixteen8
            }
        }
        
        return recommended
    }
    
    // MARK: - Duration Recommendation
    
    static func recommendDuration(for profile: UserProfile) -> Int {
        var base: Int
        
        switch profile.goal {
        case .fatLoss:
            if profile.bmi >= 30 { base = 12 }
            else if profile.bmi >= 25 { base = 10 }
            else { base = 8 }
        case .maintenance:
            base = 8
        case .metabolicReset:
            base = 6
        }
        
        // Shorter commitment for stressed users
        if profile.stressLevel == .high || profile.sleepQuality == .poor {
            base = max(base - 2, 4)
        }
        
        return base
    }
    
    // MARK: - Protein Calculation
    
    static func calculateProteinPerKg(for profile: UserProfile) -> Double {
        var base: Double
        
        switch profile.activityLevel {
        case .sedentary: base = 1.2
        case .active: base = 1.4
        case .intense: base = 1.6
        }
        
        if profile.isElderly { base = max(base, 1.2) }
        if profile.goal == .fatLoss { base = min(base + 0.1, 1.6) }
        
        return base
    }
    
    // MARK: - Calorie Deficit
    
    static func calculateCalorieDeficit(for profile: UserProfile) -> Int {
        var deficit: Int
        
        switch profile.goal {
        case .fatLoss:
            if profile.bmi >= 30 { deficit = 750 }
            else if profile.bmi >= 25 { deficit = 625 }
            else { deficit = 500 }
        case .maintenance:
            deficit = 0
        case .metabolicReset:
            deficit = 500
        }
        
        // Reduce for stressed users
        if profile.stressLevel == .high {
            deficit = Int(Double(deficit) * 0.75)
        }
        
        return deficit
    }
    
    // MARK: - Weight Loss Estimation
    
    static func estimateWeeklyLoss(deficit: Int, preset: FastingPreset) -> Double {
        guard deficit > 0 else { return 0 }
        let deficitLoss = Double(deficit * 7) / 7700
        let effectiveFastHours = max(Double(preset.fastingHours) - 12, 0)
        let fastingBonus = effectiveFastHours * 0.01
        return deficitLoss + fastingBonus
    }
    
    // MARK: - Milestones
    
    static func generateMilestones(
        durationWeeks: Int,
        goal: FastingGoal,
        weeklyLoss: Double
    ) -> [PlanMilestone] {
        var milestones: [PlanMilestone] = []
        var idx = 0
        
        milestones.append(PlanMilestone(id: idx, weekNumber: 1, title: "Adaptation", description: "milestone_adaptation_desc", icon: "figure.walk"))
        idx += 1
        
        milestones.append(PlanMilestone(id: idx, weekNumber: 2, title: "Metabolic Shift", description: "milestone_metabolic_shift_desc", icon: "bolt.fill"))
        idx += 1
        
        if durationWeeks >= 4 {
            let loss = String(format: "%.1f", weeklyLoss * 4)
            milestones.append(PlanMilestone(id: idx, weekNumber: 4, title: "First Results", description: "milestone_first_results_desc|\(loss)", icon: "chart.line.uptrend.xyaxis"))
            idx += 1
        }
        
        if durationWeeks >= 8 {
            let loss = String(format: "%.1f", weeklyLoss * 8)
            milestones.append(PlanMilestone(id: idx, weekNumber: 8, title: "Clinically Significant", description: "milestone_clinical_desc|\(loss)", icon: "star.fill"))
            idx += 1
        }
        
        if durationWeeks >= 12 {
            milestones.append(PlanMilestone(id: idx, weekNumber: 12, title: "Consolidation", description: "milestone_consolidation_desc", icon: "trophy.fill"))
            idx += 1
        }
        
        milestones.append(PlanMilestone(id: idx, weekNumber: durationWeeks, title: "Plan Complete", description: "milestone_complete_desc", icon: "flag.checkered"))
        
        return milestones
    }
    
    // MARK: - Nutrition Summary
    
    static func nutritionSummary(for profile: UserProfile, plan: FastingPlan) -> String {
        var lines: [String] = []
        lines.append("Daily calories: \(plan.dailyCalorieTarget) kcal")
        if plan.calorieDeficit > 0 {
            lines.append("Deficit: -\(plan.calorieDeficit) kcal from TDEE (\(Int(profile.tdee)) kcal)")
        }
        lines.append("Protein: \(plan.proteinDescription)")
        lines.append("Carb quality: total carbs ÷ fiber ≤ \(Int(plan.carbFiberRatio)):1")
        lines.append("Sodium: < 2,300mg/day")
        lines.append("Added sugar: < \(Int(Double(plan.dailyCalorieTarget) * 0.1 / 4))g/day (10% of calories)")
        if profile.isElderly {
            lines.append("⚠️ Ensure ≥\(plan.proteinTargetGrams)g protein to prevent sarcopenia")
        }
        if profile.dietPreference == .vegan {
            lines.append("⚠️ Supplement B12, D, calcium, iron, zinc, omega-3")
        }
        return lines.joined(separator: "\n")
    }
}
