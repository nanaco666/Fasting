//
//  Strings.swift
//  Fasting
//
//  Localization support - Default English, with Chinese option
//

import Foundation

// MARK: - Localized Strings

enum L10n {
    // MARK: - Tab Bar
    enum Tab {
        static var timer: String { "Timer".localized }
        static var history: String { "History".localized }
        static var insights: String { "Insights".localized }
    }
    
    // MARK: - Timer View
    enum Timer {
        static var title: String { "Fasting".localized }
        static var startFasting: String { "Start Fast".localized }
        static var endFasting: String { "End Fast".localized }
        static var fasting: String { "Fasting".localized }
        static var notFasting: String { "Not Fasting".localized }
        static var goalReached: String { "Goal Reached".localized }
        static var remaining: String { "remaining".localized }
        static var elapsed: String { "elapsed".localized }
        static var confirmEnd: String { "End this fast?".localized }
        static var confirmEndMessage: String { "You've been fasting for".localized }
        static var cancel: String { "Cancel".localized }
        static var quickStats: String { "Quick Stats".localized }
        static var currentStreak: String { "Current Streak".localized }
        static var thisWeek: String { "This Week".localized }
        static var days: String { "days".localized }
    }
    
    // MARK: - Preset Selection
    enum Preset {
        static var title: String { "Choose a Plan".localized }
        static var hoursFasting: String { "hours fasting".localized }
        static var customDuration: String { "Fasting Duration".localized }
        static var hours: String { "hours".localized }
        static var popular: String { "Popular".localized }
        static var beginner: String { "Beginner".localized }
        static var advanced: String { "Advanced".localized }
        static var custom: String { "Custom".localized }
    }
    
    // MARK: - History View
    enum History {
        static var title: String { "History".localized }
        static var recentFasts: String { "Recent Fasts".localized }
        static var monthlyStats: String { "Monthly Stats".localized }
        static var completed: String { "Completed".localized }
        static var totalHours: String { "Total Hours".localized }
        static var streak: String { "Streak".localized }
        static var noRecords: String { "No Records Yet".localized }
        static var noRecordsDesc: String { "Start your first fast to see history".localized }
        static var times: String { "times".localized }
    }
    
    // MARK: - Insights/Statistics View
    enum Insights {
        static var title: String { "Insights".localized }
        static var currentStreak: String { "Current Streak".localized }
        static var keepItUp: String { "Keep it up!".localized }
        static var fastingTrend: String { "Fasting Trend".localized }
        static var noData: String { "No Data Yet".localized }
        static var noDataDesc: String { "Complete fasts to see trends".localized }
        static var details: String { "Details".localized }
        static var totalFasts: String { "Total Fasts".localized }
        static var totalTime: String { "Total Time".localized }
        static var avgDuration: String { "Avg Duration".localized }
        static var completionRate: String { "Success Rate".localized }
        static var longestFast: String { "Longest Fast".localized }
        static var longestStreak: String { "Best Streak".localized }
        static var week: String { "Week".localized }
        static var month: String { "Month".localized }
        static var year: String { "Year".localized }
    }
    
    // MARK: - Settings
    enum Settings {
        static var title: String { "Settings".localized }
        static var fastingSettings: String { "Fasting".localized }
        static var defaultPlan: String { "Default Plan".localized }
        static var notifications: String { "Notifications".localized }
        static var data: String { "Data".localized }
        static var healthSync: String { "Apple Health Sync".localized }
        static var iCloudSync: String { "iCloud Sync".localized }
        static var language: String { "Language".localized }
        static var about: String { "About".localized }
        static var version: String { "Version".localized }
    }
    
    // MARK: - General
    enum General {
        static var done: String { "Done".localized }
        static var edit: String { "Edit".localized }
        static var delete: String { "Delete".localized }
        static var save: String { "Save".localized }
    }
    
    // MARK: - Fasting Status
    enum Status {
        static var inProgress: String { "In Progress".localized }
        static var completed: String { "Completed".localized }
        static var cancelled: String { "Cancelled".localized }
    }
}

// MARK: - String Extension for Localization

