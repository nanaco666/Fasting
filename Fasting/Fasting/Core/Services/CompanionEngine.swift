//
//  CompanionEngine.swift
//  Fasting
//
//  陪伴引擎 — 身心福祉响应 + 安全守护
//  基于布辛格断食监测量表，提供科学指导与温暖陪伴
//

import Foundation

enum CompanionEngine {
    
    // MARK: - Phase Message
    
    struct PhaseMessage {
        let title: String
        let body: String
        let emoji: String
    }
    
    static func phaseMessage(hours: Double) -> PhaseMessage {
        let phase = FastingPhaseManager.currentPhase(for: hours * 3600)
        return PhaseMessage(
            title: phase.name,
            body: phase.companionMessage,
            emoji: phase.emoji
        )
    }
    
    // MARK: - Wellbeing Response (New: PWB + EWB based)
    
    static func wellbeingResponse(
        pwb: Int,
        ewb: Int,
        isHungry: Bool,
        ketone: KetoneLevel?,
        symptoms: [MoodSymptom],
        hours: Double
    ) -> String {
        var parts: [String] = []
        
        // 1. Core wellbeing feedback
        parts.append(wellbeingFeedback(pwb: pwb, ewb: ewb, hours: hours))
        
        // 2. Hunger guidance (research-backed)
        if isHungry {
            parts.append(hungerGuidance(hours: hours))
        }
        
        // 3. Ketone interpretation
        if let ketone = ketone {
            parts.append(ketoneGuidance(level: ketone, hours: hours))
        }
        
        // 4. Symptom-specific advice
        let negativeSymptoms = symptoms.filter { $0.isNegative }
        if !negativeSymptoms.isEmpty {
            parts.append(symptomAdvice(symptoms: negativeSymptoms, hours: hours))
        }
        
        // 5. Positive reinforcement
        let positiveSymptoms = symptoms.filter { !$0.isNegative }
        if !positiveSymptoms.isEmpty {
            parts.append(positiveReinforcement(symptoms: positiveSymptoms, hours: hours))
        }
        
        // 6. Safety check (always last, always present if needed)
        if let safety = safetyCheck(pwb: pwb, ewb: ewb, symptoms: symptoms, hours: hours) {
            parts.append(safety)
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    // MARK: - Legacy mood response (backward compat)
    
    static func moodResponse(mood: Mood, hours: Double, symptoms: [MoodSymptom]) -> String {
        let pwb: Int
        let ewb: Int
        switch mood {
        case .great: pwb = 9; ewb = 9
        case .good: pwb = 7; ewb = 7
        case .neutral: pwb = 5; ewb = 5
        case .tough: pwb = 3; ewb = 3
        case .struggling: pwb = 1; ewb = 1
        }
        return wellbeingResponse(pwb: pwb, ewb: ewb, isHungry: false, ketone: nil, symptoms: symptoms, hours: hours)
    }
    
    // MARK: - Wellbeing Feedback
    
    private static func wellbeingFeedback(pwb: Int, ewb: Int, hours: Double) -> String {
        let bucket = hourBucket(hours)
        let avg = Double(pwb + ewb) / 2.0
        
        // Divergence detection: body and mind feel very different
        let gap = abs(pwb - ewb)
        if gap >= 4 {
            if pwb > ewb {
                return "companion_diverge_body_strong".localized
            } else {
                return "companion_diverge_mind_strong".localized
            }
        }
        
        // Overall level
        let mood = Mood.from(pwb: pwb, ewb: ewb)
        let key = "companion_\(mood.rawValue)_\(bucket)"
        let result = key.localized
        if result != key { return result }
        return "companion_\(mood.rawValue)_general".localized
    }
    
    // MARK: - Hunger Guidance
    
    private static func hungerGuidance(hours: Double) -> String {
        // Research: 93.2% of fasters report hunger disappearing after initial phase
        if hours < 4 {
            return "hunger_guidance_early".localized
        } else if hours < 12 {
            return "hunger_guidance_mid".localized
        } else if hours < 18 {
            return "hunger_guidance_late".localized
        } else {
            return "hunger_guidance_extended".localized
        }
    }
    
    // MARK: - Ketone Guidance
    
    private static func ketoneGuidance(level: KetoneLevel, hours: Double) -> String {
        switch level {
        case .negative:
            if hours >= 12 {
                return "ketone_guidance_negative_late".localized
            }
            return "ketone_guidance_negative_early".localized
        case .trace:
            return "ketone_guidance_trace".localized
        case .small:
            return "ketone_guidance_small".localized
        case .moderate:
            return "ketone_guidance_moderate".localized
        case .large, .veryLarge:
            return "ketone_guidance_high".localized
        }
    }
    
    // MARK: - Symptom Advice
    
    private static func symptomAdvice(symptoms: [MoodSymptom], hours: Double) -> String {
        let priority: [MoodSymptom] = [.dizzy, .nausea, .headache, .anxious, .foggy, .irritable, .coldHands, .muscleAche, .restless]
        let main = priority.first { symptoms.contains($0) } ?? symptoms.first!
        return "symptom_advice_\(main.rawValue)".localized
    }
    
    // MARK: - Positive Reinforcement
    
    private static func positiveReinforcement(symptoms: [MoodSymptom], hours: Double) -> String {
        let has = { (s: MoodSymptom) in symptoms.contains(s) }
        
        if has(.energetic) && has(.clearMinded) {
            return "companion_positive_both".localized
        }
        if has(.calm) && has(.lightBody) {
            return "companion_positive_serene".localized
        }
        if has(.energetic) {
            return "companion_positive_energy".localized
        }
        if has(.clearMinded) {
            return "companion_positive_clarity".localized
        }
        if has(.calm) {
            return "companion_positive_calm".localized
        }
        if has(.lightBody) {
            return "companion_positive_light".localized
        }
        return "companion_positive_general".localized
    }
    
    // MARK: - Safety Check
    
    private static func safetyCheck(pwb: Int, ewb: Int, symptoms: [MoodSymptom], hours: Double) -> String? {
        // Critical: very low scores
        if pwb <= 2 || ewb <= 2 {
            return "companion_safety_critical".localized
        }
        
        // Dangerous symptom combos
        if symptoms.contains(.dizzy) && (symptoms.contains(.nausea) || symptoms.contains(.anxious)) {
            return "companion_safety_stop".localized
        }
        
        // Extended + struggling
        if hours >= 14 && (pwb <= 3 || ewb <= 3) {
            return "companion_safety_14h".localized
        }
        
        // Low scores warning
        if pwb <= 3 || ewb <= 3 {
            return "companion_safety_low".localized
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    private static func hourBucket(_ hours: Double) -> String {
        if hours < 4 { return "early" }
        if hours < 12 { return "mid" }
        if hours < 18 { return "late" }
        return "extended"
    }
    
    // MARK: - Completion Message
    
    static func completionMessage(hours: Double, isGoalAchieved: Bool) -> (title: String, body: String) {
        if isGoalAchieved {
            return (
                "companion_complete_title".localized,
                String(format: "companion_complete_body".localized, Int(hours))
            )
        } else {
            return (
                "companion_incomplete_title".localized,
                String(format: "companion_incomplete_body".localized, Int(hours))
            )
        }
    }
    
    static func completionMessage(duration: TimeInterval, wasGoalMet: Bool) -> (title: String, body: String) {
        completionMessage(hours: duration / 3600, isGoalAchieved: wasGoalMet)
    }
}

typealias CompanionMessages = CompanionEngine
