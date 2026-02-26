//
//  FastingPhase.swift
//  Fasting
//
//  断食生理阶段模型
//

import SwiftUI

/// 断食生理阶段
struct FastingPhase: Identifiable {
    let id: Int
    let nameKey: String
    let subtitleKey: String
    let icon: String
    let color: Color
    let startHour: Double
    let endHour: Double
    let keyEvents: [PhaseEvent]
    let detailKey: String
    
    var name: String { nameKey.localized }
    var subtitle: String { subtitleKey.localized }
    var detailDescription: String { detailKey.localized }
}

/// 阶段中的关键事件
struct PhaseEvent: Identifiable {
    let id = UUID()
    let titleKey: String
    let descKey: String
    let icon: String
    
    var title: String { titleKey.localized }
    var description: String { descKey.localized }
}

/// 阶段管理器
enum FastingPhaseManager {
    
    static let phases: [FastingPhase] = [
        // Phase 1: 0-12h
        FastingPhase(
            id: 0,
            nameKey: "phase_glycogen_name",
            subtitleKey: "phase_glycogen_subtitle",
            icon: "flame",
            color: Color.fastingOrange,
            startHour: 0, endHour: 12,
            keyEvents: [
                PhaseEvent(titleKey: "phase_glycogen_ev1_title", descKey: "phase_glycogen_ev1_desc", icon: "arrow.down.circle"),
                PhaseEvent(titleKey: "phase_glycogen_ev2_title", descKey: "phase_glycogen_ev2_desc", icon: "bolt.fill"),
                PhaseEvent(titleKey: "phase_glycogen_ev3_title", descKey: "phase_glycogen_ev3_desc", icon: "drop.triangle"),
            ],
            detailKey: "phase_glycogen_detail"
        ),
        // Phase 2: 12-24h
        FastingPhase(
            id: 1,
            nameKey: "phase_ketosis_name",
            subtitleKey: "phase_ketosis_subtitle",
            icon: "bolt.fill",
            color: Color.fastingGreen,
            startHour: 12, endHour: 24,
            keyEvents: [
                PhaseEvent(titleKey: "phase_ketosis_ev1_title", descKey: "phase_ketosis_ev1_desc", icon: "atom"),
                PhaseEvent(titleKey: "phase_ketosis_ev2_title", descKey: "phase_ketosis_ev2_desc", icon: "chart.line.downtrend.xyaxis"),
                PhaseEvent(titleKey: "phase_ketosis_ev3_title", descKey: "phase_ketosis_ev3_desc", icon: "sparkles"),
                PhaseEvent(titleKey: "phase_ketosis_ev4_title", descKey: "phase_ketosis_ev4_desc", icon: "moon.zzz"),
            ],
            detailKey: "phase_ketosis_detail"
        ),
        // Phase 3: 24-48h
        FastingPhase(
            id: 2,
            nameKey: "phase_switch_name",
            subtitleKey: "phase_switch_subtitle",
            icon: "brain.head.profile",
            color: Color.fastingTeal,
            startHour: 24, endHour: 48,
            keyEvents: [
                PhaseEvent(titleKey: "phase_switch_ev1_title", descKey: "phase_switch_ev1_desc", icon: "arrow.triangle.2.circlepath"),
                PhaseEvent(titleKey: "phase_switch_ev2_title", descKey: "phase_switch_ev2_desc", icon: "brain"),
                PhaseEvent(titleKey: "phase_switch_ev3_title", descKey: "phase_switch_ev3_desc", icon: "wind"),
                PhaseEvent(titleKey: "phase_switch_ev4_title", descKey: "phase_switch_ev4_desc", icon: "lightbulb.fill"),
            ],
            detailKey: "phase_switch_detail"
        ),
        // Phase 4: 48-72h
        FastingPhase(
            id: 3,
            nameKey: "phase_autophagy_name",
            subtitleKey: "phase_autophagy_subtitle",
            icon: "sparkles",
            color: Color.fastingTeal,
            startHour: 48, endHour: 72,
            keyEvents: [
                PhaseEvent(titleKey: "phase_autophagy_ev1_title", descKey: "phase_autophagy_ev1_desc", icon: "star.fill"),
                PhaseEvent(titleKey: "phase_autophagy_ev2_title", descKey: "phase_autophagy_ev2_desc", icon: "shield.checkered"),
                PhaseEvent(titleKey: "phase_autophagy_ev3_title", descKey: "phase_autophagy_ev3_desc", icon: "brain.filled.head.profile"),
            ],
            detailKey: "phase_autophagy_detail"
        ),
        // Phase 5: 72h+
        FastingPhase(
            id: 4,
            nameKey: "phase_remodel_name",
            subtitleKey: "phase_remodel_subtitle",
            icon: "leaf.fill",
            color: Color.fastingTeal,
            startHour: 72, endHour: .infinity,
            keyEvents: [
                PhaseEvent(titleKey: "phase_remodel_ev1_title", descKey: "phase_remodel_ev1_desc", icon: "scale.3d"),
                PhaseEvent(titleKey: "phase_remodel_ev2_title", descKey: "phase_remodel_ev2_desc", icon: "leaf.arrow.circlepath"),
                PhaseEvent(titleKey: "phase_remodel_ev3_title", descKey: "phase_remodel_ev3_desc", icon: "exclamationmark.triangle"),
            ],
            detailKey: "phase_remodel_detail"
        ),
    ]
    
    static func currentPhase(for duration: TimeInterval) -> FastingPhase {
        let hours = duration / 3600
        return phases.last(where: { hours >= $0.startHour }) ?? phases[0]
    }
    
    static func phaseProgress(for duration: TimeInterval) -> Double {
        let hours = duration / 3600
        let phase = currentPhase(for: duration)
        guard phase.endHour != .infinity else {
            let phaseHours = hours - phase.startHour
            return min(phaseHours / (168 - phase.startHour), 1.0)
        }
        let phaseLength = phase.endHour - phase.startHour
        let elapsed = hours - phase.startHour
        return min(max(elapsed / phaseLength, 0), 1.0)
    }
    
    static func unlockedPhases(for duration: TimeInterval) -> [FastingPhase] {
        let hours = duration / 3600
        return phases.filter { hours >= $0.startHour }
    }
    
    static func nextPhase(for duration: TimeInterval) -> FastingPhase? {
        let hours = duration / 3600
        return phases.first(where: { hours < $0.startHour })
    }
    
    static func timeToNextPhase(for duration: TimeInterval) -> TimeInterval? {
        guard let next = nextPhase(for: duration) else { return nil }
        return max((next.startHour * 3600) - duration, 0)
    }
}
