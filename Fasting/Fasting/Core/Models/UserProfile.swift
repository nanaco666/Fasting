//
//  UserProfile.swift
//  Fasting
//
//  用户身体参数模型
//

import Foundation
import SwiftData

// MARK: - Enums

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .male: return "Male".localized
        case .female: return "Female".localized
        }
    }
    
    var localizedName: String {
        switch self {
        case .male: return "男"
        case .female: return "女"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary = "sedentary"
    case active = "active"
    case intense = "intense"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary".localized
        case .active: return "Active".localized
        case .intense: return "High Intensity".localized
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Mostly sitting, minimal exercise".localized
        case .active: return "Regular moderate activity".localized
        case .intense: return "Resistance training or intense cardio".localized
        }
    }
    
    /// Activity multiplier for TDEE calculation
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .active: return 1.55
        case .intense: return 1.725
        }
    }
}

enum FastingGoal: String, Codable, CaseIterable, Identifiable {
    case fatLoss = "fat_loss"
    case maintenance = "maintenance"
    case metabolicReset = "metabolic_reset"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fatLoss: return "Fat Loss".localized
        case .maintenance: return "Maintain Weight".localized
        case .metabolicReset: return "Metabolic Reset".localized
        }
    }
    
    var description: String {
        switch self {
        case .fatLoss: return "Reduce body fat while preserving muscle".localized
        case .maintenance: return "Maintain current weight, improve health".localized
        case .metabolicReset: return "Reset insulin sensitivity and metabolism".localized
        }
    }
    
    var icon: String {
        switch self {
        case .fatLoss: return "flame.fill"
        case .maintenance: return "equal.circle.fill"
        case .metabolicReset: return "arrow.triangle.2.circlepath"
        }
    }
}

enum DietPreference: String, Codable, CaseIterable, Identifiable {
    case omnivore = "omnivore"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .omnivore: return "Omnivore".localized
        case .vegetarian: return "Vegetarian".localized
        case .vegan: return "Vegan".localized
        }
    }
    
    /// Protein multiplier adjustment for plant-based diets
    var proteinMultiplier: Double {
        switch self {
        case .omnivore: return 1.0
        case .vegetarian: return 1.1
        case .vegan: return 1.2  // Lower bioavailability
        }
    }
}

// MARK: - User Profile Model

@Model
final class UserProfile {
    var id: UUID
    var age: Int
    var sexRaw: String
    var heightCm: Double
    var weightKg: Double
    var activityLevelRaw: String
    var goalRaw: String
    var dietPreferenceRaw: String
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed
    
    var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }
    
    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .sedentary }
        set { activityLevelRaw = newValue.rawValue }
    }
    
    var goal: FastingGoal {
        get { FastingGoal(rawValue: goalRaw) ?? .fatLoss }
        set { goalRaw = newValue.rawValue }
    }
    
    var dietPreference: DietPreference {
        get { DietPreference(rawValue: dietPreferenceRaw) ?? .omnivore }
        set { dietPreferenceRaw = newValue.rawValue }
    }
    
    /// BMI
    var bmi: Double {
        let heightM = heightCm / 100
        return weightKg / (heightM * heightM)
    }
    
    /// BMI category
    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    
    /// Basal Metabolic Rate (Mifflin-St Jeor)
    var bmr: Double {
        if sex == .male {
            return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        } else {
            return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        }
    }
    
    /// Total Daily Energy Expenditure
    var tdee: Double {
        bmr * activityLevel.multiplier
    }
    
    /// Is elderly (≥65)
    var isElderly: Bool { age >= 65 }
    
    // MARK: - Init
    
    init(
        age: Int = 30,
        sex: BiologicalSex = .male,
        heightCm: Double = 170,
        weightKg: Double = 70,
        activityLevel: ActivityLevel = .sedentary,
        goal: FastingGoal = .fatLoss,
        dietPreference: DietPreference = .omnivore
    ) {
        self.id = UUID()
        self.age = age
        self.sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevelRaw = activityLevel.rawValue
        self.goalRaw = goal.rawValue
        self.dietPreferenceRaw = dietPreference.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
