//
//  MoodRecord.swift
//  Fasting
//
//  身心福祉记录 — 基于布辛格断食监测量表
//

import SwiftUI
import SwiftData

// MARK: - Well-being Score (0-10 NRS)

/// Buchinger-style 0-10 Numeric Rating Scale interpretation
enum WellbeingLevel: String {
    case excellent  // 9-10
    case good       // 7-8
    case moderate   // 5-6
    case poor       // 3-4
    case veryPoor   // 0-2
    
    init(score: Int) {
        switch score {
        case 9...10: self = .excellent
        case 7...8: self = .good
        case 5...6: self = .moderate
        case 3...4: self = .poor
        default: self = .veryPoor
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .fastingGreen
        case .good: return .fastingTeal
        case .moderate: return .secondary
        case .poor: return .fastingOrange
        case .veryPoor: return .red
        }
    }
    
    var localizedLabel: String {
        "wellbeing_\(rawValue)".localized
    }
}

// MARK: - Ketone Level (Ketostix color grades)

enum KetoneLevel: String, Codable, CaseIterable, Identifiable {
    case negative
    case trace
    case small
    case moderate
    case large
    case veryLarge
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .negative: return Color(red: 0.95, green: 0.9, blue: 0.75)
        case .trace: return Color(red: 0.9, green: 0.75, blue: 0.7)
        case .small: return Color(red: 0.8, green: 0.55, blue: 0.6)
        case .moderate: return Color(red: 0.65, green: 0.35, blue: 0.5)
        case .large: return Color(red: 0.5, green: 0.2, blue: 0.45)
        case .veryLarge: return Color(red: 0.35, green: 0.1, blue: 0.35)
        }
    }
    
    var mmolRange: String {
        switch self {
        case .negative: return "0"
        case .trace: return "0.5"
        case .small: return "1.5"
        case .moderate: return "4.0"
        case .large: return "8.0"
        case .veryLarge: return "16.0"
        }
    }
    
    var localizedLabel: String {
        "ketone_\(rawValue)".localized
    }
    
    var emoji: String {
        switch self {
        case .negative: return "⚪"
        case .trace: return "🟡"
        case .small: return "🟠"
        case .moderate: return "🟤"
        case .large: return "🟣"
        case .veryLarge: return "⚫"
        }
    }
}

// MARK: - Mood (backward compat, derived from PWB+EWB)

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great
    case good
    case neutral
    case tough
    case struggling
    
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
    
    static func from(pwb: Int, ewb: Int) -> Mood {
        let avg = Double(pwb + ewb) / 2.0
        switch avg {
        case 8...10: return .great
        case 6..<8: return .good
        case 4..<6: return .neutral
        case 2..<4: return .tough
        default: return .struggling
        }
    }
    
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
    case headache
    case dizzy
    case nausea
    case muscleAche
    case coldHands
    case foggy
    case irritable
    case anxious
    case restless
    case energetic
    case clearMinded
    case calm
    case lightBody
    
    // Keep old cases for backward compat with stored data
    case hungry
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .headache: return "🤕"
        case .dizzy: return "💫"
        case .nausea: return "🤢"
        case .muscleAche: return "💪"
        case .coldHands: return "🥶"
        case .foggy: return "🌫️"
        case .irritable: return "😤"
        case .anxious: return "😟"
        case .restless: return "🦶"
        case .energetic: return "⚡"
        case .clearMinded: return "🧠"
        case .calm: return "🧘"
        case .lightBody: return "🪶"
        case .hungry: return "🍽️"
        }
    }
    
    var localizedLabel: String { rawValue.localized }
    
    var isNegative: Bool {
        switch self {
        case .headache, .dizzy, .nausea, .muscleAche, .coldHands,
             .foggy, .irritable, .anxious, .restless, .hungry:
            return true
        case .energetic, .clearMinded, .calm, .lightBody:
            return false
        }
    }
    
    var isPhysical: Bool {
        switch self {
        case .headache, .dizzy, .nausea, .muscleAche, .coldHands,
             .energetic, .lightBody, .hungry:
            return true
        default:
            return false
        }
    }
    
    var tip: String {
        "symptom_tip_\(rawValue)".localized
    }
    
    /// Symptoms shown in the new check-in UI (excludes legacy .hungry)
    static var physicalSymptoms: [MoodSymptom] {
        [.headache, .dizzy, .nausea, .muscleAche, .coldHands, .energetic, .lightBody]
    }
    
    static var mentalSymptoms: [MoodSymptom] {
        [.foggy, .irritable, .anxious, .restless, .clearMinded, .calm]
    }
}

// MARK: - Mood Record (SwiftData)

@Model
final class MoodRecord {
    var timestamp: Date
    var moodRaw: String
    var symptomsRaw: String
    var fastingHours: Double
    var note: String?
    
    // Buchinger PWB/EWB scores (0-10)
    var physicalWellbeing: Int
    var emotionalWellbeing: Int
    
    // Hunger
    var isHungry: Bool
    
    // Ketone (optional)
    var ketoneLevelRaw: String?
    
    // MARK: - Computed
    
    var mood: Mood {
        get { Mood(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue }
    }
    
    var symptoms: [MoodSymptom] {
        get {
            guard !symptomsRaw.isEmpty else { return [] }
            return symptomsRaw.split(separator: ",").compactMap { MoodSymptom(rawValue: String($0)) }
        }
        set {
            symptomsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }
    
    var ketoneLevel: KetoneLevel? {
        get { ketoneLevelRaw.flatMap { KetoneLevel(rawValue: $0) } }
        set { ketoneLevelRaw = newValue?.rawValue }
    }
    
    var pwbLevel: WellbeingLevel { WellbeingLevel(score: physicalWellbeing) }
    var ewbLevel: WellbeingLevel { WellbeingLevel(score: emotionalWellbeing) }
    
    var averageWellbeing: Double {
        Double(physicalWellbeing + emotionalWellbeing) / 2.0
    }
    
    var needsAttention: Bool {
        physicalWellbeing <= 3 || emotionalWellbeing <= 3
    }
    
    // MARK: - Init
    
    init(
        pwb: Int,
        ewb: Int,
        isHungry: Bool,
        ketoneLevel: KetoneLevel? = nil,
        symptoms: [MoodSymptom],
        fastingHours: Double,
        note: String? = nil
    ) {
        self.timestamp = Date()
        self.physicalWellbeing = pwb
        self.emotionalWellbeing = ewb
        self.isHungry = isHungry
        self.ketoneLevelRaw = ketoneLevel?.rawValue
        self.moodRaw = Mood.from(pwb: pwb, ewb: ewb).rawValue
        self.symptomsRaw = symptoms.map(\.rawValue).joined(separator: ",")
        self.fastingHours = fastingHours
        self.note = note
    }
    
    // Legacy init
    init(mood: Mood, symptoms: [MoodSymptom], fastingHours: Double, note: String? = nil) {
        self.timestamp = Date()
        self.moodRaw = mood.rawValue
        self.symptomsRaw = symptoms.map(\.rawValue).joined(separator: ",")
        self.fastingHours = fastingHours
        self.note = note
        let score: Int
        switch mood {
        case .great: score = 9
        case .good: score = 7
        case .neutral: score = 5
        case .tough: score = 3
        case .struggling: score = 1
        }
        self.physicalWellbeing = score
        self.emotionalWellbeing = score
        self.isHungry = false
    }
}
