//
//  CompanionEngine.swift
//  Fasting
//
//  全程陪伴引擎 — 情绪觉知 + 科学复食 + 温暖语调
//  基于断食阶段提供个性化陪伴消息
//

import Foundation

// MARK: - CompanionEngine (canonical name)

enum CompanionEngine {
    
    // MARK: - Phase Messages (断食中阶段性陪伴)
    
    struct PhaseMessage {
        let title: String
        let body: String
    }
    
    /// Returns phase-appropriate companion message based on fasting hours
    static func phaseMessage(hours: Double) -> PhaseMessage {
        let key = phaseMessageKey(hours: hours)
        return PhaseMessage(
            title: "\(key)_title".localized,
            body: "\(key)_body".localized
        )
    }
    
    /// Returns (emoji, message) tuple for simpler usage
    static func phaseEmoji(hours: Double) -> (String, String) {
        if hours < 2 { return ("🌱", "companion_phase_start_body".localized) }
        if hours < 6 { return ("🔥", "companion_phase_burning_body".localized) }
        if hours < 12 { return ("💪", "companion_phase_halfway_body".localized) }
        if hours < 16 { return ("🧘", "companion_phase_deep_body".localized) }
        if hours < 20 { return ("✨", "companion_phase_ketosis_body".localized) }
        if hours < 24 { return ("🌟", "companion_phase_autophagy_body".localized) }
        return ("🏆", "companion_phase_champion_body".localized)
    }
    
    private static func phaseMessageKey(hours: Double) -> String {
        if hours < 2 { return "companion_phase_start" }
        if hours < 4 { return "companion_phase_digesting" }
        if hours < 8 { return "companion_phase_postabsorptive" }
        if hours < 12 { return "companion_phase_burning" }
        if hours < 14 { return "companion_phase_transition" }
        if hours < 16 { return "companion_phase_ketosis_light" }
        if hours < 20 { return "companion_phase_deep_ketosis" }
        if hours < 24 { return "companion_phase_autophagy" }
        return "companion_phase_extended"
    }
    
    // MARK: - Mood Response (情绪回应)
    
    /// Generate personalized response based on mood + symptoms + fasting stage
    static func moodResponse(mood: Mood, hours: Double, symptoms: [MoodSymptom]) -> String {
        var parts: [String] = []
        
        // Base mood response
        parts.append(baseMoodResponse(mood: mood, hours: hours))
        
        // Symptom-specific advice
        let negativeSymptoms = symptoms.filter { $0.isNegative }
        if !negativeSymptoms.isEmpty {
            parts.append(symptomAdvice(symptoms: negativeSymptoms, hours: hours))
        }
        
        // Positive reinforcement for positive symptoms
        let positiveSymptoms = symptoms.filter { !$0.isNegative }
        if !positiveSymptoms.isEmpty {
            parts.append(positiveReinforcement(symptoms: positiveSymptoms))
        }
        
        // Safety check for dangerous symptoms at certain hours
        if let safety = safetyCheck(mood: mood, symptoms: symptoms, hours: hours) {
            parts.append(safety)
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    private static func baseMoodResponse(mood: Mood, hours: Double) -> String {
        let bucket = hourBucket(hours)
        let key = "companion_\(mood.rawValue)_\(bucket)"
        let result = key.localized
        // Fallback if key not found (returns key itself)
        if result == key {
            return "companion_\(mood.rawValue)_general".localized
        }
        return result
    }
    
    private static func symptomAdvice(symptoms: [MoodSymptom], hours: Double) -> String {
        // Pick the most actionable symptom
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
    
    /// Safety: 14h+ red line for emotionally sensitive users
    private static func safetyCheck(mood: Mood, symptoms: [MoodSymptom], hours: Double) -> String? {
        // STOP criteria: struggling + dizzy/anxious at any point
        if mood == .struggling && (symptoms.contains(.dizzy) || symptoms.contains(.anxious)) {
            return "companion_safety_stop".localized
        }
        // 14h+ with negative mood → gentle suggestion to consider ending
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
    
    // MARK: - Completion Message (断食结束)
    
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
    
    /// Variant for RefeedGuideView using duration (TimeInterval)
    static func completionMessage(duration: TimeInterval, wasGoalMet: Bool) -> (title: String, body: String) {
        completionMessage(hours: duration / 3600, isGoalAchieved: wasGoalMet)
    }
}

// MARK: - Alias for backward compatibility

/// Used by Timer/ views that reference CompanionMessages
typealias CompanionMessages = CompanionEngine
