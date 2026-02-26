//
//  CompanionEngine.swift
//  Fasting
//
//  陪伴引擎 — 情绪觉知 + 安全守护
//  Phase messages now come from unified FastingPhase model
//  CompanionEngine focuses on: mood response, safety checks, completion
//

import Foundation

enum CompanionEngine {
    
    // MARK: - Phase Message (delegates to unified FastingPhase)
    
    struct PhaseMessage {
        let title: String
        let body: String
        let emoji: String
    }
    
    /// Returns unified phase info: science name + companion message
    static func phaseMessage(hours: Double) -> PhaseMessage {
        let phase = FastingPhaseManager.currentPhase(for: hours * 3600)
        return PhaseMessage(
            title: phase.name,
            body: phase.companionMessage,
            emoji: phase.emoji
        )
    }
    
    // MARK: - Mood Response
    
    static func moodResponse(mood: Mood, hours: Double, symptoms: [MoodSymptom]) -> String {
        var parts: [String] = []
        
        parts.append(baseMoodResponse(mood: mood, hours: hours))
        
        let negativeSymptoms = symptoms.filter { $0.isNegative }
        if !negativeSymptoms.isEmpty {
            parts.append(symptomAdvice(symptoms: negativeSymptoms, hours: hours))
        }
        
        let positiveSymptoms = symptoms.filter { !$0.isNegative }
        if !positiveSymptoms.isEmpty {
            parts.append(positiveReinforcement(symptoms: positiveSymptoms))
        }
        
        if let safety = safetyCheck(mood: mood, symptoms: symptoms, hours: hours) {
            parts.append(safety)
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    private static func baseMoodResponse(mood: Mood, hours: Double) -> String {
        let bucket = hourBucket(hours)
        let key = "companion_\(mood.rawValue)_\(bucket)"
        let result = key.localized
        if result == key {
            return "companion_\(mood.rawValue)_general".localized
        }
        return result
    }
    
    private static func symptomAdvice(symptoms: [MoodSymptom], hours: Double) -> String {
        let priority: [MoodSymptom] = [.dizzy, .headache, .anxious, .foggy, .irritable, .hungry]
        let main = priority.first { symptoms.contains($0) } ?? symptoms.first!
        return "symptom_advice_\(main.rawValue)".localized
    }
    
    private static func positiveReinforcement(symptoms: [MoodSymptom]) -> String {
        if symptoms.contains(.energetic) && symptoms.contains(.clearMinded) {
            return "companion_positive_both".localized
        }
        if symptoms.contains(.energetic) {
            return "companion_positive_energy".localized
        }
        return "companion_positive_clarity".localized
    }
    
    private static func safetyCheck(mood: Mood, symptoms: [MoodSymptom], hours: Double) -> String? {
        if mood == .struggling && (symptoms.contains(.dizzy) || symptoms.contains(.anxious)) {
            return "companion_safety_stop".localized
        }
        if hours >= 14 && (mood == .tough || mood == .struggling) {
            return "companion_safety_14h".localized
        }
        return nil
    }
    
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
