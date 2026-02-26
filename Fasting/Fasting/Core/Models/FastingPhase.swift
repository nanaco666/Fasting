//
//  FastingPhase.swift
//  Fasting
//
//  统一断食阶段模型 — 科学精准 + 人格化陪伴
//  合并原 FastingPhase (5 phases) + CompanionEngine phase messages (9 phases)
//  更细粒度：11个子阶段，每个有科学描述 + 陪伴语
//

import SwiftUI

// MARK: - Phase Model

struct FastingPhase: Identifiable {
    let id: Int
    let nameKey: String          // 阶段名称
    let icon: String             // SF Symbol
    let color: Color             // 主题色
    let startHour: Double        // 起始小时
    let endHour: Double          // 结束小时
    let keyEvents: [PhaseEvent]  // 关键生理事件
    let scienceKey: String       // 科学详解 (展开时)
    let companionKey: String     // 陪伴语 (卡片上直接展示)
    let emoji: String            // 状态 emoji
    
    var name: String { nameKey.localized }
    var scienceDetail: String { scienceKey.localized }
    var companionMessage: String { companionKey.localized }
}

struct PhaseEvent: Identifiable {
    let id = UUID()
    let titleKey: String
    let descKey: String
    let icon: String
    
    var title: String { titleKey.localized }
    var description: String { descKey.localized }
}

// MARK: - Phase Manager

enum FastingPhaseManager {
    
