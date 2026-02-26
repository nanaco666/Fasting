//
//  FastingRecord.swift
//  Fasting
//
//  断食记录数据模型
//

import Foundation
import SwiftData

/// 断食方案预设
enum FastingPreset: String, Codable, CaseIterable, Identifiable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    /// 断食时长（小时）
    var fastingHours: Int {
        switch self {
        case .sixteen8: return 16
        case .eighteen6: return 18
        case .twenty4: return 20
        case .omad: return 23
        case .custom: return 16 // 默认值
        }
    }
    
    /// 进食窗口（小时）
    var eatingWindow: Int {
        24 - fastingHours
    }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .sixteen8: return "16:8"
        case .eighteen6: return "18:6"
        case .twenty4: return "20:4"
        case .omad: return "OMAD"
        case .custom: return "preset_custom_name".localized
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .sixteen8: return "preset_16_8_desc".localized
        case .eighteen6: return "preset_18_6_desc".localized
        case .twenty4: return "preset_20_4_desc".localized
        case .omad: return "preset_omad_desc".localized
        case .custom: return "preset_custom_desc".localized
        }
    }
}

/// 断食状态
enum FastingStatus: String, Codable {
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .inProgress: return L10n.Status.inProgress
        case .completed: return L10n.Status.completed
        case .cancelled: return L10n.Status.cancelled
        }
    }
}

/// 断食记录模型
@Model
final class FastingRecord {
    /// 唯一标识符
    var id: UUID
    
    /// 断食开始时间
    var startTime: Date
    
    /// 断食结束时间（进行中时为 nil）
    var endTime: Date?
    
    /// 目标断食时长（秒）
    var targetDuration: TimeInterval
    
    /// 实际断食时长（秒）
    var actualDuration: TimeInterval?
    
    /// 使用的断食方案
    var presetTypeRaw: String
    
    /// 断食状态
    var statusRaw: String
    
    /// 备注
    var notes: String?
    
    /// 创建时间
    var createdAt: Date
    
    /// 更新时间
    var updatedAt: Date
    
    // MARK: - Computed Properties
    
    var presetType: FastingPreset {
        get { FastingPreset(rawValue: presetTypeRaw) ?? .sixteen8 }
        set { presetTypeRaw = newValue.rawValue }
    }
    
    var status: FastingStatus {
        get { FastingStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }
    
    /// 目标断食时长（小时）
    var targetHours: Double {
        targetDuration / 3600
    }
    
    /// 实际断食时长（小时）
    var actualHours: Double? {
        guard let actual = actualDuration else { return nil }
        return actual / 3600
    }
    
    /// 是否达成目标
    var isGoalAchieved: Bool {
        guard let actual = actualDuration else { return false }
        return actual >= targetDuration
    }
    
    /// 当前已断食时长（用于进行中的记录）
    var currentDuration: TimeInterval {
        guard status == .inProgress else {
            return actualDuration ?? 0
        }
        return Date().timeIntervalSince(startTime)
    }
    
    /// 进度百分比 (0.0 - 1.0)
    var progress: Double {
        min(currentDuration / targetDuration, 1.0)
    }
    
    // MARK: - Initializer
    
    init(
        startTime: Date = Date(),
        targetDuration: TimeInterval,
        presetType: FastingPreset = .sixteen8
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.targetDuration = targetDuration
        self.actualDuration = nil
        self.presetTypeRaw = presetType.rawValue
        self.statusRaw = FastingStatus.inProgress.rawValue
        self.notes = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Methods
    
    /// 结束断食
    func complete() {
        let now = Date()
        self.endTime = now
        self.actualDuration = now.timeIntervalSince(startTime)
        self.status = .completed
        self.updatedAt = now
    }
    
    /// 取消断食
    func cancel() {
        let now = Date()
        self.endTime = now
        self.actualDuration = now.timeIntervalSince(startTime)
        self.status = .cancelled
        self.updatedAt = now
    }
}

// MARK: - Convenience Extensions

extension FastingRecord {
    /// 格式化的断食时长字符串
    var formattedDuration: String {
        let duration = status == .inProgress ? currentDuration : (actualDuration ?? 0)
        return Self.formatDuration(duration)
    }
    
    /// 格式化时长为可读字符串
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// 格式化为简短时长（小时分钟）
    static func formatShortDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