extension String {
    var localized: String {
        let language = LanguageManager.shared.currentLanguage
        
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to base localization or key
            return NSLocalizedString(self, comment: "")
        }
        
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

// MARK: - Language Manager

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

@Observable
final class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "app_language"
    
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            // Post notification for UI refresh
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    private init() {
        // Load saved language or default to English
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: saved) {
            self.currentLanguage = language
        } else {
            // Check system language
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = systemLang.hasPrefix("zh") ? .chinese : .english
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - Localized Strings Dictionary (Inline fallback)

// Note: In production, use Localizable.strings files
// This provides inline fallback for development

private let localizedStrings: [String: [String: String]] = [
    // Tab Bar
    "Timer": ["en": "Timer", "zh-Hans": "断食"],
    "History": ["en": "History", "zh-Hans": "历史"],
    "Insights": ["en": "Insights", "zh-Hans": "统计"],
    
    // Timer
    "Fasting": ["en": "Fasting", "zh-Hans": "断食"],
    "Start Fast": ["en": "Start Fast", "zh-Hans": "开始断食"],
    "End Fast": ["en": "End Fast", "zh-Hans": "结束断食"],
    "Not Fasting": ["en": "Not Fasting", "zh-Hans": "未在断食"],
    "Goal Reached": ["en": "Goal Reached!", "zh-Hans": "目标达成！"],
    "remaining": ["en": "remaining", "zh-Hans": "剩余"],
    "elapsed": ["en": "elapsed", "zh-Hans": "已过"],
    "End this fast?": ["en": "End this fast?", "zh-Hans": "结束此次断食？"],
    "You've been fasting for": ["en": "You've been fasting for", "zh-Hans": "已断食"],
    "Cancel": ["en": "Cancel", "zh-Hans": "取消"],
    "Quick Stats": ["en": "Quick Stats", "zh-Hans": "快速统计"],
    "Current Streak": ["en": "Current Streak", "zh-Hans": "连续天数"],
    "This Week": ["en": "This Week", "zh-Hans": "本周完成"],
    "days": ["en": "days", "zh-Hans": "天"],
    
    // Presets
    "Choose a Plan": ["en": "Choose a Plan", "zh-Hans": "选择方案"],
    "hours fasting": ["en": "hours fasting", "zh-Hans": "小时断食"],
    "Fasting Duration": ["en": "Fasting Duration", "zh-Hans": "断食时长"],
    "hours": ["en": "hours", "zh-Hans": "小时"],
    "Popular": ["en": "Popular", "zh-Hans": "热门"],
    "Beginner": ["en": "Beginner", "zh-Hans": "入门"],
    "Advanced": ["en": "Advanced", "zh-Hans": "进阶"],
    "Custom": ["en": "Custom", "zh-Hans": "自定义"],
    
    // History
    "Recent Fasts": ["en": "Recent Fasts", "zh-Hans": "最近记录"],
    "Monthly Stats": ["en": "Monthly Stats", "zh-Hans": "本月统计"],
    "Completed": ["en": "Completed", "zh-Hans": "完成"],
    "Total Hours": ["en": "Total Hours", "zh-Hans": "总时长"],
    "Streak": ["en": "Streak", "zh-Hans": "连续"],
    "No Records Yet": ["en": "No Records Yet", "zh-Hans": "暂无记录"],
    "Start your first fast to see history": ["en": "Start your first fast to see history", "zh-Hans": "开始你的第一次断食吧"],
    "times": ["en": "times", "zh-Hans": "次"],
    
    // Insights
    "Keep it up!": ["en": "Keep it up!", "zh-Hans": "继续保持！"],
    "Fasting Trend": ["en": "Fasting Trend", "zh-Hans": "断食趋势"],
    "No Data Yet": ["en": "No Data Yet", "zh-Hans": "暂无数据"],
    "Complete fasts to see trends": ["en": "Complete fasts to see trends", "zh-Hans": "完成断食后查看趋势"],
    "Details": ["en": "Details", "zh-Hans": "详细统计"],
    "Total Fasts": ["en": "Total Fasts", "zh-Hans": "总次数"],
    "Total Time": ["en": "Total Time", "zh-Hans": "总时长"],
    "Avg Duration": ["en": "Avg Duration", "zh-Hans": "平均时长"],
    "Success Rate": ["en": "Success Rate", "zh-Hans": "完成率"],
    "Longest Fast": ["en": "Longest Fast", "zh-Hans": "最长断食"],
    "Best Streak": ["en": "Best Streak", "zh-Hans": "最长连续"],
    "Week": ["en": "Week", "zh-Hans": "本周"],
    "Month": ["en": "Month", "zh-Hans": "本月"],
    "Year": ["en": "Year", "zh-Hans": "今年"],
    
    // Settings
    "Settings": ["en": "Settings", "zh-Hans": "设置"],
    "Default Plan": ["en": "Default Plan", "zh-Hans": "默认方案"],
    "Notifications": ["en": "Notifications", "zh-Hans": "通知设置"],
    "Data": ["en": "Data", "zh-Hans": "数据"],
    "Apple Health Sync": ["en": "Apple Health Sync", "zh-Hans": "Apple 健康同步"],
    "iCloud Sync": ["en": "iCloud Sync", "zh-Hans": "iCloud 同步"],
    "Language": ["en": "Language", "zh-Hans": "语言"],
    "About": ["en": "About", "zh-Hans": "关于"],
    "Version": ["en": "Version", "zh-Hans": "版本"],
    
    // General
    "Done": ["en": "Done", "zh-Hans": "完成"],
    "Edit": ["en": "Edit", "zh-Hans": "编辑"],
    "Delete": ["en": "Delete", "zh-Hans": "删除"],
    "Save": ["en": "Save", "zh-Hans": "保存"],
    
    // Status
    "In Progress": ["en": "In Progress", "zh-Hans": "进行中"],
    "Cancelled": ["en": "Cancelled", "zh-Hans": "已取消"],
]
