//
//  RefeedGuide.swift
//  Fasting
//
//  科学复食指导 — 基于断食时长定制
//  Sources: 断食生理机制与代谢重塑指南.md
//

import SwiftUI

// MARK: - Models

struct RefeedPhase: Identifiable {
    let id = UUID()
    let icon: String
    let timingKey: String       // localization key
    let titleKey: String        // localization key
    let foodKeys: [String]      // localization keys
    let avoidKeys: [String]     // localization keys
    let reasonKey: String       // localization key
    
    var localizedTiming: String { timingKey.localized }
    var localizedTitle: String { titleKey.localized }
    var localizedFoods: [String] { foodKeys.map { $0.localized } }
    var localizedAvoid: [String] { avoidKeys.map { $0.localized } }
    var localizedReason: String { reasonKey.localized }
}

struct RefeedWarning: Identifiable {
    let id = UUID()
    let icon: String
    let messageKey: String
    
    var message: String { messageKey.localized }
}

struct RefeedStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let timing: String
    let color: Color
}

struct RefeedPlan {
    let title: String
    let subtitle: String
    let steps: [RefeedStep]
    let warnings: [String]
}

// MARK: - RefeedGuide

enum RefeedGuide {
    
    // MARK: - Phase-based API (used by RefeedGuideView in Companion/)
    
    static func phases(for duration: TimeInterval) -> [RefeedPhase] {
        let hours = duration / 3600
        if hours < 18 {
            return shortFastPhases
        } else if hours < 36 {
            return mediumFastPhases
        } else {
            return extendedFastPhases
        }
    }
    
    static func warnings(for duration: TimeInterval) -> [RefeedWarning] {
        let hours = duration / 3600
        var result: [RefeedWarning] = []
        
        // Always warn about sugar
        result.append(RefeedWarning(icon: "🚫", messageKey: "refeed_warn_no_sugar"))
        
        if hours >= 18 {
            result.append(RefeedWarning(icon: "🥄", messageKey: "refeed_warn_small_portions"))
        }
        if hours >= 36 {
            result.append(RefeedWarning(icon: "⚡", messageKey: "refeed_warn_insulin"))
        }
        return result
    }
    
    // MARK: - Legacy plan API (used by RefeedGuideView in Companion/)
    
    static func plan(forHours hours: Double) -> RefeedPlan {
        if hours < 18 {
            return shortFastPlan
        } else if hours < 24 {
            return mediumFastPlan
        } else {
            return extendedFastPlan
        }
    }
    
    // MARK: - Short Fast (< 18h)
    
    private static var shortFastPhases: [RefeedPhase] {
        [
            RefeedPhase(
                icon: "💧",
                timingKey: "refeed_timing_first",
                titleKey: "refeed_water_title",
                foodKeys: ["refeed_food_warm_water", "refeed_food_lemon_water"],
                avoidKeys: ["refeed_avoid_cold_drinks"],
                reasonKey: "refeed_reason_hydration"
            ),
            RefeedPhase(
                icon: "🥬",
                timingKey: "refeed_timing_15min",
                titleKey: "refeed_light_title",
                foodKeys: ["refeed_food_cooked_veg", "refeed_food_light_soup"],
                avoidKeys: ["refeed_avoid_raw_salad", "refeed_avoid_fried"],
                reasonKey: "refeed_reason_gentle_gut"
            ),
            RefeedPhase(
                icon: "🍽️",
                timingKey: "refeed_timing_30min",
                titleKey: "refeed_meal_title",
                foodKeys: ["refeed_food_balanced_meal", "refeed_food_lean_protein"],
                avoidKeys: ["refeed_avoid_sugar", "refeed_avoid_processed"],
                reasonKey: "refeed_reason_nutrient_restore"
            ),
        ]
    }
    
    // MARK: - Medium Fast (18-36h)
    
    private static var mediumFastPhases: [RefeedPhase] {
        [
            RefeedPhase(
                icon: "🍵",
                timingKey: "refeed_timing_first",
                titleKey: "refeed_broth_title",
                foodKeys: ["refeed_food_bone_broth", "refeed_food_miso"],
                avoidKeys: ["refeed_avoid_solid_food", "refeed_avoid_caffeine"],
                reasonKey: "refeed_reason_electrolyte"
            ),
            RefeedPhase(
                icon: "🥣",
                timingKey: "refeed_timing_30min",
                titleKey: "refeed_vegsoup_title",
                foodKeys: ["refeed_food_veg_soup", "refeed_food_steamed_veg"],
                avoidKeys: ["refeed_avoid_sugar", "refeed_avoid_dairy"],
                reasonKey: "refeed_reason_enzyme_wake"
            ),
            RefeedPhase(
                icon: "🐟",
                timingKey: "refeed_timing_1h",
                titleKey: "refeed_protein_title",
                foodKeys: ["refeed_food_fish", "refeed_food_egg", "refeed_food_tofu"],
                avoidKeys: ["refeed_avoid_red_meat", "refeed_avoid_heavy_carb"],
                reasonKey: "refeed_reason_gradual_protein"
            ),
        ]
    }
    