    static let phases: [FastingPhase] = [
        // ── 0-2h: 餐后期 ──
        FastingPhase(
            id: 0,
            nameKey: "phase_postmeal_name",
            icon: "fork.knife",
            color: .fastingOrange,
            startHour: 0, endHour: 2,
            keyEvents: [
                PhaseEvent(titleKey: "phase_postmeal_ev1_title", descKey: "phase_postmeal_ev1_desc", icon: "arrow.up.circle"),
            ],
            scienceKey: "phase_postmeal_science",
            companionKey: "phase_postmeal_companion",
            emoji: "🌱"
        ),
        // ── 2-6h: 消化吸收期 ──
        FastingPhase(
            id: 1,
            nameKey: "phase_absorbing_name",
            icon: "stomach",
            color: .fastingOrange,
            startHour: 2, endHour: 6,
            keyEvents: [
                PhaseEvent(titleKey: "phase_absorbing_ev1_title", descKey: "phase_absorbing_ev1_desc", icon: "arrow.down.circle"),
                PhaseEvent(titleKey: "phase_absorbing_ev2_title", descKey: "phase_absorbing_ev2_desc", icon: "bolt.fill"),
            ],
            scienceKey: "phase_absorbing_science",
            companionKey: "phase_absorbing_companion",
            emoji: "🔄"
        ),
        // ── 6-10h: 糖原消耗期 ──
        FastingPhase(
            id: 2,
            nameKey: "phase_glycogen_name",
            icon: "flame",
            color: .fastingOrange,
            startHour: 6, endHour: 10,
            keyEvents: [
                PhaseEvent(titleKey: "phase_glycogen_ev1_title", descKey: "phase_glycogen_ev1_desc", icon: "bolt.fill"),
                PhaseEvent(titleKey: "phase_glycogen_ev3_title", descKey: "phase_glycogen_ev3_desc", icon: "drop.triangle"),
            ],
            scienceKey: "phase_glycogen_science",
            companionKey: "phase_glycogen_companion",
            emoji: "🔥"
        ),
        // ── 10-14h: 代谢切换期 ──
        FastingPhase(
            id: 3,
            nameKey: "phase_transition_name",
            icon: "arrow.triangle.2.circlepath",
            color: .fastingGreen,
            startHour: 10, endHour: 14,
            keyEvents: [
                PhaseEvent(titleKey: "phase_transition_ev1_title", descKey: "phase_transition_ev1_desc", icon: "arrow.triangle.2.circlepath"),
                PhaseEvent(titleKey: "phase_transition_ev2_title", descKey: "phase_transition_ev2_desc", icon: "chart.line.downtrend.xyaxis"),
            ],
            scienceKey: "phase_transition_science",
            companionKey: "phase_transition_companion",
            emoji: "💪"
        ),
        // ── 14-16h: 轻度酮症 ──
        FastingPhase(
            id: 4,
            nameKey: "phase_light_ketosis_name",
            icon: "bolt.fill",
            color: .fastingGreen,
            startHour: 14, endHour: 16,
            keyEvents: [
                PhaseEvent(titleKey: "phase_ketosis_ev1_title", descKey: "phase_ketosis_ev1_desc", icon: "atom"),
                PhaseEvent(titleKey: "phase_ketosis_ev3_title", descKey: "phase_ketosis_ev3_desc", icon: "sparkles"),
            ],
            scienceKey: "phase_light_ketosis_science",
            companionKey: "phase_light_ketosis_companion",
            emoji: "⚡"
        ),
        // ── 16-20h: 深度酮症 ──
        FastingPhase(
            id: 5,
            nameKey: "phase_deep_ketosis_name",
            icon: "brain.head.profile",
            color: .fastingGreen,
            startHour: 16, endHour: 20,
            keyEvents: [
                PhaseEvent(titleKey: "phase_switch_ev1_title", descKey: "phase_switch_ev1_desc", icon: "arrow.triangle.2.circlepath"),
                PhaseEvent(titleKey: "phase_switch_ev2_title", descKey: "phase_switch_ev2_desc", icon: "brain"),
                PhaseEvent(titleKey: "phase_switch_ev4_title", descKey: "phase_switch_ev4_desc", icon: "lightbulb.fill"),
            ],
            scienceKey: "phase_deep_ketosis_science",
            companionKey: "phase_deep_ketosis_companion",
            emoji: "🧠"
        ),
        // ── 20-24h: 自噬启动 ──
        FastingPhase(
            id: 6,
            nameKey: "phase_autophagy_start_name",
            icon: "sparkles",
            color: .fastingTeal,
            startHour: 20, endHour: 24,
            keyEvents: [
                PhaseEvent(titleKey: "phase_switch_ev3_title", descKey: "phase_switch_ev3_desc", icon: "wind"),
                PhaseEvent(titleKey: "phase_ketosis_ev4_title", descKey: "phase_ketosis_ev4_desc", icon: "moon.zzz"),
            ],
            scienceKey: "phase_autophagy_start_science",
            companionKey: "phase_autophagy_start_companion",
            emoji: "✨"
        ),
        // ── 24-36h: 自噬加速 ──
        FastingPhase(
            id: 7,
            nameKey: "phase_autophagy_accel_name",
            icon: "wind",
            color: .fastingTeal,
            startHour: 24, endHour: 36,
            keyEvents: [
                PhaseEvent(titleKey: "phase_autophagy_ev1_title", descKey: "phase_autophagy_ev1_desc", icon: "star.fill"),
            ],
            scienceKey: "phase_autophagy_accel_science",
            companionKey: "phase_autophagy_accel_companion",
            emoji: "🌟"
        ),
        // ── 36-48h: 峰值自噬 ──
        FastingPhase(
            id: 8,
            nameKey: "phase_autophagy_name",
            icon: "star.fill",
            color: .fastingTeal,
            startHour: 36, endHour: 48,
            keyEvents: [
                PhaseEvent(titleKey: "phase_autophagy_ev1_title", descKey: "phase_autophagy_ev1_desc", icon: "star.fill"),
                PhaseEvent(titleKey: "phase_autophagy_ev2_title", descKey: "phase_autophagy_ev2_desc", icon: "shield.checkered"),
            ],
            scienceKey: "phase_autophagy_peak_science",
            companionKey: "phase_autophagy_peak_companion",
            emoji: "⭐"
        ),
        // ── 48-72h: 免疫重启 ──
        FastingPhase(
            id: 9,
            nameKey: "phase_immune_name",
            icon: "shield.checkered",
            color: .fastingTeal,
            startHour: 48, endHour: 72,
            keyEvents: [
                PhaseEvent(titleKey: "phase_autophagy_ev2_title", descKey: "phase_autophagy_ev2_desc", icon: "shield.checkered"),
                PhaseEvent(titleKey: "phase_autophagy_ev3_title", descKey: "phase_autophagy_ev3_desc", icon: "brain.filled.head.profile"),
            ],
            scienceKey: "phase_immune_science",
            companionKey: "phase_immune_companion",
            emoji: "🛡️"
        ),
        // ── 72h+: 深度重塑 ──
        FastingPhase(
            id: 10,
            nameKey: "phase_remodel_name",
            icon: "leaf.fill",
            color: .fastingTeal,
            startHour: 72, endHour: .infinity,
            keyEvents: [
                PhaseEvent(titleKey: "phase_remodel_ev1_title", descKey: "phase_remodel_ev1_desc", icon: "scale.3d"),
                PhaseEvent(titleKey: "phase_remodel_ev2_title", descKey: "phase_remodel_ev2_desc", icon: "leaf.arrow.circlepath"),
                PhaseEvent(titleKey: "phase_remodel_ev3_title", descKey: "phase_remodel_ev3_desc", icon: "exclamationmark.triangle"),
            ],
            scienceKey: "phase_remodel_detail",
            companionKey: "phase_remodel_companion",
            emoji: "🏆"
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
