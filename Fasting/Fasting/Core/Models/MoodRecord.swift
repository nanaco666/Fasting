//
//  MoodRecord.swift
//  Fasting
//
//  情绪记录模型
//

import SwiftUI
import SwiftData

// MARK: - Mood

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great      // 很好
    case good       // 不错
    case neutral    // 一般
    case tough      // 有点难
    case struggling // 很挣扎
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .tough: return "😣"
        case .struggling: return "😰"
        }
    }
    
    var label: String {
        switch self {
        case .great: return "mood_great"
        case .good: return "mood_good"
        case .neutral: return "mood_neutral"
        case .tough: return "mood_tough"
        case .struggling: return "mood_struggling"
        }
    }
    
    var localizedLabel: String { label.localized }
    
    /// Companion response based on mood + fasting duration
    func companionMessage(hours: Double) -> String {
        let key = "companion_\(rawValue)_\(hourBucket(hours))"
        return key.localized
    }
    
    private func hourBucket(_ hours: Double) -> String {
        if hours < 4 { return "early" }
        if hours < 12 { return "mid" }
        if hours < 18 { return "late" }
        return "extended"
    }
}

// MARK: - Mood Symptoms

enum MoodSymptom: String, Codable, CaseIterable, Identifiable {
    case headache       // 头痛
    case irritable      // 易怒
    case foggy          // 脑雾
    case hungry         // 饥饿
    case energetic      // 精力充沛
    case clearMinded    // 头脑清晰
    case dizzy          // 头晕
    case anxious        // 焦虑
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .headache: return "🤕"
        case .irritable: return "😤"
        case .foggy: return "🌫️"
        case .hungry: return "🍽️"
        case .energetic: return "⚡"
        case .clearMinded: return "🧠"
        case .dizzy: return "💫"
        case .anxious: return "😟"
        }
    }
    
    var localizedLabel: String { rawValue.localized }
    
    var isNegative: Bool {
        switch self {
        case .headache, .irritable, .foggy, .hungry, .dizzy, .anxious: return true
        case .energetic, .clearMinded: return false
        }
    }
    
    /// Science-based tip for this symptom
    var tip: String {
        "symptom_tip_\(rawValue)".localized
    }
}

// MARK: - Mood Record (SwiftData)

@Model
final class MoodRecord {
    var timestamp: Date
    var moodRaw: String
    var symptomsRaw: String  // comma-separated
    var fastingHours: Double
    var note: String?
    
    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
    
    var symptoms: [MoodSymptom] {
        get {
            symptomsRaw.split(separator: ",").compactMap { MoodSymptom(rawValue: String($0)) }
        }
        set {
            symptomsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }
    
    init(mood: Mood, symptoms: [MoodSymptom], fastingHours: Double, note: String? = nil) {
        self.timestamp = Date()
        self.moodRaw = mood.rawValue
        self.symptomsRaw = symptoms.map(\.rawValue).joined(separator: ",")
        self.fastingHours = fastingHours
        self.note = note
    }
}
