//
//  PlanCalculator.swift
//  Fasting
//
//  科学计算引擎 — 基于2025-2030膳食指南+断食减重研究
//

import Foundation

enum PlanCalculator {
    
    /// Generate a personalized fasting plan from user profile
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
    
    /// 根据目标和经验推荐断食方案
    static func recommendPreset(for profile: UserProfile) -> FastingPreset {
        switch profile.goal {
        case .fatLoss:
            if profile.bmi >= 30 {
                return .eighteen6  // 肥胖: 更激进
            }
            return .sixteen8  // 标准减脂
            
        case .maintenance:
            return .sixteen8  // 最可持续
            
        case .metabolicReset:
            if profile.isElderly {
                return .sixteen8  // 老年人保守
            }
            return .twenty4  // 代谢重置需要更长窗口
        }
    }
    
    // MARK: - Duration Recommendation
    
    /// 推荐计划周期（周）
    static func recommendDuration(for profile: UserProfile) -> Int {
        switch profile.goal {
        case .fatLoss:
            // 8-12周产生临床显著减重 (>5kg or >5%)
            if profile.bmi >= 30 { return 12 }
            if profile.bmi >= 25 { return 10 }
            return 8
            
        case .maintenance:
            return 8  // 建立习惯
            
        case .metabolicReset:
            return 6  // 集中重置
        }
    }
    
    // MARK: - Protein Calculation
    
    /// 蛋白质目标 (g/kg/day)
    /// 基础: 1.2-1.6 g/kg
    /// 老年人: ≥1.2 g/kg 防肌少症
    /// 高强度训练: 1.6 g/kg
    static func calculateProteinPerKg(for profile: UserProfile) -> Double {
        var base: Double
        
        switch profile.activityLevel {
        case .sedentary:
            base = 1.2
        case .active:
            base = 1.4
        case .intense:
            base = 1.6
        }
        
        // 老年人保底1.2
        if profile.isElderly {
            base = max(base, 1.2)
        }
        
        // 减脂期间提高蛋白防肌肉流失
        if profile.goal == .fatLoss {
            base = min(base + 0.1, 1.6)
        }
        
        return base
    }
    
    // MARK: - Calorie Deficit
    
    /// 热量缺口 (kcal/day)
    /// 推荐: 500-750 kcal
    static func calculateCalorieDeficit(for profile: UserProfile) -> Int {
        switch profile.goal {
        case .fatLoss:
            if profile.bmi >= 30 { return 750 }
            if profile.bmi >= 25 { return 625 }
            return 500
            
        case .maintenance:
            return 0
            
        case .metabolicReset:
            return 500  // 适度缺口配合断食
        }
    }
    
    // MARK: - Weight Loss Estimation
    
    /// 预估每周减重 (kg)
    /// 1 kg 脂肪 ≈ 7700 kcal
    /// 有效减脂时长 = 断食时长 - 12h (肝糖原耗尽)
    static func estimateWeeklyLoss(deficit: Int, preset: FastingPreset) -> Double {
        guard deficit > 0 else { return 0 }
        
        // 基础热量缺口减重
        let deficitLoss = Double(deficit * 7) / 7700
        
        // 断食额外脂肪动员 bonus (保守估计)
        let effectiveFastHours = max(Double(preset.fastingHours) - 12, 0)
        let fastingBonus = effectiveFastHours * 0.01  // ~10g per effective hour per day
        
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
        
        // Week 1: Adaptation
        milestones.append(PlanMilestone(
            id: idx,
            weekNumber: 1,
            title: "Adaptation",
            description: "milestone_adaptation_desc",
            icon: "figure.walk"
        ))
        idx += 1
        
        // Week 2: Metabolic shift
        milestones.append(PlanMilestone(
            id: idx,
            weekNumber: 2,
            title: "Metabolic Shift",
            description: "milestone_metabolic_shift_desc",
            icon: "bolt.fill"
        ))
        idx += 1
        
        // Week 4: First results
        if durationWeeks >= 4 {
            let expectedLoss = String(format: "%.1f", weeklyLoss * 4)
            milestones.append(PlanMilestone(
                id: idx,
                weekNumber: 4,
                title: "First Results",
                description: "milestone_first_results_desc|\(expectedLoss)",
                icon: "chart.line.uptrend.xyaxis"
            ))
            idx += 1
        }
        
        // Week 8: Clinical significance
        if durationWeeks >= 8 {
            let expectedLoss = String(format: "%.1f", weeklyLoss * 8)
            milestones.append(PlanMilestone(
                id: idx,
                weekNumber: 8,
                title: "Clinically Significant",
                description: "milestone_clinical_desc|\(expectedLoss)",
                icon: "star.fill"
            ))
            idx += 1
        }
        
        // Week 12: Consolidation
        if durationWeeks >= 12 {
            milestones.append(PlanMilestone(
                id: idx,
                weekNumber: 12,
                title: "Consolidation",
                description: "milestone_consolidation_desc",
                icon: "trophy.fill"
            ))
            idx += 1
        }
        
        // Final milestone
        milestones.append(PlanMilestone(
            id: idx,
            weekNumber: durationWeeks,
            title: "Plan Complete",
            description: "milestone_complete_desc",
            icon: "flag.checkered"
        ))
        
        return milestones
    }
    
    // MARK: - Nutrition Summary
    
    /// Generate a nutrition summary string
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
