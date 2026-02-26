//
//  RefeedGuide.swift
//  Fasting
//
//  科学复食指导 — 基于断食时长定制
//  Sources: 断食生理机制与代谢重塑指南.md
//

import SwiftUI

// MARK: - Models

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
    
    // MARK: - Plan API (used by RefeedGuideView)
    
    static func plan(forHours hours: Double) -> RefeedPlan {
        if hours < 18 {
            return shortFastPlan
        } else if hours < 24 {
            return mediumFastPlan
        } else {
            return extendedFastPlan
        }
    }
    
    // MARK: - Legacy Plan (for backward compat)
    
    private static var shortFastPlan: RefeedPlan {
        RefeedPlan(
            title: "refeed_short_title".localized,
            subtitle: "refeed_short_subtitle".localized,
            steps: [
                RefeedStep(icon: "drop.fill", title: "refeed_water_title".localized, detail: "refeed_water_detail".localized, timing: "refeed_timing_first".localized, color: .fastingTeal),
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
                RefeedStep(icon: "cup.and.saucer.fill", title: "refeed_broth_title".localized, detail: "refeed_broth_detail".localized, timing: "refeed_timing_first".localized, color: .fastingOrange),
                RefeedStep(icon: "leaf.fill", title: "refeed_vegsoup_title".localized, detail: "refeed_vegsoup_detail".localized, timing: "refeed_timing_30min".localized, color: .green),
                RefeedStep(icon: "fish.fill", title: "refeed_protein_title".localized, detail: "refeed_protein_detail".localized, timing: "refeed_timing_1h".localized, color: .fastingOrange),
            ],
            warnings: ["refeed_warn_no_sugar".localized, "refeed_warn_small_portions".localized]
        )
    }
    
    private static var extendedFastPlan: RefeedPlan {
        RefeedPlan(
            title: "refeed_extended_title".localized,
            subtitle: "refeed_extended_subtitle".localized,
            steps: [
                RefeedStep(icon: "cup.and.saucer.fill", title: "refeed_broth_title".localized, detail: "refeed_broth_extended_detail".localized, timing: "refeed_timing_first".localized, color: .fastingOrange),
                RefeedStep(icon: "leaf.fill", title: "refeed_fermented_title".localized, detail: "refeed_fermented_detail".localized, timing: "refeed_timing_1h".localized, color: .green),
                RefeedStep(icon: "carrot.fill", title: "refeed_millet_title".localized, detail: "refeed_millet_detail".localized, timing: "refeed_timing_2h".localized, color: .fastingGreen),
                RefeedStep(icon: "fish.fill", title: "refeed_protein_title".localized, detail: "refeed_extended_protein_detail".localized, timing: "refeed_timing_3h".localized, color: .fastingOrange),
            ],
            warnings: ["refeed_warn_no_sugar".localized, "refeed_warn_small_portions".localized, "refeed_warn_insulin".localized]
        )
    }
}