    // MARK: - Extended Fast (36h+)
    
    private static var extendedFastPhases: [RefeedPhase] {
        [
            RefeedPhase(
                icon: "🍵",
                timingKey: "refeed_timing_first",
                titleKey: "refeed_broth_title",
                foodKeys: ["refeed_food_bone_broth", "refeed_food_electrolyte"],
                avoidKeys: ["refeed_avoid_any_solid"],
                reasonKey: "refeed_reason_refeeding_risk"
            ),
            RefeedPhase(
                icon: "🥒",
                timingKey: "refeed_timing_1h",
                titleKey: "refeed_fermented_title",
                foodKeys: ["refeed_food_kimchi", "refeed_food_yogurt_small"],
                avoidKeys: ["refeed_avoid_sugar", "refeed_avoid_large_portions"],
                reasonKey: "refeed_reason_microbiome"
            ),
            RefeedPhase(
                icon: "🥣",
                timingKey: "refeed_timing_2h",
                titleKey: "refeed_millet_title",
                foodKeys: ["refeed_food_congee", "refeed_food_millet_porridge"],
                avoidKeys: ["refeed_avoid_wheat", "refeed_avoid_gluten"],
                reasonKey: "refeed_reason_gentle_carb"
            ),
            RefeedPhase(
                icon: "🐟",
                timingKey: "refeed_timing_3h",
                titleKey: "refeed_protein_title",
                foodKeys: ["refeed_food_fish", "refeed_food_steamed_chicken"],
                avoidKeys: ["refeed_avoid_red_meat", "refeed_avoid_fried"],
                reasonKey: "refeed_reason_rebuild"
            ),
        ]
    }
    
    // MARK: - Legacy Plan (for backward compat)
    
    private static var shortFastPlan: RefeedPlan {
        RefeedPlan(
            title: "refeed_short_title".localized,
            subtitle: "refeed_short_subtitle".localized,
            steps: [
                RefeedStep(icon: "drop.fill", title: "refeed_water_title".localized, detail: "refeed_water_detail".localized, timing: "refeed_timing_first".localized, color: .blue),
                RefeedStep(icon: "leaf.fill", title: "refeed_light_title".localized, detail: "refeed_light_detail".localized, timing: "refeed_timing_15min".localized, color: .green),
                RefeedStep(icon: "fork.knife", title: "refeed_meal_title".localized, detail: "refeed_short_meal_detail".localized, timing: "refeed_timing_30min".localized, color: .orange),
            ],
            warnings: ["refeed_warn_no_sugar".localized]
        )
    }
    
    private static var mediumFastPlan: RefeedPlan {
        RefeedPlan(
            title: "refeed_medium_title".localized,
            subtitle: "refeed_medium_subtitle".localized,
            steps: [
                RefeedStep(icon: "cup.and.saucer.fill", title: "refeed_broth_title".localized, detail: "refeed_broth_detail".localized, timing: "refeed_timing_first".localized, color: .brown),
                RefeedStep(icon: "leaf.fill", title: "refeed_vegsoup_title".localized, detail: "refeed_vegsoup_detail".localized, timing: "refeed_timing_30min".localized, color: .green),
                RefeedStep(icon: "fish.fill", title: "refeed_protein_title".localized, detail: "refeed_protein_detail".localized, timing: "refeed_timing_1h".localized, color: .pink),
            ],
            warnings: ["refeed_warn_no_sugar".localized, "refeed_warn_small_portions".localized]
        )
    }
    
    private static var extendedFastPlan: RefeedPlan {
        RefeedPlan(
            title: "refeed_extended_title".localized,
            subtitle: "refeed_extended_subtitle".localized,
            steps: [
                RefeedStep(icon: "cup.and.saucer.fill", title: "refeed_broth_title".localized, detail: "refeed_broth_extended_detail".localized, timing: "refeed_timing_first".localized, color: .brown),
                RefeedStep(icon: "leaf.fill", title: "refeed_fermented_title".localized, detail: "refeed_fermented_detail".localized, timing: "refeed_timing_1h".localized, color: .green),
                RefeedStep(icon: "carrot.fill", title: "refeed_millet_title".localized, detail: "refeed_millet_detail".localized, timing: "refeed_timing_2h".localized, color: .yellow),
                RefeedStep(icon: "fish.fill", title: "refeed_protein_title".localized, detail: "refeed_extended_protein_detail".localized, timing: "refeed_timing_3h".localized, color: .pink),
            ],
            warnings: ["refeed_warn_no_sugar".localized, "refeed_warn_small_portions".localized, "refeed_warn_insulin".localized]
        )
    }
}
