//
//  FitnessRecommendations.swift
//  Fasting
//
//  科学健身建议 — 基于2025-2030膳食指南+断食研究
//

import Foundation

struct FitnessRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let priority: Priority
    
    enum Priority: Int { case critical = 0, important = 1, optional = 2 }
}

enum FitnessAdvisor {
    
    /// Generate fitness recommendations based on user profile and plan
    static func recommendations(for profile: UserProfile, plan: FastingPlan) -> [FitnessRecommendation] {
        var recs: [FitnessRecommendation] = []
        
        // 1. Resistance training — CRITICAL for everyone on a deficit
        // 文档: "2/3的减重可能来自肌肉", "抗阻力训练人群蛋白质取高值1.6g/kg"
        if plan.calorieDeficit > 0 {
            recs.append(FitnessRecommendation(
                title: "Resistance Training".localized,
                description: "resistance_training_desc".localized,
                icon: "dumbbell.fill",
                priority: .critical
            ))
        }
        
        // 2. Timing — exercise during eating window
        // 断食期间运动需注意: 高强度应在进食窗口, 低强度可在断食期
        recs.append(FitnessRecommendation(
            title: "Exercise Timing".localized,
            description: "exercise_timing_desc".localized,
            icon: "clock.arrow.2.circlepath",
            priority: .important
        ))
        
        // 3. Post-workout protein — 文档: 蛋白质1.2-1.6g/kg, ≥50%动物源
        let proteinPerMeal = plan.proteinTargetGrams / 3
        recs.append(FitnessRecommendation(
            title: "Post-Workout Protein".localized,
            description: String(format: "post_workout_protein_desc".localized, proteinPerMeal),
            icon: "fork.knife",
            priority: .important
        ))
        
        // 4. Elderly-specific
        // 文档: "老年人≥65岁必须蛋白质≥1.2g/kg防肌少症"
        if profile.isElderly {
            recs.append(FitnessRecommendation(
                title: "Sarcopenia Prevention".localized,
                description: "sarcopenia_desc".localized,
                icon: "figure.stand",
                priority: .critical
            ))
        }
        
        // 5. Walking / Low intensity — safe during fasting
        recs.append(FitnessRecommendation(
            title: "Fasted Walking".localized,
            description: "fasted_walking_desc".localized,
            icon: "figure.walk",
            priority: .optional
        ))
        
        // 6. Hydration — 文档: "断食期间胰岛素下降, 肾脏排出大量水分和钠"
        recs.append(FitnessRecommendation(
            title: "Hydration & Electrolytes".localized,
            description: "hydration_desc".localized,
            icon: "drop.fill",
            priority: .important
        ))
        
        // 7. Weekly target based on activity level
        let weeklyTarget = weeklyExerciseTarget(for: profile)
        recs.append(FitnessRecommendation(
            title: "Weekly Target".localized,
            description: String(format: "weekly_target_desc".localized, weeklyTarget.sessions, weeklyTarget.minutesPerSession),
            icon: "target",
            priority: .important
        ))
        
        return recs.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    /// Weekly exercise target
    static func weeklyExerciseTarget(for profile: UserProfile) -> (sessions: Int, minutesPerSession: Int) {
        switch profile.activityLevel {
        case .sedentary:
            return (3, 30)  // 3x30min — build up gradually
        case .active:
            return (4, 45)  // 4x45min — maintain
        case .intense:
            return (5, 60)  // 5x60min — already trained
        }
    }
    
    /// Calculate adjusted TDEE with exercise calories
    static func adjustedTDEE(baseTDEE: Double, exerciseCalories: Double) -> Double {
        baseTDEE + exerciseCalories
    }
    
    /// Net calorie balance
    static func netBalance(intake: Int, baseTDEE: Double, exerciseCalories: Double) -> Double {
        Double(intake) - (baseTDEE + exerciseCalories)
    }
}
