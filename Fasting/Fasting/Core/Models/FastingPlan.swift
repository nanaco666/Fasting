//
//  FastingPlan.swift
//  Fasting
//
//  个性化断食计划模型
//

import Foundation
import SwiftData

// MARK: - Milestone

struct PlanMilestone: Codable, Identifiable {
    var id: Int
    var weekNumber: Int
    var title: String
    var description: String
    var icon: String
    var isCompleted: Bool = false
    
    /// Localize description at render time. Supports "key|arg" format for parameterized strings.
    var localizedDescription: String {
        if description.contains("|") {
            let parts = description.split(separator: "|", maxSplits: 1)
            let key = String(parts[0])
            let arg = String(parts[1])
            return String(format: key.localized, arg)
        }
        return description.localized
    }
}

// MARK: - Fasting Plan Model

@Model
final class FastingPlan {
    var id: UUID
    
    /// Recommended fasting preset
    var recommendedPresetRaw: String
    
    /// Plan duration in weeks
    var durationWeeks: Int
    
    /// Daily calorie target
    var dailyCalorieTarget: Int
    
    /// Calorie deficit from TDEE
    var calorieDeficit: Int
    
    /// Daily protein target (grams)
    var proteinTargetGrams: Int
    
    /// Protein per kg bodyweight
    var proteinPerKg: Double
    
    /// Max daily carb-to-fiber ratio target
    var carbFiberRatio: Double
    
    /// Expected weight loss per week (kg)
    var expectedWeeklyLossKg: Double
    
    /// Milestones (stored as JSON)
    var milestonesData: Data?
    
    /// Plan start date
    var startDate: Date
    
    /// Is plan active
    var isActive: Bool
    
    var createdAt: Date
    
    // MARK: - Computed
    
    var recommendedPreset: FastingPreset {
        get { FastingPreset(rawValue: recommendedPresetRaw) ?? .sixteen8 }
        set { recommendedPresetRaw = newValue.rawValue }
    }
    
    var milestones: [PlanMilestone] {
        get {
            guard let data = milestonesData else { return [] }
            return (try? JSONDecoder().decode([PlanMilestone].self, from: data)) ?? []
        }
        set {
            milestonesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Weeks elapsed since start
    var weeksElapsed: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(days / 7, 0)
    }
    
    /// Plan progress (0.0 - 1.0)
    var progress: Double {
        min(Double(weeksElapsed) / Double(durationWeeks), 1.0)
    }
    
    /// End date
    var endDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: durationWeeks, to: startDate) ?? startDate
    }
    
    /// Is plan completed
    var isCompleted: Bool {
        Date() >= endDate
    }
    
    /// Formatted protein recommendation
    var proteinDescription: String {
        "\(proteinTargetGrams)g/day (\(String(format: "%.1f", proteinPerKg))g/kg)"
    }
    
    // MARK: - Init
    
    init(
        recommendedPreset: FastingPreset,
        durationWeeks: Int,
        dailyCalorieTarget: Int,
        calorieDeficit: Int,
        proteinTargetGrams: Int,
        proteinPerKg: Double,
        carbFiberRatio: Double = 8.0,
        expectedWeeklyLossKg: Double = 0,
        milestones: [PlanMilestone] = [],
        startDate: Date = Date()
    ) {
        self.id = UUID()
        self.recommendedPresetRaw = recommendedPreset.rawValue
        self.durationWeeks = durationWeeks
        self.dailyCalorieTarget = dailyCalorieTarget
        self.calorieDeficit = calorieDeficit
        self.proteinTargetGrams = proteinTargetGrams
        self.proteinPerKg = proteinPerKg
        self.carbFiberRatio = carbFiberRatio
        self.expectedWeeklyLossKg = expectedWeeklyLossKg
        self.milestonesData = try? JSONEncoder().encode(milestones)
        self.startDate = startDate
        self.isActive = true
        self.createdAt = Date()
    }
}
