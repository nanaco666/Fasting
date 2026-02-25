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
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let startHour: Double
    let endHour: Double  // Double.infinity for last phase
    let keyEvents: [PhaseEvent]
    let detailDescription: String
}

/// 阶段中的关键事件
struct PhaseEvent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

/// 阶段管理器
enum FastingPhaseManager {
    
    /// 所有断食阶段
    static let phases: [FastingPhase] = [
        // Phase 1: 0-12h
        FastingPhase(
            id: 0,
            name: "Glycogen Depletion".localized,
            subtitle: "糖原消耗期",
            icon: "flame",
            color: Color.fastingOrange,
            startHour: 0,
            endHour: 12,
            keyEvents: [
                PhaseEvent(
                    title: "Insulin Drops".localized,
                    description: "胰岛素水平开始下降，身体从\"储存模式\"切换到\"消耗模式\"",
                    icon: "arrow.down.circle"
                ),
                PhaseEvent(
                    title: "Liver Glycogen Burning".localized,
                    description: "肝脏开始消耗储存的糖原（约400-600kcal的储备）",
                    icon: "bolt.fill"
                ),
                PhaseEvent(
                    title: "Fat Mobilization Starts".localized,
                    description: "脂肪动员初步启动，脂肪细胞开始释放脂肪酸",
                    icon: "drop.triangle"
                )
            ],
            detailDescription: "身体正在消耗肝脏中储存的糖原。胰岛素水平下降，脂肪分解开始启动。这是最轻松的阶段——你可能不会感到明显的饥饿感。"
        ),
        
        // Phase 2: 12-24h
        FastingPhase(
            id: 1,
            name: "Ketosis Initiation".localized,
            subtitle: "酮症启动",
            icon: "bolt.fill",
            color: Color.fastingGreen,
            startHour: 12,
            endHour: 24,
            keyEvents: [
                PhaseEvent(
                    title: "Ketone Production".localized,
                    description: "肝糖原基本耗尽，身体开始将脂肪转化为酮体（β-羟基丁酸）作为替代燃料",
                    icon: "atom"
                ),
                PhaseEvent(
                    title: "Blood Sugar -20%".localized,
                    description: "血糖水平下降约20%，身体适应使用脂肪供能",
                    icon: "chart.line.downtrend.xyaxis"
                ),
                PhaseEvent(
                    title: "Autophagy Begins".localized,
                    description: "自噬作用被诱导——细胞开始清理内部受损的蛋白质和细胞器",
                    icon: "sparkles"
                ),
                PhaseEvent(
                    title: "Digestive Rest".localized,
                    description: "消化系统进入完全休息状态，肠道开始自我修复",
                    icon: "moon.zzz"
                )
            ],
            detailDescription: "这是代谢切换的关键窗口。肝糖原耗尽后，身体开始燃烧脂肪并产生酮体。自噬作用启动——你的细胞正在进行\"大扫除\"。你可能会感到轻微饥饿，但这是身体在适应新燃料。"
        ),
        
        // Phase 3: 24-48h
        FastingPhase(
            id: 2,
            name: "Metabolic Switch".localized,
            subtitle: "代谢全面切换",
            icon: "brain.head.profile",
            color: Color.fastingTeal,
            startHour: 24,
            endHour: 48,
            keyEvents: [
                PhaseEvent(
                    title: "Full Ketosis".localized,
                    description: "从葡萄糖代谢到酮体代谢的全面切换完成",
                    icon: "arrow.triangle.2.circlepath"
                ),
                PhaseEvent(
                    title: "BDNF Surge".localized,
                    description: "大脑分泌更多脑源性神经营养因子（BDNF），促进神经元保护和认知功能",
                    icon: "brain"
                ),
                PhaseEvent(
                    title: "Autophagy Accelerates".localized,
                    description: "自噬作用显著加速，开始更彻底地清理受损蛋白和细胞器",
                    icon: "wind"
                ),
                PhaseEvent(
                    title: "Mental Clarity".localized,
                    description: "酮体跨越血脑屏障，提供比葡萄糖更高效的能量——许多人报告思维更清晰",
                    icon: "lightbulb.fill"
                )
            ],
            detailDescription: "恭喜，你的身体已经完全切换到脂肪供能模式。大脑现在主要依靠酮体运行，BDNF水平升高正在保护你的神经元。自噬作用加速——细胞修复进入高速档。"
        ),
        
        // Phase 4: 48-72h
        FastingPhase(
            id: 3,
            name: "Peak Autophagy".localized,
            subtitle: "峰值自噬 · 免疫重启",
            icon: "sparkles",
            color: Color.fastingBlue,
            startHour: 48,
            endHour: 72,
            keyEvents: [
                PhaseEvent(
                    title: "Autophagy Peak".localized,
                    description: "自噬达到峰值——细胞再生能力处于最强状态",
                    icon: "star.fill"
                ),
                PhaseEvent(
                    title: "Immune Reset".localized,
                    description: "IGF-1大幅下降，诱导造血干细胞自我更新，免疫系统开始\"重启\"",
                    icon: "shield.checkered"
                ),
                PhaseEvent(
                    title: "Stable Brain Function".localized,
                    description: "尽管血糖处于低位，大脑依靠酮体维持稳定甚至更优的功能",
                    icon: "brain.filled.head.profile"
                )
            ],
            detailDescription: "这是断食的黄金阶段。自噬达到峰值，你的细胞正在进行最深层的修复和更新。免疫系统通过干细胞更新实现\"重启\"。⚠️ 超过48小时的断食属于专业医疗干预范畴，请在医生监督下进行。"
        ),
        
        // Phase 5: 72h+
        FastingPhase(
            id: 4,
            name: "Deep Remodeling".localized,
            subtitle: "深度重塑",
            icon: "leaf.fill",
            color: Color.fastingPurple,
            startHour: 72,
            endHour: .infinity,
            keyEvents: [
                PhaseEvent(
                    title: "New Homeostasis".localized,
                    description: "身体建立新的代谢稳态，能量供给达到平衡",
                    icon: "scale.3d"
                ),
                PhaseEvent(
                    title: "Gut Microbiome Shift".localized,
                    description: "肠道微生物多样性发生重大调整（~第9-10天），产生有益代谢物",
                    icon: "leaf.arrow.circlepath"
                ),
                PhaseEvent(
                    title: "⚠️ Muscle Risk",
                    description: "需警惕瘦体重流失——长期断食中约2/3减重可能来自肌肉",
                    icon: "exclamationmark.triangle"
                )
            ],
            detailDescription: "身体进入深度代谢重塑阶段。新的稳态正在建立，但也需要警惕肌肉流失风险。⚠️ 此阶段必须在专业医疗监督下进行，尤其是糖尿病、低BMI或有进食障碍史的人群。"
        )
    ]
    
