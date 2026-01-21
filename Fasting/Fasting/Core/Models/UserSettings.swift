//
//  UserSettings.swift
//  Fasting
//
//  用户设置数据模型
//

import Foundation
import SwiftData

/// 用户设置模型
@Model
final class UserSettings {
    /// 默认断食方案
    var defaultPresetRaw: String
    
    /// 自定义断食时长（小时）- 当使用自定义方案时
    var customFastingHours: Int
    
    /// 是否启用通知
    var notificationsEnabled: Bool
    
    /// 断食开始提醒时间
    var startReminderTime: Date?
    
    /// 是否启用断食结束提醒
    var endReminderEnabled: Bool
    
    /// 是否启用进食窗口结束提醒
    var eatingWindowEndReminderEnabled: Bool
    
    /// 是否启用 HealthKit 同步
    var healthKitEnabled: Bool
    
    /// 是否启用 iCloud 同步
    var iCloudSyncEnabled: Bool
    
    /// 首次启动完成
    var onboardingCompleted: Bool
    
    // MARK: - Computed Properties
    
    var defaultPreset: FastingPreset {
        get { FastingPreset(rawValue: defaultPresetRaw) ?? .sixteen8 }
        set { defaultPresetRaw = newValue.rawValue }
    }
    
    /// 当前选择的断食时长（小时）
    var currentFastingHours: Int {
        if defaultPreset == .custom {
            return customFastingHours
        }
        return defaultPreset.fastingHours
    }
    
    /// 当前选择的断食时长（秒）
    var currentFastingDuration: TimeInterval {
        TimeInterval(currentFastingHours * 3600)
    }
    
    // MARK: - Initializer
    
    init() {
        self.defaultPresetRaw = FastingPreset.sixteen8.rawValue
        self.customFastingHours = 16
        self.notificationsEnabled = true
        self.startReminderTime = nil
        self.endReminderEnabled = true
        self.eatingWindowEndReminderEnabled = false
        self.healthKitEnabled = false
        self.iCloudSyncEnabled = true
        self.onboardingCompleted = false
    }
    
    // MARK: - Static
    
    /// 默认设置
    static var `default`: UserSettings {
        UserSettings()
    }
}