    /// 根据断食时长获取当前阶段
    static func currentPhase(for duration: TimeInterval) -> FastingPhase {
        let hours = duration / 3600
        return phases.last(where: { hours >= $0.startHour }) ?? phases[0]
    }
    
    /// 获取当前阶段的进度 (0.0 - 1.0)
    static func phaseProgress(for duration: TimeInterval) -> Double {
        let hours = duration / 3600
        let phase = currentPhase(for: duration)
        
        guard phase.endHour != .infinity else {
            // 最后一个阶段，以168小时(7天)为满
            let phaseHours = hours - phase.startHour
            return min(phaseHours / (168 - phase.startHour), 1.0)
        }
        
        let phaseLength = phase.endHour - phase.startHour
        let elapsed = hours - phase.startHour
        return min(max(elapsed / phaseLength, 0), 1.0)
    }
    
    /// 获取所有已解锁的阶段
    static func unlockedPhases(for duration: TimeInterval) -> [FastingPhase] {
        let hours = duration / 3600
        return phases.filter { hours >= $0.startHour }
    }
    
    /// 下一个阶段（如果有）
    static func nextPhase(for duration: TimeInterval) -> FastingPhase? {
        let hours = duration / 3600
        return phases.first(where: { hours < $0.startHour })
    }
    
    /// 距离下一阶段的剩余时间
    static func timeToNextPhase(for duration: TimeInterval) -> TimeInterval? {
        guard let next = nextPhase(for: duration) else { return nil }
        let remaining = (next.startHour * 3600) - duration
        return max(remaining, 0)
    }
}
