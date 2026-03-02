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
        static var plan: String { "Plan".localized }
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
        static var started: String { "STARTED".localized }
        static var start: String { "START".localized }
        static var goal: String { "GOAL".localized }
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
        
        // 1. Check inline dictionary first
        if let translations = LocalizedStrings.all[self],
           let translated = translations[language.rawValue] {
            return translated
        }
        
        // 2. Fallback to bundle
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let result = NSLocalizedString(self, bundle: bundle, comment: "")
            if result != self { return result }
        }
        
        // 3. Return key as-is
        return self
    }
    
    /// Localized with format arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: self.localized, arguments: args)
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

enum LocalizedStrings {
static let all: [String: [String: String]] = [
    // Tab Bar
    "Timer": ["en": "Fasting", "zh-Hans": "空盘"],
    "History": ["en": "History", "zh-Hans": "历史"],
    "Insights": ["en": "Insights", "zh-Hans": "统计"],
    
    // Timer
    "Fasting": ["en": "Fasting", "zh-Hans": "断食"],
    "Start Fast": ["en": "Start Fast", "zh-Hans": "开始断食"],
    "End Fast": ["en": "End Fast", "zh-Hans": "结束断食"],
    "STARTED": ["en": "STARTED", "zh-Hans": "已开始"],
    "START": ["en": "START", "zh-Hans": "开始"],
    "GOAL": ["en": "GOAL", "zh-Hans": "目标"],
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
    
    // Preset names & descriptions
    "preset_custom_name": ["en": "Custom", "zh-Hans": "自定义"],
    "preset_16_8_desc": ["en": "16h fasting, 8h eating window", "zh-Hans": "断食16小时，8小时进食窗口"],
    "preset_18_6_desc": ["en": "18h fasting, 6h eating window", "zh-Hans": "断食18小时，6小时进食窗口"],
    "preset_20_4_desc": ["en": "20h fasting, 4h eating window", "zh-Hans": "断食20小时，4小时进食窗口"],
    "preset_omad_desc": ["en": "23h fasting, one meal a day", "zh-Hans": "断食23小时，每天只吃一餐"],
    "preset_custom_desc": ["en": "Custom fasting duration", "zh-Hans": "自定义断食时长"],
    
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
    
    // Plan & Onboarding
    "Plan": ["en": "Plan", "zh-Hans": "计划"],
    "Your Plan": ["en": "Your Plan", "zh-Hans": "你的计划"],
    "No Plan Yet": ["en": "No Plan Yet", "zh-Hans": "还没有计划"],
    "Create Plan": ["en": "Create Plan", "zh-Hans": "创建计划"],
    "Create a personalized fasting plan\nbased on your body and goals.": ["en": "Create a personalized fasting plan\nbased on your body and goals.", "zh-Hans": "根据你的身体状况和目标\n创建个性化断食计划"],
    "Edit Profile": ["en": "Edit Profile", "zh-Hans": "编辑资料"],
    "Reset Plan": ["en": "Reset Plan", "zh-Hans": "重置计划"],
    
    // Onboarding Steps
    "Tell us about yourself": ["en": "Tell us about yourself", "zh-Hans": "关于你"],
    "We'll use this to calculate your nutritional needs.": ["en": "We'll use this to calculate your nutritional needs.", "zh-Hans": "我们将据此计算你的营养需求"],
    "Your Lifestyle": ["en": "Your Lifestyle", "zh-Hans": "你的生活方式"],
    "Activity level affects calorie needs and protein targets.": ["en": "Activity level affects calorie needs and protein targets.", "zh-Hans": "活动量影响热量需求和蛋白质目标"],
    "Your Goal": ["en": "Your Goal", "zh-Hans": "你的目标"],
    "This determines fasting intensity and plan duration.": ["en": "This determines fasting intensity and plan duration.", "zh-Hans": "这决定了断食强度和计划周期"],
    "Based on your profile, here's what we recommend:": ["en": "Based on your profile, here's what we recommend:", "zh-Hans": "根据你的资料，我们推荐："],
    
    // Body Info
    "Basics": ["en": "Basics", "zh-Hans": "基本信息"],
    "Body": ["en": "Body", "zh-Hans": "身体"],
    "Sex": ["en": "Sex", "zh-Hans": "性别"],
    "Age": ["en": "Age", "zh-Hans": "年龄"],
    "Height": ["en": "Height", "zh-Hans": "身高"],
    "Weight": ["en": "Weight", "zh-Hans": "体重"],
    "Male": ["en": "Male", "zh-Hans": "男"],
    "Female": ["en": "Female", "zh-Hans": "女"],
    
    // Activity
    "Activity Level": ["en": "Activity Level", "zh-Hans": "活动量"],
    "Sedentary": ["en": "Sedentary", "zh-Hans": "久坐"],
    "Active": ["en": "Active", "zh-Hans": "活跃"],
    "High Intensity": ["en": "High Intensity", "zh-Hans": "高强度训练"],
    "Mostly sitting, minimal exercise": ["en": "Mostly sitting, minimal exercise", "zh-Hans": "基本不运动，以坐为主"],
    "Regular moderate activity": ["en": "Regular moderate activity", "zh-Hans": "定期中等强度运动"],
    "Resistance training or intense cardio": ["en": "Resistance training or intense cardio", "zh-Hans": "力量训练或高强度有氧"],
    "Diet": ["en": "Diet", "zh-Hans": "饮食"],
    "Preference": ["en": "Preference", "zh-Hans": "偏好"],
    "Omnivore": ["en": "Omnivore", "zh-Hans": "杂食"],
    "Vegetarian": ["en": "Vegetarian", "zh-Hans": "素食"],
    "Vegan": ["en": "Vegan", "zh-Hans": "纯素"],
    
    // Goals
    "Fat Loss": ["en": "Fat Loss", "zh-Hans": "减脂"],
    "Maintain Weight": ["en": "Maintain Weight", "zh-Hans": "维持体重"],
    "Metabolic Reset": ["en": "Metabolic Reset", "zh-Hans": "代谢重置"],
    "Reduce body fat while preserving muscle": ["en": "Reduce body fat while preserving muscle", "zh-Hans": "减少体脂，保留肌肉"],
    "Maintain current weight, improve health": ["en": "Maintain current weight, improve health", "zh-Hans": "维持当前体重，改善健康"],
    "Reset insulin sensitivity and metabolism": ["en": "Reset insulin sensitivity and metabolism", "zh-Hans": "重置胰岛素敏感性和代谢"],
    
    // Plan View
    "Daily Nutrition": ["en": "Daily Nutrition", "zh-Hans": "每日营养"],
    "Calories": ["en": "Calories", "zh-Hans": "热量"],
    "Protein": ["en": "Protein", "zh-Hans": "蛋白质"],
    "Milestones": ["en": "Milestones", "zh-Hans": "里程碑"],
    "Fasting Plan": ["en": "Fasting Plan", "zh-Hans": "断食方案"],
    "Daily calories": ["en": "Daily calories", "zh-Hans": "每日热量"],
    "Expected loss": ["en": "Expected loss", "zh-Hans": "预期减重"],
    "Nutrition": ["en": "Nutrition", "zh-Hans": "营养"],
    "Deficit": ["en": "Deficit", "zh-Hans": "热量缺口"],
    "Profile": ["en": "Profile", "zh-Hans": "个人资料"],
    "Carb:Fiber ratio": ["en": "Carb:Fiber ratio", "zh-Hans": "碳水:纤维比"],
    "per week": ["en": "per week", "zh-Hans": "每周"],
    "weeks left": ["en": "weeks left", "zh-Hans": "周剩余"],
    "Back": ["en": "Back", "zh-Hans": "返回"],
    "Next": ["en": "Next", "zh-Hans": "下一步"],
    
    // Milestones
    "Adaptation": ["en": "Adaptation", "zh-Hans": "适应期"],
    "Metabolic Shift": ["en": "Metabolic Shift", "zh-Hans": "代谢转换"],
    "First Results": ["en": "First Results", "zh-Hans": "初见成效"],
    "Clinically Significant": ["en": "Clinically Significant", "zh-Hans": "临床显著"],
    "Consolidation": ["en": "Consolidation", "zh-Hans": "巩固期"],
    "Plan Complete": ["en": "Plan Complete", "zh-Hans": "计划完成"],
    
    // Body Journey
    "Body Journey": ["en": "Body Journey", "zh-Hans": "身体旅程"],
    "Start fasting to begin your body's journey": ["en": "Start fasting to begin your body's journey", "zh-Hans": "开始断食，开启身体旅程"],
    "NOW": ["en": "NOW", "zh-Hans": "当前"],
    
    // Statistics / Insights extra
    "Streaks": ["en": "Streaks", "zh-Hans": "连续记录"],
    "Stats": ["en": "Stats", "zh-Hans": "统计"],
    "Fasts": ["en": "Fasts", "zh-Hans": "次"],
    "This Year": ["en": "This Year", "zh-Hans": "今年"],
    "Day Streak": ["en": "Day Streak", "zh-Hans": "天连续"],
    "No Current Streak": ["en": "No Current Streak", "zh-Hans": "暂无连续记录"],
    "Fast at least once a day\nto build a streak.": ["en": "Fast at least once a day\nto build a streak.", "zh-Hans": "每天至少断食一次\n来建立连续记录"],
    "Longest": ["en": "Longest", "zh-Hans": "最长"],
    "Daily": ["en": "Daily", "zh-Hans": "每日"],
    "Best": ["en": "Best", "zh-Hans": "最佳"],
    "Weekly": ["en": "Weekly", "zh-Hans": "每周"],
    "Record": ["en": "Record", "zh-Hans": "记录"],
    "Days": ["en": "Days", "zh-Hans": "天"],
    "Success": ["en": "Success", "zh-Hans": "成功"],
    "Rate": ["en": "Rate", "zh-Hans": "率"],
    "Average": ["en": "Average", "zh-Hans": "平均"],
    "Duration": ["en": "Duration", "zh-Hans": "时长"],
    "total": ["en": "total", "zh-Hans": "总计"],
    "Last 7 days": ["en": "Last 7 days", "zh-Hans": "最近7天"],
    "Last 4 weeks": ["en": "Last 4 weeks", "zh-Hans": "最近4周"],
    "Last 12 months": ["en": "Last 12 months", "zh-Hans": "最近12个月"],
    "BMI": ["en": "BMI", "zh-Hans": "BMI"],
    "TDEE": ["en": "TDEE", "zh-Hans": "TDEE"],
    "BMR": ["en": "BMR", "zh-Hans": "BMR"],
    
    // History extra
    "Fast Details": ["en": "Fast Details", "zh-Hans": "断食详情"],
    "Time": ["en": "Time", "zh-Hans": "时间"],
    "Started": ["en": "Started", "zh-Hans": "开始"],
    "Ended": ["en": "Ended", "zh-Hans": "结束"],
    "Target": ["en": "Target", "zh-Hans": "目标"],
    "Actual": ["en": "Actual", "zh-Hans": "实际"],
    
    // Warnings
    "Supplement B12, vitamin D, calcium, iron, zinc, omega-3": ["en": "Supplement B12, vitamin D, calcium, iron, zinc, omega-3", "zh-Hans": "需补充 B12、维生素D、钙、铁、锌、Omega-3"],
    
    // Fasting Phases
    "Glycogen Depletion": ["en": "Glycogen Depletion", "zh-Hans": "糖原消耗"],
    "Ketosis Initiation": ["en": "Ketosis Initiation", "zh-Hans": "酮症启动"],
    "Metabolic Switch": ["en": "Metabolic Switch", "zh-Hans": "代谢切换"],
    "Peak Autophagy": ["en": "Peak Autophagy", "zh-Hans": "峰值自噬"],
    "Deep Remodeling": ["en": "Deep Remodeling", "zh-Hans": "深度重塑"],
    "Insulin Drops": ["en": "Insulin Drops", "zh-Hans": "胰岛素下降"],
    "Liver Glycogen Burning": ["en": "Liver Glycogen Burning", "zh-Hans": "肝糖原消耗"],
    "Fat Mobilization Starts": ["en": "Fat Mobilization Starts", "zh-Hans": "脂肪动员启动"],
    "Ketone Production": ["en": "Ketone Production", "zh-Hans": "酮体生成"],
    "Blood Sugar -20%": ["en": "Blood Sugar -20%", "zh-Hans": "血糖下降20%"],
    "Autophagy Begins": ["en": "Autophagy Begins", "zh-Hans": "自噬启动"],
    "Digestive Rest": ["en": "Digestive Rest", "zh-Hans": "消化系统休息"],
    "Full Ketosis": ["en": "Full Ketosis", "zh-Hans": "完全酮症"],
    "BDNF Surge": ["en": "BDNF Surge", "zh-Hans": "BDNF激增"],
    "Autophagy Accelerates": ["en": "Autophagy Accelerates", "zh-Hans": "自噬加速"],
    "Mental Clarity": ["en": "Mental Clarity", "zh-Hans": "思维清晰"],
    "Autophagy Peak": ["en": "Autophagy Peak", "zh-Hans": "自噬峰值"],
    "Immune Reset": ["en": "Immune Reset", "zh-Hans": "免疫重启"],
    "Stable Brain Function": ["en": "Stable Brain Function", "zh-Hans": "大脑功能稳定"],
    "New Homeostasis": ["en": "New Homeostasis", "zh-Hans": "新稳态建立"],
    "Gut Microbiome Shift": ["en": "Gut Microbiome Shift", "zh-Hans": "肠道菌群重构"],
    
    // Fitness & HealthKit
    "Activity": ["en": "Activity", "zh-Hans": "活动"],
    "Today's Activity": ["en": "Today's Activity", "zh-Hans": "今日活动"],
    "Active Calories": ["en": "Active Calories", "zh-Hans": "活动消耗"],
    "Steps": ["en": "Steps", "zh-Hans": "步数"],
    "This Week's Workouts": ["en": "This Week's Workouts", "zh-Hans": "本周训练"],
    "No workouts this week": ["en": "No workouts this week", "zh-Hans": "本周暂无训练记录"],
    "Connect Health": ["en": "Connect Health", "zh-Hans": "连接健康"],
    "Connect Apple Health to track your exercise and calorie burn.": ["en": "Connect Apple Health to track your exercise and calorie burn.", "zh-Hans": "连接 Apple 健康以追踪运动和消耗"],
    "Net Balance": ["en": "Net Balance", "zh-Hans": "净热量"],
    "Exercise Burn": ["en": "Exercise Burn", "zh-Hans": "运动消耗"],
    "Fitness Advice": ["en": "Fitness Advice", "zh-Hans": "健身建议"],
    
    // Workout types
    "Running": ["en": "Running", "zh-Hans": "跑步"],
    "Walking": ["en": "Walking", "zh-Hans": "步行"],
    "Cycling": ["en": "Cycling", "zh-Hans": "骑行"],
    "Strength Training": ["en": "Strength Training", "zh-Hans": "力量训练"],
    "Yoga": ["en": "Yoga", "zh-Hans": "瑜伽"],
    "Swimming": ["en": "Swimming", "zh-Hans": "游泳"],
    "HIIT": ["en": "HIIT", "zh-Hans": "高强度间歇"],
    "Core Training": ["en": "Core Training", "zh-Hans": "核心训练"],
    "Elliptical": ["en": "Elliptical", "zh-Hans": "椭圆机"],
    "Rowing": ["en": "Rowing", "zh-Hans": "划船"],
    "Workout": ["en": "Workout", "zh-Hans": "训练"],
    
    // Fitness recommendations
    "Resistance Training": ["en": "Resistance Training", "zh-Hans": "抗阻训练"],
    "resistance_training_desc": ["en": "Critical during calorie deficit. Without resistance training, up to 2/3 of weight loss may come from muscle, not fat. Aim for 2-3 sessions per week targeting major muscle groups.", "zh-Hans": "热量缺口期间至关重要。没有抗阻训练，减掉的体重中可能有2/3是肌肉而非脂肪。每周2-3次，覆盖主要肌群。"],
    "Exercise Timing": ["en": "Exercise Timing", "zh-Hans": "运动时机"],
    "exercise_timing_desc": ["en": "High-intensity training should be done during your eating window. Light activities like walking are safe during fasting and can enhance fat oxidation.", "zh-Hans": "高强度训练应安排在进食窗口内。低强度活动（如步行）可在断食期间进行，有助于增强脂肪氧化。"],
    "Post-Workout Protein": ["en": "Post-Workout Protein", "zh-Hans": "训练后蛋白质"],
    "post_workout_protein_desc": ["en": "Consume ~%dg protein within 2 hours after training. Prioritize animal-source protein (meat, eggs, dairy) for higher bioavailability.", "zh-Hans": "训练后2小时内摄入约%dg蛋白质。优先选择动物源蛋白（肉、蛋、奶），生物利用度更高。"],
    "Sarcopenia Prevention": ["en": "Sarcopenia Prevention", "zh-Hans": "预防肌少症"],
    "sarcopenia_desc": ["en": "At 65+, muscle preservation is critical. Combine resistance training with protein ≥1.2g/kg daily. Focus on functional movements: squats, push-ups, balance exercises.", "zh-Hans": "65岁以上，保持肌肉至关重要。抗阻训练配合每日蛋白质≥1.2g/kg。重点做功能性动作：深蹲、俯卧撑、平衡训练。"],
    "Fasted Walking": ["en": "Fasted Walking", "zh-Hans": "空腹步行"],
    "fasted_walking_desc": ["en": "Walking during fasting is safe and effective. 30-45 minutes of brisk walking can enhance fat oxidation without depleting muscle glycogen.", "zh-Hans": "断食期间步行安全有效。30-45分钟快走可增强脂肪氧化，不会消耗肌糖原。"],
    "Hydration & Electrolytes": ["en": "Hydration & Electrolytes", "zh-Hans": "补水与电解质"],
    "hydration_desc": ["en": "Fasting lowers insulin, causing kidneys to excrete water and sodium. Drink plenty of water and supplement electrolytes, especially during exercise.", "zh-Hans": "断食降低胰岛素，肾脏会排出大量水分和钠。充足饮水并补充电解质，运动时尤其重要。"],
    "Weekly Target": ["en": "Weekly Target", "zh-Hans": "每周目标"],
    "weekly_target_desc": ["en": "%d sessions × %d minutes per week. Mix resistance training with moderate cardio for optimal results.", "zh-Hans": "每周%d次 × 每次%d分钟。抗阻训练搭配中等有氧，效果最佳。"],
    
    // Milestone descriptions
    "milestone_adaptation_desc": ["en": "Your body is adjusting to the fasting schedule. Hunger signals will normalize. Stay hydrated.", "zh-Hans": "身体正在适应断食节奏。饥饿信号会逐渐正常化。保持充足饮水。"],
    "milestone_metabolic_shift_desc": ["en": "Fat-burning pathways are activating. You may notice improved energy and mental clarity.", "zh-Hans": "脂肪燃烧通路正在激活。你可能会感到精力提升、思维更清晰。"],
    "milestone_first_results_desc": ["en": "Expected progress: ~%@kg. Insulin sensitivity improving. Check your measurements.", "zh-Hans": "预期进展：约%@kg。胰岛素敏感性改善中。量一下体围吧。"],
    "milestone_clinical_desc": ["en": "Expected: ~%@kg loss. This is where research shows meaningful health improvements.", "zh-Hans": "预期：约减%@kg。研究表明此阶段健康指标开始显著改善。"],
    "milestone_consolidation_desc": ["en": "Habits are solidified. Metabolic benefits are well-established. Time to evaluate next phase.", "zh-Hans": "习惯已稳固，代谢获益已确立。是时候评估下一阶段了。"],
    "milestone_complete_desc": ["en": "Evaluate results and decide: maintain, adjust, or start a new cycle.", "zh-Hans": "评估结果，决定下一步：维持、调整还是开启新周期。"],
    
    // Plan Progress
    "Plan Progress": ["en": "Plan Progress", "zh-Hans": "计划进度"],
    "weeks": ["en": "weeks", "zh-Hans": "周"],
    "Adjust Start Time": ["en": "Adjust Start Time", "zh-Hans": "调整开始时间"],
    "Longest Streak": ["en": "Longest Streak", "zh-Hans": "最长连续"],
    "No fasts this day": ["en": "No fasts this day", "zh-Hans": "当天无断食记录"],
    "Today": ["en": "Today", "zh-Hans": "今天"],
    "Yesterday": ["en": "Yesterday", "zh-Hans": "昨天"],
    "Status": ["en": "Status", "zh-Hans": "状态"],
    "Tomorrow": ["en": "Tomorrow", "zh-Hans": "明天"],
    "days away": ["en": "days away", "zh-Hans": "天后"],
    "Normal": ["en": "Normal", "zh-Hans": "正常"],
    "Skip": ["en": "Skip", "zh-Hans": "跳过"],
    "Flexible": ["en": "Flexible", "zh-Hans": "弹性"],
    "Extended": ["en": "Extended", "zh-Hans": "加长"],
    "week_number": ["en": "Week %d", "zh-Hans": "第 %d 周"],
    "week_progress": ["en": "%d/%d weeks", "zh-Hans": "%d/%d 周"],
    "Half Way! 💪": ["en": "Half Way! 💪", "zh-Hans": "已过半！💪"],
    "halfway_body": ["en": "You're halfway through your %@ fast. Keep going!", "zh-Hans": "%@ 断食已过半，继续坚持！"],
    "Goal Reached! 🎉": ["en": "Goal Reached! 🎉", "zh-Hans": "目标达成！🎉"],
    "complete_body": ["en": "Your %@ fast is complete! Well done.", "zh-Hans": "%@ 断食完成！干得漂亮。"],
    "Connect": ["en": "Connect", "zh-Hans": "连接"],
    
    // Mood check-in
    "Your mood": ["en": "Your mood", "zh-Hans": "你的状态"],
    "Any symptoms?": ["en": "Any symptoms?", "zh-Hans": "有什么症状吗？"],
    "For you": ["en": "For you", "zh-Hans": "给你的建议"],
    "safety_consider_ending": ["en": "It's okay to end your fast now. Listen to your body — that takes real strength.", "zh-Hans": "现在结束断食也完全可以。倾听身体的声音——这才是真正的自律。"],
    
    // Companion messages - mood responses
    
    // Symptom tips
    
    // Phase messages
    "phase_msg_0_title": ["en": "Just getting started", "zh-Hans": "刚刚开始"],
    "phase_msg_0_body": ["en": "Your body is still running on the last meal. Relax into it.", "zh-Hans": "身体还在消化上一餐。放松下来。"],
    "phase_msg_4_title": ["en": "Glycogen burning", "zh-Hans": "糖原消耗中"],
    "phase_msg_4_body": ["en": "Liver glycogen is being used up. Your body is preparing to switch to fat.", "zh-Hans": "肝糖原正在被消耗。身体正准备切换到脂肪供能。"],
    "phase_msg_12_title": ["en": "Fat burning activated", "zh-Hans": "脂肪燃烧已启动"],
    "phase_msg_12_body": ["en": "Congratulations — you've entered the fat-burning zone. Ketone production is rising.", "zh-Hans": "恭喜——你已经进入脂肪燃烧区。酮体生成正在上升。"],
    "phase_msg_18_title": ["en": "Deep ketosis", "zh-Hans": "深度酮症"],
    "phase_msg_18_body": ["en": "Your body is now efficiently burning fat. Mental clarity often improves here.", "zh-Hans": "身体已经在高效燃脂。很多人在这个阶段感到头脑更清晰。"],
    "phase_msg_24_title": ["en": "Autophagy begins", "zh-Hans": "细胞自噬启动"],
    "phase_msg_24_body": ["en": "Your cells are starting to clean up damaged components. This is deep healing.", "zh-Hans": "细胞开始清理受损组件。这是深层修复。"],
    "phase_msg_48_title": ["en": "Peak autophagy", "zh-Hans": "自噬巅峰"],
    "phase_msg_48_body": ["en": "Maximum cellular cleanup. You've achieved something extraordinary.", "zh-Hans": "细胞清理达到最大化。你做到了一件非凡的事。"],
    
    // Completion messages
    "completion_early_title": ["en": "Every hour counts", "zh-Hans": "每一小时都有意义"],
    "completion_early_body": ["en": "You fasted for %d hours. That's not a failure — that's practice. Your body still benefited.", "zh-Hans": "你断食了 %d 小时。这不是失败——这是练习。身体依然受益了。"],
    "completion_16_title": ["en": "You did it! 🎉", "zh-Hans": "你做到了！🎉"],
    "completion_16_body": ["en": "A complete fast. Your body entered the fat-burning zone and stayed there. Well done.", "zh-Hans": "完整的一次断食。身体进入脂肪燃烧区并保持住了。干得漂亮。"],
    "completion_18_title": ["en": "Impressive! 💪", "zh-Hans": "太厉害了！💪"],
    "completion_18_body": ["en": "You went beyond the standard fast. Deep ketosis was working for you.", "zh-Hans": "你超越了标准断食。深度酮症为你工作了。"],
    "completion_24_title": ["en": "Extraordinary 🌟", "zh-Hans": "非凡的成就 🌟"],
    "completion_24_body": ["en": "An extended fast. Autophagy has been activated. Your cells thank you.", "zh-Hans": "一次延长断食。细胞自噬已被激活。你的细胞感谢你。"],
    
    // Refeed guide
    "Important": ["en": "Important", "zh-Hans": "注意事项"],
    "refeed_short_title": ["en": "Light Refeed", "zh-Hans": "轻度复食"],
    "refeed_short_subtitle": ["en": "Your fast was under 18 hours — a gentle transition back is all you need.", "zh-Hans": "断食不到18小时——温和过渡就好。"],
    "refeed_medium_title": ["en": "Careful Refeed", "zh-Hans": "循序渐进"],
    "refeed_medium_subtitle": ["en": "After 18+ hours, your gut needs a gentle wake-up call.", "zh-Hans": "18小时以上的断食，肠胃需要温柔唤醒。"],
    "refeed_extended_title": ["en": "Structured Refeed", "zh-Hans": "分阶段复食"],
    "refeed_extended_subtitle": ["en": "Extended fasts require careful refeeding to avoid discomfort.", "zh-Hans": "长时间断食需要谨慎复食，避免不适。"],
    "refeed_timing_first": ["en": "First", "zh-Hans": "首先"],
    "refeed_timing_15min": ["en": "After 15 min", "zh-Hans": "15分钟后"],
    "refeed_timing_30min": ["en": "After 30 min", "zh-Hans": "30分钟后"],
    "refeed_timing_1h": ["en": "After 1 hour", "zh-Hans": "1小时后"],
    "refeed_timing_2h": ["en": "After 2 hours", "zh-Hans": "2小时后"],
    "refeed_timing_3h": ["en": "After 3 hours", "zh-Hans": "3小时后"],
    "refeed_water_title": ["en": "Warm water", "zh-Hans": "温水"],
    "refeed_water_detail": ["en": "Start with a glass of warm water. Let your stomach wake up gently.", "zh-Hans": "先喝一杯温水。让胃温柔地醒过来。"],
    "refeed_light_title": ["en": "Light vegetables", "zh-Hans": "清淡蔬菜"],
    "refeed_light_detail": ["en": "A small portion of cooked, non-starchy vegetables. Easy to digest.", "zh-Hans": "一小份煮熟的非淀粉类蔬菜。容易消化。"],
    "refeed_meal_title": ["en": "Normal meal", "zh-Hans": "正常饮食"],
    "refeed_short_meal_detail": ["en": "You can resume normal eating. Focus on protein and vegetables first.", "zh-Hans": "可以恢复正常饮食。优先吃蛋白质和蔬菜。"],
    "refeed_broth_title": ["en": "Bone broth or miso", "zh-Hans": "骨汤或味噌汤"],
    "refeed_broth_detail": ["en": "Warm broth restores electrolytes and primes your digestive system.", "zh-Hans": "温热的汤补充电解质，唤醒消化系统。"],
    "refeed_broth_extended_detail": ["en": "Start with small sips of bone broth. Rich in minerals, gentle on the gut.", "zh-Hans": "从小口骨汤开始。富含矿物质，对肠胃温和。"],
    "refeed_vegsoup_title": ["en": "Vegetable soup", "zh-Hans": "蔬菜汤"],
    "refeed_vegsoup_detail": ["en": "A warm, blended vegetable soup. Avoid raw vegetables — your gut isn't ready.", "zh-Hans": "温热的蔬菜汤。避免生蔬菜——肠胃还没准备好。"],
    "refeed_protein_title": ["en": "Lean protein", "zh-Hans": "优质蛋白"],
    "refeed_protein_detail": ["en": "Small portion of fish, eggs, or chicken. Avoid heavy red meat.", "zh-Hans": "一小份鱼、蛋或鸡肉。避免较重的红肉。"],
    "refeed_extended_protein_detail": ["en": "Very small portion of easily digestible protein — steamed fish or soft eggs.", "zh-Hans": "极少量易消化蛋白——清蒸鱼或软蛋。"],
    "refeed_fermented_title": ["en": "Fermented foods", "zh-Hans": "发酵食品"],
    "refeed_fermented_detail": ["en": "A small amount of yogurt, kimchi, or sauerkraut to restore gut bacteria.", "zh-Hans": "少量酸奶、泡菜或酸菜，帮助恢复肠道菌群。"],
    "refeed_millet_title": ["en": "Gentle grains", "zh-Hans": "温和谷物"],
    "refeed_millet_detail": ["en": "Small bowl of congee or millet porridge. Easy on the digestive system.", "zh-Hans": "一小碗粥或小米粥。对消化系统很温和。"],
    "refeed_warn_no_sugar": ["en": "Avoid sugar and refined carbs — they cause insulin spikes after fasting.", "zh-Hans": "避免糖和精制碳水——断食后会导致胰岛素剧烈波动。"],
    "refeed_warn_small_portions": ["en": "Eat small portions. Your stomach has shrunk — respect its new capacity.", "zh-Hans": "吃少量。胃已经缩小了——尊重它现在的容量。"],
    "refeed_warn_insulin": ["en": "Refeeding syndrome risk: after 24h+ fasts, sudden carbs can cause dangerous electrolyte shifts.", "zh-Hans": "再喂养综合征风险：24小时以上的断食后，突然摄入碳水可能导致危险的电解质紊乱。"],
    
    // Mood Check-in
    "How are you feeling?": ["en": "How are you feeling?", "zh-Hans": "你现在感觉怎么样？"],
    "companion_checkin_subtitle": ["en": "Quick check-in, we're here for you", "zh-Hans": "快速记录，我们陪着你"],
    "mood_great": ["en": "Great", "zh-Hans": "很好"],
    "mood_good": ["en": "Good", "zh-Hans": "不错"],
    "mood_neutral": ["en": "Okay", "zh-Hans": "一般"],
    "mood_tough": ["en": "Tough", "zh-Hans": "有点难"],
    "mood_struggling": ["en": "Hard", "zh-Hans": "很挣扎"],
    "headache": ["en": "Headache", "zh-Hans": "头痛"],
    "irritable": ["en": "Irritable", "zh-Hans": "易怒"],
    "foggy": ["en": "Brain fog", "zh-Hans": "脑雾"],
    "hungry": ["en": "Hungry", "zh-Hans": "饥饿"],
    "energetic": ["en": "Energetic", "zh-Hans": "精力充沛"],
    "clearMinded": ["en": "Clear mind", "zh-Hans": "头脑清晰"],
    "dizzy": ["en": "Dizzy", "zh-Hans": "头晕"],
    "anxious": ["en": "Anxious", "zh-Hans": "焦虑"],
    
    // Companion Phase Messages
    "companion_phase_start": ["en": "You've just started. Your body is still using the last meal's energy. Relax.", "zh-Hans": "刚刚开始。身体还在消耗上一餐的能量。放松。"],
    "companion_phase_early": ["en": "Insulin is dropping, blood sugar stabilizing. Your body is transitioning smoothly.", "zh-Hans": "胰岛素在下降，血糖趋于稳定。身体正在平滑过渡。"],
    "companion_phase_burning": ["en": "Glycogen stores are running low. Your body is starting to unlock fat reserves.", "zh-Hans": "糖原储备快用完了。身体正在解锁脂肪储备。"],
    "companion_phase_switch": ["en": "The metabolic switch is happening. Fat is becoming your primary fuel source.", "zh-Hans": "代谢切换正在发生。脂肪正在成为主要燃料来源。"],
    "companion_phase_ketone": ["en": "Ketones are rising. Your brain is getting a premium energy source. Mental clarity incoming.", "zh-Hans": "酮体在升高。大脑获得了优质能源。思维清晰度提升中。"],
    "companion_phase_cleanup": ["en": "Autophagy is accelerating. Your cells are cleaning house — recycling damaged proteins.", "zh-Hans": "细胞自噬在加速。细胞正在大扫除——回收受损蛋白质。"],
    "companion_phase_almostthere": ["en": "You're in the deep zone. Every hour now multiplies the benefits. Almost there.", "zh-Hans": "你已进入深水区。现在每过一小时收益都在叠加。快到了。"],
    "companion_phase_beyond": ["en": "Beyond 24 hours — you're in rare territory. Deep autophagy, HGH surge, cellular renewal.", "zh-Hans": "超过24小时——你进入了稀有领域。深度自噬、生长激素飙升、细胞更新。"],
    
    // Companion Mood Responses
    "companion_great_early": ["en": "That's the honeymoon phase! Enjoy it. Your body is well-fueled.", "zh-Hans": "这是蜜月期！好好享受。身体能量充足。"],
    "companion_great_mid": ["en": "Still feeling great — your body is adapting beautifully to fasting.", "zh-Hans": "状态依然很好——身体在完美适应断食。"],
    "companion_great_late": ["en": "Feeling great at this stage is a sign of metabolic flexibility. Your body knows what it's doing.", "zh-Hans": "在这个阶段感觉很好，说明代谢灵活性很高。身体知道它在做什么。"],
    "companion_great_extended": ["en": "You're in the zone. Ride this wave.", "zh-Hans": "你进入状态了。乘着这股浪吧。"],
    "companion_good_early": ["en": "Solid start. Just settle in and let your body do its thing.", "zh-Hans": "不错的开始。安顿下来，让身体做它的事。"],
    "companion_good_mid": ["en": "You're doing well. The harder part may come soon — we'll be here.", "zh-Hans": "做得很好。可能快到难的部分了——我们会在这里。"],
    "companion_good_late": ["en": "Past the halfway point and still good? You've got this.", "zh-Hans": "过了一半还挺好的？稳了。"],
    "companion_good_extended": ["en": "Consistent good mood this deep in — impressive adaptation.", "zh-Hans": "这么深入还保持好心情——适应能力很强。"],
    "companion_neutral_early": ["en": "Neutral is fine. No need to force feelings. Just be.", "zh-Hans": "平淡也挺好。不用强迫自己有什么感觉。顺其自然。"],
    "companion_neutral_mid": ["en": "A flat feeling around now is normal. Your hormones are adjusting. Drink some water.", "zh-Hans": "现在感觉平平是正常的。激素在调整。喝点水。"],
    "companion_neutral_late": ["en": "If you're not feeling bad, that's actually great news at this stage.", "zh-Hans": "如果没有不舒服，在这个阶段其实是好消息。"],
    "companion_neutral_extended": ["en": "Steady and neutral — your body has found its rhythm.", "zh-Hans": "稳定平和——身体找到了节奏。"],
    "companion_tough_early": ["en": "It's still early — this might just be habit hunger, not real hunger. It'll pass in ~20 minutes.", "zh-Hans": "还早——这可能只是习惯性饥饿，不是真正的饥饿。大约20分钟后会过去。"],
    "companion_tough_mid": ["en": "This is the hardest stretch for most people. Your body is right at the metabolic crossover. Push through 30 more minutes and it gets easier.", "zh-Hans": "这是大多数人最难的阶段。身体正在代谢切换点。再坚持30分钟就会好转。"],
    "companion_tough_late": ["en": "Feeling tough but you're still here — that's strength. Try a pinch of salt in water for the electrolytes.", "zh-Hans": "感觉艰难但你还在——这就是力量。试试在水里加一小撮盐补充电解质。"],
    "companion_tough_extended": ["en": "This deep and still pushing? Respect. But listen to your body — there's no shame in stopping.", "zh-Hans": "这么深入还在坚持？敬意。但要听身体的声音——停下来没什么丢人的。"],
    "companion_struggling_early": ["en": "If you're struggling this early, it might not be the right day. That's okay. Tomorrow is another chance.", "zh-Hans": "如果这么早就很挣扎，可能今天不是合适的日子。没关系。明天还有机会。"],
    "companion_struggling_mid": ["en": "Your cortisol might be elevated. Try: deep breathing (4-7-8), walk outside, or splash cold water on your face.", "zh-Hans": "皮质醇可能偏高。试试：深呼吸（4-7-8）、出去走走、或用冷水拍脸。"],
    "companion_struggling_late": ["en": "You've already gotten most of the benefits at this point. If your body is screaming, it's okay to listen.", "zh-Hans": "到这个时间点，大部分收益你已经拿到了。如果身体在呐喊，可以听它的。"],
    "companion_struggling_extended": ["en": "Struggling beyond 18 hours needs attention. Please consider ending — the benefits don't outweigh distress.", "zh-Hans": "超过18小时还在挣扎需要注意。请考虑结束——收益不值得让你这么难受。"],
    "companion_safety_check": ["en": "\n⚠️ If you feel dizzy, have heart palpitations, or can't concentrate, please end your fast now. Safety first, always.", "zh-Hans": "\n⚠️ 如果感到头晕、心悸或无法集中注意力，请立即结束断食。安全永远第一。"],
    
    // Symptom Tips
    "symptom_tip_headache": ["en": "Headaches during fasting are usually from dehydration or caffeine withdrawal. Drink water with a pinch of salt.", "zh-Hans": "断食期间头痛通常是脱水或咖啡因戒断引起的。喝加一小撮盐的水。"],
    "symptom_tip_irritable": ["en": "Irritability often peaks when blood sugar dips. This is temporary — your body is switching fuel sources.", "zh-Hans": "血糖下降时易怒感往往最强。这是暂时的——身体在切换燃料来源。"],
    "symptom_tip_foggy": ["en": "Brain fog usually clears once ketones kick in (around 12-16h). Hang in there — clarity is coming.", "zh-Hans": "脑雾通常在酮体启动后消散（约12-16小时）。再等等——清晰感就要来了。"],
    "symptom_tip_hungry": ["en": "Hunger comes in waves, not linearly. This wave will pass in 15-20 minutes. Drink water or have some black tea.", "zh-Hans": "饥饿感是一波一波的，不是线性的。这波会在15-20分钟后过去。喝水或黑茶。"],
    "symptom_tip_energetic": ["en": "Great! This is likely from adrenaline and ketone production. Your body is thriving.", "zh-Hans": "很好！这可能来自肾上腺素和酮体产生。身体状态很好。"],
    "symptom_tip_clearMinded": ["en": "Mental clarity from ketones! Your brain loves this fuel — it's more efficient than glucose.", "zh-Hans": "酮体带来的思维清晰！大脑喜欢这种燃料——比葡萄糖更高效。"],
    "symptom_tip_dizzy": ["en": "Dizziness can mean low blood pressure or electrolyte imbalance. Stand up slowly, and add salt to your water.", "zh-Hans": "头晕可能意味着低血压或电解质失衡。慢慢站起来，在水里加盐。"],
    "symptom_tip_anxious": ["en": "Anxiety during fasting can be cortisol-related. Try box breathing: inhale 4s, hold 4s, exhale 4s, hold 4s.", "zh-Hans": "断食期间的焦虑可能与皮质醇有关。试试方块呼吸：吸4秒、屏4秒、呼4秒、屏4秒。"],
    
    // Completion Messages
    "companion_end_early_title": ["en": "That's okay. Really.", "zh-Hans": "没关系。真的。"],
    "companion_end_early_body": ["en": "You fasted for %@ hours — that still counts. Every attempt builds metabolic flexibility. No guilt.", "zh-Hans": "你断食了 %@ 小时——这算数的。每次尝试都在构建代谢灵活性。不要内疚。"],
    "companion_end_short_title": ["en": "Well done! 💚", "zh-Hans": "做得好！💚"],
    "companion_end_short_body": ["en": "You completed your fast. Your body thanks you. Now let's refuel properly.", "zh-Hans": "你完成了断食。身体感谢你。现在让我们好好复食。"],
    "companion_end_medium_title": ["en": "Incredible effort! 🌟", "zh-Hans": "了不起的坚持！🌟"],
    "companion_end_medium_body": ["en": "%@ hours of fasting — deep fat burning achieved, ketones elevated, cells cleaned up. You earned this meal.", "zh-Hans": "%@ 小时断食——深度燃脂达成、酮体升高、细胞清理完毕。你值得这顿饭。"],
    "companion_end_long_title": ["en": "Warrior mode! 🏆", "zh-Hans": "战士模式！🏆"],
    "companion_end_long_body": ["en": "%@ hours — you've triggered deep autophagy, HGH surge, and metabolic reset. Take refueling VERY seriously.", "zh-Hans": "%@ 小时——你触发了深度自噬、生长激素飙升和代谢重置。请非常认真地对待复食。"],
    
    // Encouragement
    "companion_encourage_first": ["en": "First attempt — whether it lasted 2 hours or 20, you showed up. That's what matters.", "zh-Hans": "第一次尝试——不管持续了2小时还是20小时，你出现了。这才是最重要的。"],
    "companion_encourage_learning": ["en": "Each fast teaches your body something. You're calibrating, not failing.", "zh-Hans": "每次断食都在教会身体一些东西。你在校准，不是在失败。"],
    "companion_encourage_veteran": ["en": "You know the drill by now. Some days are harder — that's biology, not weakness.", "zh-Hans": "你已经很有经验了。有些天更难——那是生理，不是软弱。"],
    
    // Refeed Guide
    "Refeed Guide": ["en": "Refeed Guide", "zh-Hans": "复食指南"],
    "refeed_plan": ["en": "Your Refeed Plan", "zh-Hans": "你的复食计划"],
    "refeed_eat": ["en": "Recommended", "zh-Hans": "推荐"],
    "refeed_avoid": ["en": "Avoid", "zh-Hans": "避免"],
    "refeed_closing": ["en": "Remember: how you break a fast matters as much as the fast itself. Be gentle with your body.", "zh-Hans": "记住：怎么复食和断食本身一样重要。对身体温柔一点。"],
    "Got it": ["en": "Got it", "zh-Hans": "知道了"],
    "refeed_warning_insulin": ["en": "Your insulin sensitivity is elevated. Avoid sugar and refined carbs for the first meal — they'll spike blood sugar hard.", "zh-Hans": "你的胰岛素敏感度升高了。第一餐避免糖和精制碳水——它们会让血糖飙升。"],
    "refeed_warning_electrolyte": ["en": "After 24+ hours, electrolytes may be depleted. Add salt to water or drink bone broth before eating.", "zh-Hans": "超过24小时后，电解质可能耗竭。吃饭前在水里加盐或喝骨头汤。"],
    "refeed_warning_refeeding_syndrome": ["en": "After 48+ hours, refeeding syndrome is a real risk. Start with liquids only. If you feel chest tightness or irregular heartbeat, seek medical help.", "zh-Hans": "超过48小时后，再喂养综合征是真实风险。先只喝液体。如果感到胸闷或心跳不规律，请就医。"],
    
    // MARK: - Companion Phase Messages (title + body pairs)
    "companion_phase_start_title": ["en": "Just Starting", "zh-Hans": "刚刚开始"],
    "companion_phase_start_body": ["en": "Your body is still processing the last meal. Relax and ease in.", "zh-Hans": "身体还在消化上一餐。放松，慢慢进入状态。"],
    "companion_phase_digesting_title": ["en": "Post-Meal Phase", "zh-Hans": "餐后阶段"],
    "companion_phase_digesting_body": ["en": "Insulin is active, nutrients being absorbed. The real fasting hasn't started yet.", "zh-Hans": "胰岛素活跃中，营养正在被吸收。真正的断食还没开始。"],
    "companion_phase_postabsorptive_title": ["en": "Post-Absorptive", "zh-Hans": "吸收后期"],
    "companion_phase_postabsorptive_body": ["en": "Nutrient absorption complete. Your body is starting to tap glycogen stores.", "zh-Hans": "营养吸收完成。身体开始动用糖原储备。"],
    "companion_phase_burning_title": ["en": "Fat Mobilization", "zh-Hans": "脂肪动员"],
    "companion_phase_burning_body": ["en": "Glycogen is running low. Fat cells are releasing fatty acids for energy.", "zh-Hans": "糖原快用完了。脂肪细胞正在释放脂肪酸供能。"],
    "companion_phase_transition_title": ["en": "Metabolic Switch", "zh-Hans": "代谢切换"],
    "companion_phase_transition_body": ["en": "Your body is switching from glucose to fat as primary fuel. This is the key transition.", "zh-Hans": "身体正从葡萄糖切换到脂肪作为主要燃料。这是关键转换点。"],
    "companion_phase_ketosis_light_title": ["en": "Light Ketosis", "zh-Hans": "轻度酮症"],
    "companion_phase_ketosis_light_body": ["en": "Ketone production is ramping up. Your brain is getting an alternative fuel source.", "zh-Hans": "酮体产生正在加速。大脑正在获得替代燃料。"],
    "companion_phase_deep_ketosis_title": ["en": "Deep Ketosis", "zh-Hans": "深度酮症"],
    "companion_phase_deep_ketosis_body": ["en": "Full ketosis achieved. Mental clarity, stable energy, enhanced fat burning.", "zh-Hans": "完全酮症达成。思维清晰、能量稳定、燃脂增强。"],
    "companion_phase_autophagy_title": ["en": "Autophagy Active", "zh-Hans": "自噬激活"],
    "companion_phase_autophagy_body": ["en": "Your cells are recycling damaged proteins and organelles. Deep cellular cleanup.", "zh-Hans": "细胞正在回收受损蛋白质和细胞器。深层细胞清理中。"],
    "companion_phase_extended_title": ["en": "Extended Fast", "zh-Hans": "延长断食"],
    "companion_phase_extended_body": ["en": "Deep autophagy, elevated HGH, metabolic reset. Monitor how you feel closely.", "zh-Hans": "深度自噬、生长激素升高、代谢重置。密切关注身体感受。"],
    "companion_phase_halfway_body": ["en": "Halfway through! Fat burning is accelerating. You're doing great.", "zh-Hans": "过半了！脂肪燃烧在加速。你做得很棒。"],
    "companion_phase_deep_body": ["en": "Deep into fasting territory. Ketones are fueling your brain now.", "zh-Hans": "进入断食深水区。酮体正在为大脑供能。"],
    "companion_phase_ketosis_body": ["en": "Ketosis is kicking in. Mental sharpness incoming.", "zh-Hans": "酮症启动中。思维敏捷度即将提升。"],
    "companion_phase_champion_body": ["en": "Champion level! You've unlocked maximum fasting benefits.", "zh-Hans": "冠军级别！你已解锁最大断食收益。"],
    
    // Mood fallback (general)
    "companion_great_general": ["en": "You're feeling great — your body is responding beautifully to the fast.", "zh-Hans": "你感觉很好——身体对断食的反应非常棒。"],
    "companion_good_general": ["en": "Good energy! Your metabolism is working well.", "zh-Hans": "状态不错！代谢运转良好。"],
    "companion_neutral_general": ["en": "Steady and stable — that's perfectly normal during fasting.", "zh-Hans": "平稳稳定——这在断食中是完全正常的。"],
    "companion_tough_general": ["en": "Hang in there. This tough phase is temporary — your body is adapting.", "zh-Hans": "坚持住。这个困难阶段是暂时的——身体正在适应。"],
    "companion_struggling_general": ["en": "It's okay to struggle. Listen to your body — there's no shame in stopping if you need to.", "zh-Hans": "挣扎是正常的。倾听身体的声音——如果需要停下来，完全没问题。"],
    
    // MARK: - Safety & Positive Reinforcement
    "companion_safety_stop": ["en": "⚠️ You're struggling with concerning symptoms. Please consider ending your fast now. Your health comes first — always.", "zh-Hans": "⚠️ 你正在经历令人担忧的症状。请考虑立即结束断食。健康永远第一。"],
    "companion_safety_14h": ["en": "💛 You've been at it for a while and it's getting tough. There's no shame in stopping here — you've already gained significant benefits.", "zh-Hans": "💛 你已经坚持了很久，而且越来越难了。在这里停下来没什么丢人的——你已经获得了显著的收益。"],
    "companion_positive_both": ["en": "Energetic AND clear-minded? That's the sweet spot. Your body is in full fat-burning mode and loving it.", "zh-Hans": "精力充沛又头脑清晰？这就是最佳状态。身体全面燃脂中，而且乐在其中。"],
    "companion_positive_energy": ["en": "That energy surge is from adrenaline and ketones working together. Ride the wave!", "zh-Hans": "那股能量来自肾上腺素和酮体的协同作用。乘浪前行！"],
    "companion_positive_clarity": ["en": "Mental clarity from ketones — your brain is running on premium fuel right now.", "zh-Hans": "酮体带来的思维清晰——你的大脑现在在用高级燃料运转。"],
    
    // MARK: - Completion Messages
    "companion_complete_title": ["en": "You did it! 🎉", "zh-Hans": "你做到了！🎉"],
    "companion_complete_body": ["en": "Amazing — %d hours of fasting completed. Your body thanks you.", "zh-Hans": "太棒了——%d小时断食完成。身体感谢你。"],
    "companion_incomplete_title": ["en": "Every hour counts 💚", "zh-Hans": "每一小时都算数 💚"],
    "companion_incomplete_body": ["en": "You fasted for %d hours. That's not failure — that's building metabolic flexibility.", "zh-Hans": "你断食了%d小时。这不是失败——这是在构建代谢灵活性。"],
    
    // MARK: - Symptom Advice
    "symptom_advice_dizzy": ["en": "💫 Dizziness can signal low blood pressure or electrolytes. Sit down, add salt to water, and stand up slowly. If it persists, please end your fast.", "zh-Hans": "💫 头晕可能是低血压或电解质不足的信号。坐下来，水里加盐，慢慢站起来。如果持续，请结束断食。"],
    "symptom_advice_headache": ["en": "🤕 Headaches are usually dehydration or caffeine withdrawal. Drink 500ml water with a pinch of salt. It should ease in 20-30 minutes.", "zh-Hans": "🤕 头痛通常是脱水或咖啡因戒断。喝500ml加了一小撮盐的水。20-30分钟后应该会缓解。"],
    "symptom_advice_anxious": ["en": "😟 Anxiety may be cortisol-related. Try box breathing: inhale 4s → hold 4s → exhale 4s → hold 4s. Repeat 4 times.", "zh-Hans": "😟 焦虑可能和皮质醇有关。试试方块呼吸：吸4秒→屏4秒→呼4秒→屏4秒。重复4次。"],
    "symptom_advice_foggy": ["en": "🌫️ Brain fog usually clears once ketones kick in (12-16h). Hang in there — mental clarity is coming.", "zh-Hans": "🌫️ 脑雾通常在酮体启动后消散（12-16小时）。再等等——清晰感就要来了。"],
    "symptom_advice_irritable": ["en": "😤 Irritability peaks when blood sugar drops. It's temporary. A walk or cold water on your face can help reset.", "zh-Hans": "😤 血糖下降时易怒感最强。这是暂时的。散步或冷水拍脸可以帮助重置。"],
    "symptom_advice_hungry": ["en": "🍽️ Hunger comes in waves, not a straight line. This wave will pass in 15-20 minutes. Stay hydrated.", "zh-Hans": "🍽️ 饥饿感是一波一波的，不是直线上升。这波会在15-20分钟后过去。保持水分。"],
    
    // MARK: - Mood Check-in UI
    "timer_next_phase": ["en": "Next", "zh-Hans": "下一步"],
    
    // MARK: - Unified Fasting Phases (science + companion merged)
    
    // Phase 0: 0-2h Post-meal
    "phase_postmeal_name": ["en": "Post-Meal", "zh-Hans": "餐后期"],
    "phase_postmeal_ev1_title": ["en": "Insulin Peak", "zh-Hans": "胰岛素峰值"],
    "phase_postmeal_ev1_desc": ["en": "Insulin peaks as your body processes the last meal.", "zh-Hans": "胰岛素达到峰值，身体正在处理上一餐。"],
    "phase_postmeal_science": ["en": "Your body is in full absorption mode. Insulin is high, directing glucose into cells. Fat burning is suppressed. This is the easiest phase.", "zh-Hans": "身体处于完全吸收模式。胰岛素水平高，将葡萄糖导入细胞。脂肪燃烧被抑制。这是最轻松的阶段。"],
    "phase_postmeal_companion": ["en": "You just started — relax into it. Your body is still running on the last meal.", "zh-Hans": "刚刚开始——放松就好。身体还在消化上一餐。"],
    
    // Phase 1: 2-6h Absorbing
    "phase_absorbing_name": ["en": "Digesting", "zh-Hans": "消化吸收期"],
    "phase_absorbing_ev1_title": ["en": "Insulin Dropping", "zh-Hans": "胰岛素下降"],
    "phase_absorbing_ev1_desc": ["en": "Insulin begins to drop as nutrient absorption completes.", "zh-Hans": "营养吸收完成，胰岛素开始下降。"],
    "phase_absorbing_ev2_title": ["en": "Glycogen Storing", "zh-Hans": "糖原储存"],
    "phase_absorbing_ev2_desc": ["en": "Excess glucose stored as glycogen (~400-600 kcal reserve).", "zh-Hans": "多余葡萄糖被储存为糖原（约400-600kcal储备）。"],
    "phase_absorbing_science": ["en": "Insulin falls as digestion completes. Body transitions from 'fed' to 'post-absorptive' state. The real fasting hasn't begun yet.", "zh-Hans": "消化完成后胰岛素下降。身体从\"进食态\"过渡到\"吸收后态\"。真正的断食还没有开始。"],
    "phase_absorbing_companion": ["en": "Your body is wrapping up digestion. The real magic starts once glycogen runs low. You're doing great.", "zh-Hans": "身体正在完成消化。糖原用完后真正的魔法才开始。你做得很好。"],
    
    // Phase 2: 6-10h Glycogen depletion
    "phase_glycogen_science": ["en": "Liver glycogen is being rapidly consumed. Insulin drops further, signaling fat cells to release fatty acids. Mild hunger is normal and temporary.", "zh-Hans": "肝糖原正在被快速消耗。胰岛素进一步下降，向脂肪细胞发出释放脂肪酸的信号。轻微饥饿感是正常的，且是暂时的。"],
    "phase_glycogen_companion": ["en": "Glycogen is running low — your body is about to switch fuel sources. Hunger waves will pass in ~20 minutes. Drink some water.", "zh-Hans": "糖原快用完了——身体即将切换燃料。饥饿感大约20分钟就会过去。喝点水。"],
    
    // Phase 3: 10-14h Metabolic transition
    "phase_transition_name": ["en": "Metabolic Switch", "zh-Hans": "代谢切换"],
    "phase_transition_ev1_title": ["en": "Fat Mobilization", "zh-Hans": "脂肪动员"],
    "phase_transition_ev1_desc": ["en": "Glycogen depleted. Fat cells release fatty acids as primary energy.", "zh-Hans": "糖原耗尽。脂肪细胞释放脂肪酸作为主要能源。"],
    "phase_transition_ev2_title": ["en": "Blood Sugar Stabilizes", "zh-Hans": "血糖趋稳"],
    "phase_transition_ev2_desc": ["en": "Blood sugar drops ~20% then stabilizes at a new baseline.", "zh-Hans": "血糖下降约20%后趋于稳定。"],
    "phase_transition_science": ["en": "Critical crossover window. Liver glycogen depleted, fat oxidation ramps up, early ketone production begins. This is where most people feel the hardest hunger — but it passes.", "zh-Hans": "关键切换窗口。肝糖原耗尽，脂肪氧化急剧上升，早期酮体生成开始。大多数人在这里感到最强饥饿——但它会过去。"],
    "phase_transition_companion": ["en": "This is the hardest stretch — you're right at the crossover point. Push through 30 more minutes and it gets noticeably easier.", "zh-Hans": "这是最难的阶段——身体正在切换点上。再坚持30分钟就会明显轻松。"],
    
    // Phase 4: 14-16h Light ketosis
    "phase_light_ketosis_name": ["en": "Light Ketosis", "zh-Hans": "轻度酮症"],
    "phase_light_ketosis_science": ["en": "Ketone production accelerates. Brain uses β-hydroxybutyrate — more efficient than glucose. Early autophagy triggered. Digestive system enters full rest.", "zh-Hans": "酮体产生加速。大脑使用β-羟基丁酸——比葡萄糖更高效。早期自噬被触发。消化系统完全休息。"],
    "phase_light_ketosis_companion": ["en": "You've crossed into ketosis — fat is now fuel. Hunger fading, mental clarity lifting. The hard part is behind you.", "zh-Hans": "你已进入酮症——脂肪现在就是燃料。饥饿消退，头脑清醒。最难的部分已经过去了。"],
    
    // Phase 5: 16-20h Deep ketosis
    "phase_deep_ketosis_name": ["en": "Deep Ketosis", "zh-Hans": "深度酮症"],
    "phase_deep_ketosis_science": ["en": "Full ketosis. BDNF surges, promoting neuroprotection. Autophagy accelerates — cells clearing damaged proteins and organelles.", "zh-Hans": "完全酮症。BDNF激增，促进神经保护。自噬加速——细胞清理受损蛋白质和细胞器。"],
    "phase_deep_ketosis_companion": ["en": "Your brain is on premium fuel. If you feel unusually clear-headed, that's BDNF. Cells are deep cleaning. Enjoy this state.", "zh-Hans": "大脑在用高级燃料。如果感觉异常清醒，那是BDNF在工作。细胞深度清理中。享受吧。"],
    
    // Phase 6: 20-24h Autophagy starts
    "phase_autophagy_start_name": ["en": "Autophagy Begins", "zh-Hans": "自噬启动"],
    "phase_autophagy_start_science": ["en": "Autophagy fully active — cells recycling damaged components at accelerating rate. Immune function optimizing. Growth hormone rises.", "zh-Hans": "自噬完全活跃——细胞以加速的速度回收受损组件。免疫功能优化。生长激素上升。"],
    "phase_autophagy_start_companion": ["en": "Almost a full day — rare territory. Autophagy in full swing. Every hour from here multiplies benefits. You've earned this.", "zh-Hans": "快一整天了——稀有领域。自噬全面启动。每过一小时收益叠加。你值得的。"],
    
    // Phase 7: 24-36h Autophagy accelerates
    "phase_autophagy_accel_name": ["en": "Autophagy Accelerating", "zh-Hans": "自噬加速"],
    "phase_autophagy_accel_science": ["en": "Autophagy in high gear. Growth hormone may be 5x baseline. Inflammation markers drop significantly.", "zh-Hans": "自噬进入高速档。生长激素可能是基线的5倍。炎症指标显著下降。"],
    "phase_autophagy_accel_companion": ["en": "Beyond 24 hours — an achievement. Deep repair mode. HGH surging, inflammation dropping. Be proud.", "zh-Hans": "超过24小时——这是成就。深度修复模式。生长激素飙升，炎症下降。骄傲吧。"],
    
    // Phase 8: 36-48h Peak autophagy
    "phase_autophagy_peak_science": ["en": "Maximum autophagy. Damaged organelles, misfolded proteins aggressively recycled. The golden window of cellular renewal.", "zh-Hans": "自噬最大化。受损细胞器、错误折叠蛋白质被积极回收。细胞更新的黄金窗口。"],
    "phase_autophagy_peak_companion": ["en": "Peak autophagy — deepest cellular clean possible. Something extraordinary. ⚠️ Past 36h, listen to your body very carefully.", "zh-Hans": "自噬巅峰——最深层的细胞清理。了不起。⚠️ 超过36小时，请仔细倾听身体。"],
    
    // Phase 9: 48-72h Immune reset
    "phase_immune_name": ["en": "Immune Reset", "zh-Hans": "免疫重启"],
    "phase_immune_science": ["en": "IGF-1 drops significantly, triggering stem cell renewal. Immune system 'rebooting'. ⚠️ Medical supervision required.", "zh-Hans": "IGF-1大幅下降，触发干细胞更新。免疫系统\"重启\"。⚠️ 需要医疗监督。"],
    "phase_immune_companion": ["en": "Immune system rebooting via stem cell renewal. Powerful but serious territory. ⚠️ Medical guidance essential.", "zh-Hans": "免疫系统通过干细胞更新重启。强力修复但也是严肃领域。⚠️ 请确保有医生指导。"],
    
    // Phase 10: 72h+ Deep remodeling
    "phase_remodel_companion": ["en": "Deep metabolic remodeling. ⚠️ Professional medical supervision required. Watch for muscle loss.", "zh-Hans": "深度代谢重塑。⚠️ 必须在专业医疗监督下进行。注意肌肉流失。"],

    // Legacy phase keys (kept for backward compat)
    "phase_glycogen_name": ["en": "Glycogen Depletion", "zh-Hans": "糖原消耗"],
    "phase_glycogen_subtitle": ["en": "Glycogen depletion phase", "zh-Hans": "糖原消耗期"],
    "phase_glycogen_ev1_title": ["en": "Insulin Drops", "zh-Hans": "胰岛素下降"],
    "phase_glycogen_ev1_desc": ["en": "Insulin levels begin to drop. Your body switches from \"storage mode\" to \"consumption mode\".", "zh-Hans": "胰岛素水平开始下降，身体从\"储存模式\"切换到\"消耗模式\""],
    "phase_glycogen_ev2_title": ["en": "Liver Glycogen Burning", "zh-Hans": "肝糖原消耗"],
    "phase_glycogen_ev2_desc": ["en": "Your liver starts burning stored glycogen (approximately 400-600kcal of reserves).", "zh-Hans": "肝脏开始消耗储存的糖原（约400-600kcal的储备）"],
    "phase_glycogen_ev3_title": ["en": "Fat Mobilization Starts", "zh-Hans": "脂肪动员启动"],
    "phase_glycogen_ev3_desc": ["en": "Fat mobilization initiates — fat cells begin releasing fatty acids.", "zh-Hans": "脂肪动员初步启动，脂肪细胞开始释放脂肪酸"],
    "phase_glycogen_detail": ["en": "Your body is consuming liver glycogen stores. Insulin drops and fat breakdown begins. This is the easiest phase — you likely won't feel significant hunger.", "zh-Hans": "身体正在消耗肝脏中储存的糖原。胰岛素水平下降，脂肪分解开始启动。这是最轻松的阶段——你可能不会感到明显的饥饿感。"],
    
    "phase_ketosis_name": ["en": "Ketosis Initiation", "zh-Hans": "酮症启动"],
    "phase_ketosis_subtitle": ["en": "Ketosis activation", "zh-Hans": "酮症启动期"],
    "phase_ketosis_ev1_title": ["en": "Ketone Production", "zh-Hans": "酮体产生"],
    "phase_ketosis_ev1_desc": ["en": "Liver glycogen is nearly depleted. Your body starts converting fat into ketones (β-hydroxybutyrate) as alternative fuel.", "zh-Hans": "肝糖原基本耗尽，身体开始将脂肪转化为酮体（β-羟基丁酸）作为替代燃料"],
    "phase_ketosis_ev2_title": ["en": "Blood Sugar -20%", "zh-Hans": "血糖下降20%"],
    "phase_ketosis_ev2_desc": ["en": "Blood sugar drops about 20%. Your body adapts to using fat for energy.", "zh-Hans": "血糖水平下降约20%，身体适应使用脂肪供能"],
    "phase_ketosis_ev3_title": ["en": "Autophagy Begins", "zh-Hans": "自噬启动"],
    "phase_ketosis_ev3_desc": ["en": "Autophagy is induced — cells begin clearing damaged proteins and organelles.", "zh-Hans": "自噬作用被诱导——细胞开始清理内部受损的蛋白质和细胞器"],
    "phase_ketosis_ev4_title": ["en": "Digestive Rest", "zh-Hans": "消化系统休息"],
    "phase_ketosis_ev4_desc": ["en": "Your digestive system enters complete rest. The gut begins self-repair.", "zh-Hans": "消化系统进入完全休息状态，肠道开始自我修复"],
    "phase_ketosis_detail": ["en": "This is the critical metabolic switching window. After glycogen depletion, your body burns fat and produces ketones. Autophagy activates — your cells are doing a deep clean. You may feel mild hunger as your body adapts to the new fuel.", "zh-Hans": "这是代谢切换的关键窗口。肝糖原耗尽后，身体开始燃烧脂肪并产生酮体。自噬作用启动——你的细胞正在进行\"大扫除\"。你可能会感到轻微饥饿，但这是身体在适应新燃料。"],
    
    "phase_switch_name": ["en": "Metabolic Switch", "zh-Hans": "代谢切换"],
    "phase_switch_subtitle": ["en": "Full metabolic switch", "zh-Hans": "代谢全面切换"],
    "phase_switch_ev1_title": ["en": "Full Ketosis", "zh-Hans": "完全酮症"],
    "phase_switch_ev1_desc": ["en": "Complete switch from glucose to ketone metabolism.", "zh-Hans": "从葡萄糖代谢到酮体代谢的全面切换完成"],
    "phase_switch_ev2_title": ["en": "BDNF Surge", "zh-Hans": "BDNF激增"],
    "phase_switch_ev2_desc": ["en": "Your brain produces more BDNF (brain-derived neurotrophic factor), promoting neuroprotection and cognitive function.", "zh-Hans": "大脑分泌更多脑源性神经营养因子（BDNF），促进神经元保护和认知功能"],
    "phase_switch_ev3_title": ["en": "Autophagy Accelerates", "zh-Hans": "自噬加速"],
    "phase_switch_ev3_desc": ["en": "Autophagy significantly accelerates, thoroughly clearing damaged proteins and organelles.", "zh-Hans": "自噬作用显著加速，开始更彻底地清理受损蛋白和细胞器"],
    "phase_switch_ev4_title": ["en": "Mental Clarity", "zh-Hans": "思维清晰"],
    "phase_switch_ev4_desc": ["en": "Ketones cross the blood-brain barrier, providing more efficient energy than glucose — many report clearer thinking.", "zh-Hans": "酮体跨越血脑屏障，提供比葡萄糖更高效的能量——许多人报告思维更清晰"],
    "phase_switch_detail": ["en": "Congratulations, your body has fully switched to fat-fueled metabolism. Your brain now runs primarily on ketones with elevated BDNF protecting your neurons. Autophagy is in high gear — cellular repair at full speed.", "zh-Hans": "恭喜，你的身体已经完全切换到脂肪供能模式。大脑现在主要依靠酮体运行，BDNF水平升高正在保护你的神经元。自噬作用加速——细胞修复进入高速档。"],
    
    "phase_autophagy_name": ["en": "Peak Autophagy", "zh-Hans": "峰值自噬"],
    "phase_autophagy_subtitle": ["en": "Peak autophagy · immune reset", "zh-Hans": "峰值自噬 · 免疫重启"],
    "phase_autophagy_ev1_title": ["en": "Autophagy Peak", "zh-Hans": "自噬峰值"],
    "phase_autophagy_ev1_desc": ["en": "Autophagy reaches its peak — cellular regeneration is at maximum capacity.", "zh-Hans": "自噬达到峰值——细胞再生能力处于最强状态"],
    "phase_autophagy_ev2_title": ["en": "Immune Reset", "zh-Hans": "免疫重启"],
    "phase_autophagy_ev2_desc": ["en": "IGF-1 drops significantly, triggering hematopoietic stem cell renewal — your immune system begins to \"reboot\".", "zh-Hans": "IGF-1大幅下降，诱导造血干细胞自我更新，免疫系统开始\"重启\""],
    "phase_autophagy_ev3_title": ["en": "Stable Brain Function", "zh-Hans": "大脑功能稳定"],
    "phase_autophagy_ev3_desc": ["en": "Despite low blood sugar, your brain maintains stable — even enhanced — function powered by ketones.", "zh-Hans": "尽管血糖处于低位，大脑依靠酮体维持稳定甚至更优的功能"],
    "phase_autophagy_detail": ["en": "This is the golden phase of fasting. Autophagy peaks as your cells undergo the deepest repair and renewal. Your immune system reboots via stem cell renewal. ⚠️ Fasts beyond 48 hours require medical supervision.", "zh-Hans": "这是断食的黄金阶段。自噬达到峰值，你的细胞正在进行最深层的修复和更新。免疫系统通过干细胞更新实现\"重启\"。⚠️ 超过48小时的断食属于专业医疗干预范畴，请在医生监督下进行。"],
    
    "phase_remodel_name": ["en": "Deep Remodeling", "zh-Hans": "深度重塑"],
    "phase_remodel_subtitle": ["en": "Deep remodeling", "zh-Hans": "深度重塑期"],
    "phase_remodel_ev1_title": ["en": "New Homeostasis", "zh-Hans": "新稳态"],
    "phase_remodel_ev1_desc": ["en": "Your body establishes a new metabolic homeostasis with balanced energy supply.", "zh-Hans": "身体建立新的代谢稳态，能量供给达到平衡"],
    "phase_remodel_ev2_title": ["en": "Gut Microbiome Shift", "zh-Hans": "肠道菌群重构"],
    "phase_remodel_ev2_desc": ["en": "Major gut microbiome diversity shift (~day 9-10), producing beneficial metabolites.", "zh-Hans": "肠道微生物多样性发生重大调整（~第9-10天），产生有益代谢物"],
    "phase_remodel_ev3_title": ["en": "⚠️ Muscle Risk", "zh-Hans": "⚠️ 肌肉风险"],
    "phase_remodel_ev3_desc": ["en": "Watch for lean mass loss — in extended fasts, ~2/3 of weight loss may come from muscle.", "zh-Hans": "需警惕瘦体重流失——长期断食中约2/3减重可能来自肌肉"],
    "phase_remodel_detail": ["en": "Your body enters deep metabolic remodeling. New homeostasis is forming, but watch for muscle loss risk. ⚠️ This phase requires professional medical supervision, especially for those with diabetes, low BMI, or eating disorder history.", "zh-Hans": "身体进入深度代谢重塑阶段。新的稳态正在建立，但也需要警惕肌肉流失风险。⚠️ 此阶段必须在专业医疗监督下进行。"],
    "mood_recorded_at": ["en": "Recorded at", "zh-Hans": "记录于"],
    "mood_update": ["en": "Update", "zh-Hans": "更新"],
    "mood_very_unpleasant": ["en": "VERY UNPLEASANT", "zh-Hans": "非常不舒服"],
    "mood_very_pleasant": ["en": "VERY PLEASANT", "zh-Hans": "非常舒适"],
    "mood_question": ["en": "How are you feeling right now?", "zh-Hans": "你现在感觉怎么样？"],
    "symptom_question": ["en": "Any symptoms?", "zh-Hans": "有什么症状吗？"],
    "note_optional": ["en": "Notes (optional)", "zh-Hans": "备注（可选）"],
    "note_placeholder": ["en": "Anything you want to remember about this moment...", "zh-Hans": "想记录下这一刻的任何想法..."],
    "companion_says": ["en": "For you", "zh-Hans": "给你"],
    
    // MARK: - Refeed Foods & Reasons
    "refeed_food_warm_water": ["en": "Warm water", "zh-Hans": "温水"],
    "refeed_food_lemon_water": ["en": "Lemon water", "zh-Hans": "柠檬水"],
    "refeed_avoid_cold_drinks": ["en": "Cold or iced drinks", "zh-Hans": "冰饮"],
    "refeed_reason_hydration": ["en": "Rehydrate gently — your digestive system needs a warm wake-up.", "zh-Hans": "温和补水——消化系统需要温暖的唤醒。"],
    "refeed_food_cooked_veg": ["en": "Steamed/cooked vegetables", "zh-Hans": "蒸/煮蔬菜"],
    "refeed_food_light_soup": ["en": "Light vegetable soup", "zh-Hans": "清淡蔬菜汤"],
    "refeed_avoid_raw_salad": ["en": "Raw salads", "zh-Hans": "生冷沙拉"],
    "refeed_avoid_fried": ["en": "Fried or greasy food", "zh-Hans": "油炸油腻食物"],
    "refeed_reason_gentle_gut": ["en": "Cooked foods are gentler on a resting digestive tract.", "zh-Hans": "熟食对休息中的消化道更温和。"],
    "refeed_food_balanced_meal": ["en": "Balanced meal (protein + veg + good fats)", "zh-Hans": "均衡餐食（蛋白质+蔬菜+优质脂肪）"],
    "refeed_food_lean_protein": ["en": "Lean protein (chicken, fish, eggs)", "zh-Hans": "优质蛋白（鸡肉、鱼、蛋）"],
    "refeed_avoid_sugar": ["en": "Sugar and refined carbs", "zh-Hans": "糖和精制碳水"],
    "refeed_avoid_processed": ["en": "Processed/packaged food", "zh-Hans": "加工/包装食品"],
    "refeed_reason_nutrient_restore": ["en": "Now your body can handle a full meal. Focus on nutrient density.", "zh-Hans": "现在身体可以处理完整的一餐了。注重营养密度。"],
    "refeed_food_bone_broth": ["en": "Bone broth", "zh-Hans": "骨头汤"],
    "refeed_food_miso": ["en": "Miso soup", "zh-Hans": "味噌汤"],
    "refeed_avoid_solid_food": ["en": "Any solid food", "zh-Hans": "任何固体食物"],
    "refeed_avoid_caffeine": ["en": "Coffee or strong tea", "zh-Hans": "咖啡或浓茶"],
    "refeed_reason_electrolyte": ["en": "Broth restores sodium, potassium, and magnesium — critical after extended fasting.", "zh-Hans": "汤可以恢复钠、钾和镁——长时间断食后至关重要。"],
    "refeed_food_veg_soup": ["en": "Vegetable soup", "zh-Hans": "蔬菜汤"],
    "refeed_food_steamed_veg": ["en": "Steamed vegetables", "zh-Hans": "蒸蔬菜"],
    "refeed_avoid_dairy": ["en": "Dairy products", "zh-Hans": "乳制品"],
    "refeed_reason_enzyme_wake": ["en": "Gentle foods reactivate digestive enzymes without overwhelming the gut.", "zh-Hans": "温和的食物重新激活消化酶，不会让肠道负担过重。"],
    "refeed_food_fish": ["en": "Steamed fish", "zh-Hans": "蒸鱼"],
    "refeed_food_egg": ["en": "Soft-boiled eggs", "zh-Hans": "溏心蛋"],
    "refeed_food_tofu": ["en": "Silken tofu", "zh-Hans": "嫩豆腐"],
    "refeed_avoid_red_meat": ["en": "Red meat", "zh-Hans": "红肉"],
    "refeed_avoid_heavy_carb": ["en": "Heavy carbs (bread, pasta, rice)", "zh-Hans": "重碳水（面包、意面、米饭）"],
    "refeed_reason_gradual_protein": ["en": "Easy-to-digest proteins help rebuild without stressing the gut.", "zh-Hans": "易消化的蛋白质帮助重建，不给肠道添负担。"],
    "refeed_food_electrolyte": ["en": "Electrolyte water", "zh-Hans": "电解质水"],
    "refeed_avoid_any_solid": ["en": "Any solid food for the first hour", "zh-Hans": "第一小时内任何固体食物"],
    "refeed_reason_refeeding_risk": ["en": "After 36+ hours, refeeding syndrome is a real risk. Start liquid-only.", "zh-Hans": "超过36小时后，再喂养综合征是真实风险。先只喝液体。"],
    "refeed_food_kimchi": ["en": "Small amount of kimchi/sauerkraut", "zh-Hans": "少量泡菜/酸菜"],
    "refeed_food_yogurt_small": ["en": "Small plain yogurt", "zh-Hans": "少量原味酸奶"],
    "refeed_avoid_large_portions": ["en": "Large portions of anything", "zh-Hans": "任何大份食物"],
    "refeed_reason_microbiome": ["en": "Fermented foods gently reintroduce beneficial bacteria to the gut.", "zh-Hans": "发酵食物温和地重新引入有益菌到肠道。"],
    "refeed_food_congee": ["en": "Rice congee/porridge", "zh-Hans": "白粥"],
    "refeed_food_millet_porridge": ["en": "Millet porridge", "zh-Hans": "小米粥"],
    "refeed_avoid_wheat": ["en": "Wheat products", "zh-Hans": "小麦制品"],
    "refeed_avoid_gluten": ["en": "Gluten-heavy foods", "zh-Hans": "高麸质食物"],
    "refeed_reason_gentle_carb": ["en": "Easily digestible grains restore glycogen gently without insulin spikes.", "zh-Hans": "易消化的谷物温和恢复糖原，不会导致胰岛素飙升。"],
    "refeed_food_steamed_chicken": ["en": "Steamed chicken breast", "zh-Hans": "蒸鸡胸肉"],
    "refeed_reason_rebuild": ["en": "Your body is ready for substantial protein to rebuild and recover.", "zh-Hans": "身体准备好接受大量蛋白质来重建和恢复了。"],
    
    // MARK: - Health Conditions
    "Diabetes": ["en": "Diabetes", "zh-Hans": "糖尿病"],
    "Thyroid condition": ["en": "Thyroid condition", "zh-Hans": "甲状腺疾病"],
    "Eating disorder history": ["en": "Eating disorder history", "zh-Hans": "进食障碍史"],
    "Pregnant or nursing": ["en": "Pregnant or nursing", "zh-Hans": "怀孕或哺乳期"],
    "Heart disease": ["en": "Heart disease", "zh-Hans": "心脏疾病"],
    "Taking medication": ["en": "Taking medication", "zh-Hans": "正在服药"],
    
    // MARK: - Stress & Sleep
    "Low": ["en": "Low", "zh-Hans": "低"],
    "Moderate": ["en": "Moderate", "zh-Hans": "中等"],
    "High": ["en": "High", "zh-Hans": "高"],
    "Good (7-9h)": ["en": "Good (7-9h)", "zh-Hans": "好 (7-9h)"],
    "Fair (5-7h)": ["en": "Fair (5-7h)", "zh-Hans": "一般 (5-7h)"],
    "Poor (<5h)": ["en": "Poor (<5h)", "zh-Hans": "差 (<5h)"],
    "Stress Level": ["en": "Stress Level", "zh-Hans": "压力水平"],
    "Sleep Quality": ["en": "Sleep Quality", "zh-Hans": "睡眠质量"],
    "Stress": ["en": "Stress", "zh-Hans": "压力"],
    "Sleep": ["en": "Sleep", "zh-Hans": "睡眠"],
    "Poor": ["en": "Poor", "zh-Hans": "差"],
    
    // MARK: - Onboarding Steps
    "Health Check": ["en": "Health Check", "zh-Hans": "健康检查"],
    "Your safety matters. We'll adjust your plan accordingly.": ["en": "Your safety matters. We'll adjust your plan accordingly.", "zh-Hans": "你的安全最重要。我们会据此调整你的方案。"],
    "Do you have any of these conditions?": ["en": "Do you have any of these conditions?", "zh-Hans": "你有以下情况吗？"],
    "How are you doing?": ["en": "How are you doing?", "zh-Hans": "你最近状态怎么样？"],
    "Stress and sleep affect fasting tolerance. We'll calibrate your plan.": ["en": "Stress and sleep affect fasting tolerance. We'll calibrate your plan.", "zh-Hans": "压力和睡眠会影响断食耐受力。我们会据此校准你的方案。"],
    "Smart Schedule": ["en": "Smart Schedule", "zh-Hans": "智能排期"],
    "Connect your calendar for personalized daily suggestions.": ["en": "Connect your calendar for personalized daily suggestions.", "zh-Hans": "连接日历，获取个性化的每日断食建议。"],
    "Connect Calendar": ["en": "Connect Calendar", "zh-Hans": "连接日历"],
    "Free": ["en": "Free", "zh-Hans": "空闲"],
    "No events this week": ["en": "No events this week", "zh-Hans": "本周没有事件"],
    "events": ["en": "events", "zh-Hans": "个事件"],
    "Safety Notes": ["en": "Safety Notes", "zh-Hans": "安全提示"],
    
    // MARK: - Safety Messages
    "safety_blocked_title": ["en": "Not Recommended", "zh-Hans": "不建议断食"],
    "safety_eating_disorder": ["en": "Intermittent fasting is not recommended for those with eating disorder history. Please consult a healthcare professional.", "zh-Hans": "有进食障碍史的人不建议进行间歇性断食。请咨询医疗专业人士。"],
    "safety_pregnant": ["en": "Fasting is not safe during pregnancy or while nursing. Please consult your doctor.", "zh-Hans": "怀孕或哺乳期间断食不安全。请咨询您的医生。"],
    "safety_diabetes": ["en": "Diabetes: Plan limited to 16:8 max. Monitor blood sugar closely.", "zh-Hans": "糖尿病：方案限制在16:8以内。请密切监测血糖。"],
    "safety_thyroid": ["en": "Thyroid: Extended fasting may affect thyroid function. We'll keep it moderate.", "zh-Hans": "甲状腺：长时间断食可能影响甲状腺功能。我们会保持适度。"],
    "safety_heart": ["en": "Heart condition: Intense fasting can affect electrolytes. Reduced intensity.", "zh-Hans": "心脏疾病：高强度断食可能影响电解质。已降低强度。"],
    "safety_medication": ["en": "Some medications require food. Check with your doctor about fasting windows.", "zh-Hans": "某些药物需要随餐服用。请与医生确认断食窗口。"],
    "safety_elderly": ["en": "Age 65+: Higher protein targets and gentler fasting.", "zh-Hans": "65岁以上：更高蛋白质目标和更温和的断食。"],
    "safety_underweight": ["en": "BMI < 18.5: Fasting may cause further weight loss.", "zh-Hans": "BMI < 18.5：断食可能导致体重进一步下降。"],
    "safety_stress_sleep": ["en": "High stress + poor sleep: Starting gentle. Cortisol is already elevated.", "zh-Hans": "高压力+差睡眠：从温和方案开始。皮质醇已经偏高。"],
    "safety_contraindication_warning": ["en": "This condition may make fasting unsafe. We recommend consulting your doctor.", "zh-Hans": "这种情况下断食可能不安全。建议先咨询医生。"],
    "safety_reduced_intensity_note": ["en": "We'll adjust your plan to a gentler intensity.", "zh-Hans": "根据你的健康情况，我们会调整为更温和的方案。"],
    "mood_gentle_note": ["en": "We'll start you with a gentler plan. Your wellbeing comes first.", "zh-Hans": "我们会给你安排更温和的方案。你的身心状态最重要。"],
    
    // MARK: - Calendar / Schedule
    "calendar_permission_desc": ["en": "We'll read your calendar to suggest optimal fasting windows around your events.", "zh-Hans": "我们会读取你的日历，根据日程推荐最佳断食窗口。"],
    "calendar_privacy_note": ["en": "Your calendar data stays on your device. We never upload it.", "zh-Hans": "你的日历数据仅存储在本地，不会上传。"],
    "calendar_connect_plan_desc": ["en": "Connect your calendar to see personalized fasting windows for each day.", "zh-Hans": "连接日历，查看每天的个性化断食窗口建议。"],
    "schedule_preview_note": ["en": "These suggestions update weekly based on your calendar.", "zh-Hans": "这些建议每周根据日历变化自动更新。"],
    "All day": ["en": "All day", "zh-Hans": "全天"],
    "Appearance": ["en": "Appearance", "zh-Hans": "外观"],
    "System": ["en": "System", "zh-Hans": "跟随系统"],
    "Light": ["en": "Light", "zh-Hans": "浅色"],
    "Dark": ["en": "Dark", "zh-Hans": "深色"],
    "Adopt": ["en": "Adopt", "zh-Hans": "采纳"],
    "schedule_default": ["en": "Standard plan — no schedule conflicts.", "zh-Hans": "标准方案——没有日程冲突。"],
    "schedule_meal_conflict": ["en": "Adjusted for your meal event. Eating window widened.", "zh-Hans": "根据用餐安排调整。进食窗口已加宽。"],
    "schedule_meal_adjusted": ["en": "Shifted to cover your meal time.", "zh-Hans": "已调整以覆盖用餐时间。"],
    "schedule_free_weekend": ["en": "Free day — great for a deeper fast!", "zh-Hans": "空闲日——适合尝试更深度的断食！"],
    "schedule_consecutive_social": ["en": "Multiple social days. Stick to baseline — don't overcompensate.", "zh-Hans": "连续社交活动。保持基线——不要过度补偿。"],
    "schedule_reduced_intensity": ["en": "Gentle mode — your body needs recovery.", "zh-Hans": "温和模式——身体需要恢复。"],

    // ========== Wellbeing Check-in (Buchinger) ==========
    
    // Greeting
    "checkin_greeting_early": ["en": "How are you settling in?", "zh-Hans": "感觉怎么样？"],
    "checkin_greeting_mid": ["en": "How's your body and mind?", "zh-Hans": "身心状态如何？"],
    "checkin_greeting_late": ["en": "You've come a long way. How are you?", "zh-Hans": "已经走了很远。你还好吗？"],
    "checkin_greeting_extended": ["en": "Deep into the journey. Let's check in.", "zh-Hans": "旅程深处。让我们看看你的状态。"],
    "checkin_hours": ["en": "Hour %d of your fast", "zh-Hans": "断食第 %d 小时"],
    
    // Body (PWB)
    "checkin_body_title": ["en": "Body", "zh-Hans": "身体"],
    "checkin_body_question": ["en": "How does your body feel right now?", "zh-Hans": "现在身体感觉怎么样？"],
    "checkin_body_low_hint": ["en": "Low energy is common during metabolic transition. Electrolytes and rest help.", "zh-Hans": "代谢切换期能量低是正常的。补充电解质和休息会有帮助。"],
    
    // Mind (EWB)
    "checkin_mind_title": ["en": "Mind", "zh-Hans": "心理"],
    "checkin_mind_question": ["en": "How's your mood and mental clarity?", "zh-Hans": "心情和思维清晰度怎么样？"],
    "checkin_mind_low_hint": ["en": "Emotional dips around 24-48h are linked to cortisol shifts. This is temporary.", "zh-Hans": "24-48小时的情绪低落与皮质醇波动有关。这是暂时的。"],
    
    // Wellbeing levels
    "wellbeing_excellent": ["en": "Excellent", "zh-Hans": "极好"],
    "wellbeing_good": ["en": "Good", "zh-Hans": "不错"],
    "wellbeing_moderate": ["en": "Moderate", "zh-Hans": "一般"],
    "wellbeing_poor": ["en": "Poor", "zh-Hans": "较差"],
    "wellbeing_veryPoor": ["en": "Very Poor", "zh-Hans": "很差"],
    
    // Hunger
    "checkin_hunger_question": ["en": "Feeling hungry?", "zh-Hans": "有饥饿感吗？"],
    "checkin_yes": ["en": "Yes", "zh-Hans": "有"],
    "checkin_no": ["en": "No", "zh-Hans": "没有"],
    
    // Hunger guidance (research: 93.2% hunger disappears after initial phase)
    "hunger_guidance_early": ["en": "Hunger in the first few hours is usually habit, not need. It often fades in 15-20 minutes. Try warm water or tea.", "zh-Hans": "最初几小时的饥饿感通常是习惯，不是真正的需要。一般15-20分钟后会消退。试试温水或茶。"],
    "hunger_guidance_mid": ["en": "Your body is at the metabolic crossover. Hunger waves are normal and they pass. Research shows 93% of fasters report hunger vanishing after this phase.", "zh-Hans": "身体正处于代谢切换点。饥饿感一阵一阵的，会过去的。研究显示93%的断食者在这个阶段后饥饿感完全消失。"],
    "hunger_guidance_late": ["en": "Still hungry this far in? Check hydration and electrolytes first. True hunger at this stage is uncommon — it might be thirst or boredom.", "zh-Hans": "到这个阶段还饿？先检查水分和电解质。这个阶段真正的饥饿不常见——可能是口渴或无聊。"],
    "hunger_guidance_extended": ["en": "Persistent hunger beyond 18h deserves attention. Have some salt water. If it doesn't fade, your body might be asking you to refeed.", "zh-Hans": "超过18小时持续饥饿需要注意。喝点盐水。如果不消退，身体可能在要求进食。"],
    
    // Symptoms (new ones)
    "nausea": ["en": "Nausea", "zh-Hans": "恶心"],
    "muscleAche": ["en": "Muscle ache", "zh-Hans": "肌肉酸痛"],
    "coldHands": ["en": "Cold hands", "zh-Hans": "手脚冰凉"],
    "restless": ["en": "Restless", "zh-Hans": "坐立不安"],
    "calm": ["en": "Calm", "zh-Hans": "平静"],
    "lightBody": ["en": "Light body", "zh-Hans": "身体轻盈"],
    "checkin_symptoms_title": ["en": "Anything else to note?", "zh-Hans": "还有什么想记录的？"],
    "checkin_symptoms_physical": ["en": "Physical", "zh-Hans": "身体感受"],
    "checkin_symptoms_mental": ["en": "Mental", "zh-Hans": "心理感受"],
    
    // Symptom advice (new)
    "symptom_advice_nausea": ["en": "Nausea during fasting is often from stomach acid on an empty stomach. Try small sips of warm water or ginger tea.", "zh-Hans": "断食期间恶心通常是空腹胃酸引起的。试试小口温水或姜茶。"],
    "symptom_advice_muscleAche": ["en": "Muscle soreness can be from electrolyte shifts. Magnesium-rich mineral water or a pinch of salt in water helps.", "zh-Hans": "肌肉酸痛可能是电解质变化引起的。含镁矿泉水或水里加一小撮盐会有帮助。"],
    "symptom_advice_coldHands": ["en": "Cold extremities are normal — your body is conserving energy by reducing peripheral blood flow. It's a sign the metabolic switch is happening.", "zh-Hans": "手脚冰凉是正常的——身体在通过减少外周血流来节省能量。这是代谢切换正在发生的信号。"],
    "symptom_advice_restless": ["en": "Restlessness is often from elevated adrenaline — your body's natural response to fasting. A walk or light stretching can channel this energy.", "zh-Hans": "坐立不安通常是肾上腺素升高——身体对断食的自然反应。散步或轻度拉伸可以释放这股能量。"],
    
    // Positive reinforcement (new)
    "companion_positive_serene": ["en": "Calm and light — this is the fasting sweet spot. Your body has found its rhythm. Enjoy this feeling.", "zh-Hans": "平静且轻盈——这是断食的甜蜜点。身体找到了节奏。享受这种感觉。"],
    "companion_positive_calm": ["en": "That sense of calm is real — elevated GABA and ketones create a natural tranquility. Your brain is thriving.", "zh-Hans": "那种平静感是真实的——升高的GABA和酮体创造了自然的宁静。大脑状态很好。"],
    "companion_positive_light": ["en": "Feeling light is a sign your body has efficiently switched to fat metabolism. Less inflammation, less water retention.", "zh-Hans": "感觉轻盈说明身体已经高效切换到脂肪代谢。炎症减少，水肿减少。"],
    "companion_positive_general": ["en": "Your body is sending positive signals. Trust the process — you're doing great.", "zh-Hans": "身体在发出积极信号。相信过程——你做得很好。"],
    
    // Divergence (body vs mind mismatch)
    "companion_diverge_body_strong": ["en": "Interesting — your body feels better than your mind. Emotional dips during fasting are biochemical, not personal. Try a short walk or call a friend.", "zh-Hans": "有意思——身体感觉比心理好。断食期间的情绪低落是生化反应，不是你的问题。试试短暂散步或跟朋友聊天。"],
    "companion_diverge_mind_strong": ["en": "Your mind is clear but your body is struggling. This often happens during the metabolic transition. Focus on hydration and electrolytes — the body will catch up.", "zh-Hans": "思维很清晰但身体在挣扎。这在代谢过渡期很常见。注意补水和电解质——身体会跟上来的。"],
    
    // Safety
    "companion_safety_critical": ["en": "⚠️ Your wellbeing score is very low. Please consider ending your fast. No fast is worth compromising your health. There will always be another chance.", "zh-Hans": "⚠️ 你的身心评分很低。请考虑结束断食。没有任何一次断食值得牺牲健康。永远会有下一次机会。"],
    "companion_safety_low": ["en": "Your scores suggest you're having a tough time. Remember: listening to your body is not giving up — it's wisdom. Consider a shorter fast today.", "zh-Hans": "你的评分显示状态不太好。记住：听从身体不是放弃——而是智慧。考虑今天缩短断食时间。"],
    
    // Ketone
    "checkin_ketone_title": ["en": "Urine Ketones", "zh-Hans": "尿酮监测"],
    "checkin_optional": ["en": "Optional", "zh-Hans": "选填"],
    "checkin_ketone_question": ["en": "If you tested, match the color on your strip:", "zh-Hans": "如果你做了检测，选择试纸对应的颜色："],
    "ketone_negative": ["en": "Negative — not yet in ketosis", "zh-Hans": "阴性——尚未进入酮症"],
    "ketone_trace": ["en": "Trace — ketosis is beginning", "zh-Hans": "微量——酮症正在启动"],
    "ketone_small": ["en": "Small — light nutritional ketosis", "zh-Hans": "少量——轻度营养性酮症"],
    "ketone_moderate": ["en": "Moderate — optimal fasting ketosis", "zh-Hans": "中等——最佳断食酮症"],
    "ketone_large": ["en": "Large — deep ketosis", "zh-Hans": "大量——深度酮症"],
    "ketone_veryLarge": ["en": "Very large — monitor closely", "zh-Hans": "极大量——需密切关注"],
    
    // Ketone guidance
    "ketone_guidance_negative_early": ["en": "No ketones yet — perfectly normal. Your body is still using glycogen stores. Ketones typically appear after 12-16 hours.", "zh-Hans": "还没有酮体——完全正常。身体还在消耗糖原储备。酮体通常在12-16小时后出现。"],
    "ketone_guidance_negative_late": ["en": "No ketones after 12+ hours is uncommon. Ensure you haven't consumed anything with calories. Some people naturally produce less urinary ketones.", "zh-Hans": "12小时后还没有酮体不太常见。确认没有摄入任何有热量的东西。有些人天然尿酮产生较少。"],
    "ketone_guidance_trace": ["en": "Ketosis is starting! Your liver is beginning to produce ketone bodies. BHB (the brain's premium fuel) is on its way.", "zh-Hans": "酮症正在启动！肝脏开始产生酮体。BHB（大脑的优质燃料）正在路上。"],
    "ketone_guidance_small": ["en": "You're in light nutritional ketosis. Fat burning is active. Many people start feeling mental clarity around this level.", "zh-Hans": "你已进入轻度营养性酮症。脂肪燃烧已激活。很多人在这个水平开始感受到思维清晰。"],
    "ketone_guidance_moderate": ["en": "Optimal fasting zone! Autophagy is likely active. This is where the Buchinger studies showed the steepest wellbeing improvements.", "zh-Hans": "最佳断食区间！细胞自噬可能已激活。布辛格研究显示这个区间身心福祉改善最显著。"],
    "ketone_guidance_high": ["en": "Deep ketosis — powerful for autophagy but ensure adequate hydration and electrolytes. If you feel unwell, please end the fast.", "zh-Hans": "深度酮症——对细胞自噬很强效，但请确保充足的水分和电解质。如果感觉不适，请结束断食。"],
    
    // Ketone info sheet
    "ketone_info_title": ["en": "About Urine Ketones", "zh-Hans": "关于尿酮检测"],
    "ketone_info_what": ["en": "During fasting, your liver converts fat into ketone bodies (BHB, AcAc, acetone) as alternative fuel. Urine test strips (like Ketostix) detect acetoacetate — an overflow indicator of ketosis.\n\nThis is a simple way to confirm your body has switched to fat-burning mode. It's not a precise measurement, but a helpful directional signal.", "zh-Hans": "断食期间，肝脏将脂肪转化为酮体（BHB、AcAc、丙酮）作为替代燃料。尿酮试纸（如Ketostix）检测乙酰乙酸——酮症的溢出指标。\n\n这是确认身体已切换到脂肪燃烧模式的简单方法。不是精确测量，但是很有用的方向性信号。"],
    "ketone_info_guide_title": ["en": "Color Guide", "zh-Hans": "颜色对照"],
    "ketone_info_tips": ["en": "Tips: Test in the morning for most consistent readings. Hydration affects concentration — very dilute urine may show lower readings even in ketosis.", "zh-Hans": "小贴士：早晨检测结果最稳定。水分影响浓度——即使在酮症中，尿液很稀也可能显示较低读数。"],
    "ketone_info_safety": ["en": "Very high ketone levels (large/very large) sustained for multiple days warrant medical attention, especially for people with diabetes.", "zh-Hans": "极高酮体水平（大量/极大量）持续多天需要就医，特别是糖尿病患者。"],
    
    // Check-in UI
    "checkin_guidance_title": ["en": "Your Companion Says", "zh-Hans": "陪伴指导"],
    "checkin_save": ["en": "Record", "zh-Hans": "记录"],
    "mood_checkin_title": ["en": "How are you feeling?", "zh-Hans": "你现在感觉如何？"],
    "mood_checkin_subtitle": ["en": "Tap to check in — we're here for you", "zh-Hans": "点击记录——我们陪着你"],


    // ========== Onboarding Flow ==========
    
    "onboarding_title": ["en": "Your Plan", "zh-Hans": "你的方案"],
    "onboarding_next": ["en": "Continue", "zh-Hans": "继续"],
    "onboarding_back": ["en": "Back", "zh-Hans": "返回"],
    "onboarding_skip": ["en": "Skip this step", "zh-Hans": "跳过这一步"],
    "onboarding_create": ["en": "Start My Journey", "zh-Hans": "开始我的旅程"],
    
    // Step 1: Body
    "onboarding_body_title": ["en": "Let's get to know you", "zh-Hans": "让我们了解你"],
    "onboarding_body_subtitle": ["en": "This helps us calculate your nutritional needs and design a safe plan.", "zh-Hans": "这帮助我们计算你的营养需求，设计安全的方案。"],
    "onboarding_sex": ["en": "Biological Sex", "zh-Hans": "生理性别"],
    "onboarding_age": ["en": "Age", "zh-Hans": "年龄"],
    "onboarding_height": ["en": "Height", "zh-Hans": "身高"],
    "onboarding_weight": ["en": "Weight", "zh-Hans": "体重"],
    "onboarding_bmi_under": ["en": "Underweight", "zh-Hans": "偏瘦"],
    "onboarding_bmi_normal": ["en": "Normal", "zh-Hans": "正常"],
    "onboarding_bmi_over": ["en": "Overweight", "zh-Hans": "偏重"],
    "onboarding_bmi_obese": ["en": "Obese", "zh-Hans": "肥胖"],
    "onboarding_elderly_tip": ["en": "At 65+, muscle preservation is critical. We'll ensure your protein target is at least 1.2g/kg to prevent sarcopenia.", "zh-Hans": "65岁以上，肌肉保护至关重要。我们会确保蛋白质目标至少1.2g/kg，预防肌少症。"],
    "onboarding_protein_preview": ["en": "Based on your weight, your daily protein target will be %@ — this prevents muscle loss during fasting.", "zh-Hans": "根据你的体重，每日蛋白质目标为 %@——这能防止断食期间肌肉流失。"],
    
    // Step 2: Health
    "onboarding_health_title": ["en": "Your safety comes first", "zh-Hans": "你的安全最重要"],
    "onboarding_health_subtitle": ["en": "We'll adjust your plan based on your health. Select any that apply.", "zh-Hans": "我们会根据你的健康状况调整方案。选择符合的选项。"],
    "onboarding_contraindication_note": ["en": "Some conditions require medical guidance before fasting. We'll recommend a gentler approach or suggest consulting your doctor.", "zh-Hans": "某些状况在断食前需要医疗指导。我们会推荐更温和的方案，或建议咨询医生。"],
    "onboarding_reduced_note": ["en": "We'll reduce fasting intensity to keep you safe. Shorter windows, gentler transitions.", "zh-Hans": "我们会降低断食强度来保护你。更短的窗口，更温和的过渡。"],
    "onboarding_health_clear": ["en": "Great — no health concerns. You're cleared for the full range of fasting plans.", "zh-Hans": "很好——没有健康顾虑。你可以使用全部断食方案。"],
    
    // Step 3: Lifestyle
    "onboarding_lifestyle_title": ["en": "Your daily life", "zh-Hans": "你的日常生活"],
    "onboarding_lifestyle_subtitle": ["en": "Activity level affects how many calories you need and how your body responds to fasting.", "zh-Hans": "运动水平影响你需要多少热量，以及身体对断食的反应。"],
    "onboarding_activity": ["en": "Activity Level", "zh-Hans": "运动水平"],
    "onboarding_diet": ["en": "Diet Preference", "zh-Hans": "饮食偏好"],
    "onboarding_active_tip": ["en": "Active lifestyles need more protein (1.4-1.6g/kg) to maintain muscle. We'll increase your target accordingly.", "zh-Hans": "活跃的生活方式需要更多蛋白质(1.4-1.6g/kg)来维持肌肉。我们会相应提高你的目标。"],
    "onboarding_vegan_tip": ["en": "Plant protein has lower bioavailability. We'll set protein at the higher end and recommend B12, vitamin D, calcium, iron, zinc, and omega-3 supplementation.", "zh-Hans": "植物蛋白生物利用率较低。我们会将蛋白质设在高端，并建议补充B12、维D、钙、铁、锌和omega-3。"],
    
    // Step 4: Mood & Stress
    "onboarding_mood_title": ["en": "How are you feeling?", "zh-Hans": "你最近状态怎么样？"],
    "onboarding_mood_subtitle": ["en": "Stress and sleep directly affect fasting tolerance. We'll calibrate your plan to match.", "zh-Hans": "压力和睡眠直接影响断食耐受度。我们会校准方案来匹配你的状态。"],
    "onboarding_stress": ["en": "Stress Level", "zh-Hans": "压力水平"],
    "onboarding_sleep": ["en": "Sleep Quality", "zh-Hans": "睡眠质量"],
    "onboarding_stress_sleep_tip": ["en": "High stress or poor sleep raises cortisol, making fasting harder. We'll start you with a gentler plan and build up gradually.", "zh-Hans": "高压力或睡眠差会升高皮质醇，让断食更困难。我们会从更温和的方案开始，循序渐进。"],
    
    // Step 5: Goal
    "onboarding_goal_title": ["en": "What's your goal?", "zh-Hans": "你的目标是什么？"],
    "onboarding_goal_subtitle": ["en": "This determines fasting intensity and how long your plan will run.", "zh-Hans": "这决定了断食强度和方案持续时间。"],
    "onboarding_goal_fatloss_tip": ["en": "Fat burning truly begins 12 hours after your last meal. With 16:8, you get ~4 hours of active fat burning daily. Clinical studies show 8-12 weeks for meaningful results (>5% body weight).", "zh-Hans": "真正的脂肪燃烧在最后一餐12小时后开始。16:8方案每天有约4小时活跃燃脂。临床研究显示8-12周可获得有意义的减重效果(>5%体重)。"],
    "onboarding_goal_metabolic_tip": ["en": "Fasting improves insulin sensitivity and blood sugar regulation. The metabolic switch happens around 12-16 hours — that's when your body shifts from glucose to fat fuel.", "zh-Hans": "断食改善胰岛素敏感性和血糖调节。代谢切换在12-16小时左右发生——此时身体从葡萄糖燃料转向脂肪燃料。"],
    "onboarding_goal_clarity_tip": ["en": "Ketone bodies (BHB) are a premium brain fuel. Most people notice mental clarity improvements after 14-16 hours of fasting, when ketone production ramps up.", "zh-Hans": "酮体(BHB)是大脑的优质燃料。大多数人在断食14-16小时后注意到思维清晰度提升，此时酮体产生加速。"],
    "onboarding_goal_longevity_tip": ["en": "Autophagy — cellular self-cleaning — accelerates after 16-18 hours. This process recycles damaged proteins and is linked to longevity in numerous studies.", "zh-Hans": "细胞自噬——细胞自我清洁——在16-18小时后加速。这个过程回收受损蛋白质，众多研究表明与长寿相关。"],
    "onboarding_goal_gut_tip": ["en": "Your gut lining renews every 3-5 days. Fasting gives the digestive system a rest, reducing inflammation and promoting microbiome diversity.", "zh-Hans": "肠道内壁每3-5天更新一次。断食让消化系统得到休息，减少炎症并促进肠道菌群多样性。"],
    
    // Step 6: Calendar
    "onboarding_calendar_title": ["en": "Smart Scheduling", "zh-Hans": "智能日程"],
    "onboarding_calendar_subtitle": ["en": "Connect your calendar so we can adjust fasting around your social events.", "zh-Hans": "连接日历，我们可以根据你的社交活动调整断食安排。"],
    "onboarding_calendar_desc": ["en": "We'll detect meals, dinners, and social events to automatically adjust your fasting windows. Your data stays on your device.", "zh-Hans": "我们会检测聚餐和社交活动，自动调整断食窗口。数据仅保存在你的设备上。"],
    "onboarding_calendar_connect": ["en": "Connect Calendar", "zh-Hans": "连接日历"],
    "onboarding_calendar_privacy": ["en": "We only read event times and titles. Nothing leaves your device.", "zh-Hans": "我们只读取事件时间和标题。数据不会离开你的设备。"],
    "onboarding_calendar_connected_tip": ["en": "We'll automatically adjust your fasting plan on days with social events — shorter windows when you need flexibility.", "zh-Hans": "有社交活动的日子，我们会自动调整断食方案——需要灵活性时缩短窗口。"],
    
    // Step 7: Summary
    "onboarding_summary_title": ["en": "Your journey begins", "zh-Hans": "旅程开始了"],
    "onboarding_summary_subtitle": ["en": "Here's what we've designed for you, based on everything you shared.", "zh-Hans": "基于你分享的信息，这是我们为你设计的方案。"],
    "onboarding_your_plan": ["en": "Your Fasting Plan", "zh-Hans": "你的断食方案"],
    "onboarding_plan_duration": ["en": "%d-week program", "zh-Hans": "%d 周计划"],
    "onboarding_per_week": ["en": "per week", "zh-Hans": "每周"],
    "onboarding_nutrition": ["en": "Daily Nutrition", "zh-Hans": "每日营养"],
    "onboarding_calories": ["en": "Calories", "zh-Hans": "热量"],
    "onboarding_deficit": ["en": "Deficit", "zh-Hans": "热量缺口"],
    "onboarding_protein": ["en": "Protein", "zh-Hans": "蛋白质"],
    "onboarding_carb_fiber": ["en": "Carb:Fiber", "zh-Hans": "碳水:纤维"],
    "onboarding_your_profile": ["en": "Your Profile", "zh-Hans": "你的档案"],
    "onboarding_closing_message": ["en": "Remember: every fast teaches your body something. We'll be with you every step — adjusting, guiding, and celebrating your progress. You're not doing this alone.", "zh-Hans": "记住：每次断食都在教会身体一些东西。我们会陪你走每一步——调整、指导、庆祝你的进步。你不是一个人在做这件事。"],


    // ========== Plate Themes ==========
    
    "theme_classic": ["en": "Classic", "zh-Hans": "经典白瓷"],
    "theme_ironwood": ["en": "Ironwood", "zh-Hans": "铸铁木桌"],
    "theme_marble": ["en": "Marble", "zh-Hans": "大理石"],
    "theme_washi": ["en": "Washi", "zh-Hans": "和纸木盘"],
    "theme_section_title": ["en": "Table Setting", "zh-Hans": "餐桌布置"],
    "theme_current": ["en": "Current", "zh-Hans": "当前"],

    "theme_minimal": ["en": "Minimal", "zh-Hans": "极简"],
    "plan_suggested_window": ["en": "Suggested: %@ — eating window %@", "zh-Hans": "建议: %@ — 进食窗口 %@"],
    "edit_goal": ["en": "Edit Goal", "zh-Hans": "修改目标"],
    "goal_current": ["en": "Current Goal", "zh-Hans": "当前目标"],
    "save": ["en": "Save", "zh-Hans": "保存"],
    "plan_free_day": ["en": "No events — great day for a longer fast!", "zh-Hans": "没有活动——适合挑战更长的断食！"],
    "plan_empty_desc": ["en": "Create a personalized fasting plan\nbased on your body and goals.", "zh-Hans": "根据你的身体状况和目标\n创建个性化断食方案"],
    "plan_week_of": ["en": "Week %d of %d", "zh-Hans": "第 %d / %d 周"],
    "plan_weeks_left": ["en": "%d weeks left", "zh-Hans": "还剩 %d 周"],
    "kg/wk": ["en": "kg/wk", "zh-Hans": "kg/周"],
    "plan_view_all": ["en": "View All", "zh-Hans": "查看全部"],
    "plan_clear_schedule": ["en": "Clear schedule ahead — perfect for consistency!", "zh-Hans": "接下来日程空闲——正适合坚持断食！"],
    "health_connect_desc": ["en": "Connect Apple Health to track your exercise and calorie burn.", "zh-Hans": "连接 Apple 健康以追踪运动和消耗"],
    "Upcoming": ["en": "Upcoming", "zh-Hans": "接下来"],
    "Calendar": ["en": "Calendar", "zh-Hans": "日历"],

    // MARK: - Plan Phase Greetings & Insights
    "plan_phase_adaptation_greeting": ["en": "Your body is adapting — be patient with yourself 🌱", "zh-Hans": "身体正在适应中——对自己耐心一点 🌱"],
    "plan_phase_fat_adaptation_greeting": ["en": "Fat-burning mode is kicking in 🔥", "zh-Hans": "脂肪燃烧模式已启动 🔥"],
    "plan_phase_deep_repair_greeting": ["en": "Deep cellular repair is underway 🧬", "zh-Hans": "深层细胞修复进行中 🧬"],
    "plan_phase_consolidation_greeting": ["en": "You've built a strong foundation — keep going 💪", "zh-Hans": "你已经打下了坚实的基础——继续加油 💪"],
    "plan_phase_adaptation_insight": ["en": "Hunger peaks usually fade after 3-4 days. Your ghrelin rhythm is resetting — this is the hardest part, and it gets easier.", "zh-Hans": "饥饿感高峰通常在 3-4 天后消退。你的饥饿素节律正在重置——这是最难的阶段，之后会越来越轻松。"],
    "plan_phase_fat_adaptation_insight": ["en": "Your body is shifting from glucose to fat as its primary fuel. You may notice steadier energy and fewer cravings.", "zh-Hans": "你的身体正从葡萄糖供能转向脂肪供能。你可能会感到精力更稳定，渴望减少。"],
    "plan_phase_deep_repair_insight": ["en": "Autophagy is ramping up — your cells are clearing out damaged components and renewing themselves.", "zh-Hans": "自噬作用正在加速——你的细胞正在清除受损成分并自我更新。"],
    "plan_phase_consolidation_insight": ["en": "Your metabolic flexibility is strong now. Focus on consistency and listen to your body's signals.", "zh-Hans": "你的代谢灵活性已经很强了。专注于保持一致，倾听身体的信号。"],

    // MARK: - Plan Exercise Guidance
    "plan_exercise_adaptation_title": ["en": "Gentle Movement", "zh-Hans": "轻柔运动"],
    "plan_exercise_adaptation_detail": ["en": "Walking and light stretching are ideal while your body adjusts. Avoid intense workouts for now.", "zh-Hans": "身体调整期间，散步和轻度拉伸最合适。暂时避免高强度训练。"],
    "plan_exercise_fat_adaptation_title": ["en": "Moderate Cardio", "zh-Hans": "中等有氧"],
    "plan_exercise_fat_adaptation_detail": ["en": "Your body can now sustain moderate cardio. Try brisk walking, cycling, or light jogging during fasting windows.", "zh-Hans": "身体现在可以支撑中等有氧运动。可以在断食窗口尝试快走、骑车或慢跑。"],
    "plan_exercise_deep_repair_title": ["en": "Add Resistance Training", "zh-Hans": "加入力量训练"],
    "plan_exercise_deep_repair_detail": ["en": "Strength training during eating windows helps preserve lean mass. 2-3 sessions per week is optimal.", "zh-Hans": "在进食窗口进行力量训练有助于保持肌肉量。每周 2-3 次最佳。"],
    "plan_exercise_consolidation_title": ["en": "Full Training", "zh-Hans": "全面训练"],
    "plan_exercise_consolidation_detail": ["en": "Your body is fully adapted. Mix strength, cardio, and flexibility training as you like.", "zh-Hans": "身体已完全适应。可以随意混合力量、有氧和柔韧性训练。"],

    // MARK: - Plan Food Groups
    "plan_food_protein": ["en": "Protein", "zh-Hans": "蛋白质"],
    "plan_food_protein_detail": ["en": "Eggs, chicken, beef, fish, tofu — prioritize fatty fish 2-3×/week for omega-3", "zh-Hans": "鸡蛋、鸡肉、牛肉、鱼、豆腐——优先每周 2-3 次富脂鱼补充 omega-3"],
    "plan_food_protein_detail_vegan": ["en": "Tofu, tempeh, legumes, seitan — combine sources for complete amino acids", "zh-Hans": "豆腐、天贝、豆类、面筋——搭配食用以获取完整氨基酸"],
    "plan_food_protein_science": ["en": "1.2-1.6g/kg body weight preserves lean mass during fasting (Mettler et al. 2010)", "zh-Hans": "断食期间每公斤体重摄入 1.2-1.6g 蛋白质可保持肌肉量 (Mettler et al. 2010)"],
    "plan_food_protein_science_vegan": ["en": "Plant proteins need 10-20% higher intake to match animal protein bioavailability (van Vliet et al. 2015)", "zh-Hans": "植物蛋白需要多摄入 10-20% 才能匹配动物蛋白的生物利用率 (van Vliet et al. 2015)"],
    "plan_food_seafood": ["en": "Seafood", "zh-Hans": "海鲜"],
    "plan_food_seafood_detail": ["en": "Salmon, sardines, shrimp — rich in omega-3 fatty acids", "zh-Hans": "三文鱼、沙丁鱼、虾——富含 omega-3 脂肪酸"],
    "plan_food_seafood_science": ["en": "2-3 servings/week of fatty fish reduces inflammation markers by 30% (Calder 2017)", "zh-Hans": "每周 2-3 份富脂鱼可降低 30% 的炎症指标 (Calder 2017)"],
    "plan_food_dairy": ["en": "Dairy", "zh-Hans": "乳制品"],
    "plan_food_dairy_detail": ["en": "Greek yogurt, kefir, cheese, milk — fermented options boost gut health", "zh-Hans": "希腊酸奶、开菲尔、奶酪、牛奶——发酵类更有益肠道健康"],
    "plan_food_dairy_science": ["en": "Fermented dairy improves gut microbiome diversity during time-restricted eating (Staudacher et al. 2020)", "zh-Hans": "发酵乳制品可改善限时进食期间的肠道微生物多样性 (Staudacher et al. 2020)"],
    "plan_food_vegetables": ["en": "Vegetables", "zh-Hans": "蔬菜"],
    "plan_food_vegetables_detail": ["en": "Leafy greens, cruciferous, colorful variety — fill half your plate", "zh-Hans": "绿叶菜、十字花科、多彩搭配——占满半盘"],
    "plan_food_vegetables_science": ["en": "Fiber from vegetables feeds beneficial gut bacteria that thrive during fasting cycles (Sonnenburg & Sonnenburg 2019)", "zh-Hans": "蔬菜纤维滋养在断食周期中活跃的有益肠道细菌 (Sonnenburg & Sonnenburg 2019)"],
    "plan_food_fruit": ["en": "Fruit", "zh-Hans": "水果"],
    "plan_food_fruit_detail": ["en": "Berries, citrus, apples — whole fruit over juice", "zh-Hans": "浆果、柑橘、苹果——吃整果不喝果汁"],
    "plan_food_fruit_science": ["en": "Berries' polyphenols enhance autophagy-related gene expression (Pietrocola et al. 2016)", "zh-Hans": "浆果的多酚可增强自噬相关基因表达 (Pietrocola et al. 2016)"],
    "plan_food_healthy_fats": ["en": "Healthy Fats", "zh-Hans": "健康脂肪"],
    "plan_food_fats_detail": ["en": "Olive oil, avocado, nuts — essential for satiety", "zh-Hans": "橄榄油、牛油果、坚果——饱腹感的关键"],
    "plan_food_fats_science": ["en": "Monounsaturated fats extend satiety and reduce post-fast overeating by 23% (Wien et al. 2013)", "zh-Hans": "单不饱和脂肪延长饱腹感，减少断食后过量进食 23% (Wien et al. 2013)"],
    "plan_food_whole_grains": ["en": "Whole Grains", "zh-Hans": "全谷物"],
    "plan_food_grains_detail": ["en": "Oats, brown rice, quinoa — slow-releasing energy for your eating window", "zh-Hans": "燕麦、糙米、藜麦——进食窗口的缓释能量来源"],
    "plan_food_grains_science": ["en": "Aim for carb-to-fiber ratio under %@ — keeps insulin response gentle (Ludwig 2002)", "zh-Hans": "碳水与纤维比控制在 %@ 以下——保持温和的胰岛素反应 (Ludwig 2002)"],
    "plan_food_subtitle": ["en": "What to eat during your eating window", "zh-Hans": "进食窗口吃什么"],
    "plan_servings_per_day": ["en": "servings/day", "zh-Hans": "份/天"],
    "plan_servings_per_week": ["en": "servings/week", "zh-Hans": "份/周"],

    // MARK: - Plan UI
    "plan_show_more": ["en": "Show More", "zh-Hans": "展开更多"],
    "plan_show_less": ["en": "Show Less", "zh-Hans": "收起"],
    "plan_carb_fiber_rule": ["en": "Keep your carb-to-fiber ratio under 8:1 for better blood sugar control.", "zh-Hans": "保持碳水与纤维比在 8:1 以下，有助于血糖控制。"],
    "plan_electrolyte_reminder": ["en": "Remember electrolytes — sodium, potassium, magnesium", "zh-Hans": "别忘了补充电解质——钠、钾、镁"],
    "plan_connect_health": ["en": "Connect Apple Health", "zh-Hans": "连接 Apple 健康"],
    "plan_calendar_connect_title": ["en": "Smart Scheduling", "zh-Hans": "智能排期"],
    "plan_calendar_connect_desc": ["en": "Connect your calendar to auto-adjust fasting around meals and events.", "zh-Hans": "连接日历，自动根据饮食和活动调整断食时间。"],
    "plan_movement_title": ["en": "Movement", "zh-Hans": "运动"],
    "plan_of_weeks": ["en": "of %d weeks", "zh-Hans": "/ %d 周"],
    "plan_streak": ["en": "🔥 %d day streak", "zh-Hans": "🔥 连续 %d 天"],
    "plan_weekly_completion": ["en": "✅ %d fasts this week", "zh-Hans": "✅ 本周完成 %d 次"],
    "plan_your_rhythm": ["en": "Your Rhythm", "zh-Hans": "你的节奏"],
    // MARK: - Auth / Welcome
    "auth_welcome_title": ["en": "Fasting", "zh-Hans": "空盘"],
    "auth_welcome_subtitle": ["en": "A smarter way to fast,\ntailored to your body.", "zh-Hans": "更聪明的断食方式，\n为你的身体量身定制。"],
    "auth_feature_timer": ["en": "Smart Timer", "zh-Hans": "智能计时"],
    "auth_feature_timer_desc": ["en": "Track your fasting windows with precision", "zh-Hans": "精确追踪你的断食窗口"],
    "auth_feature_insights": ["en": "Body Insights", "zh-Hans": "身体洞察"],
    "auth_feature_insights_desc": ["en": "Personalized plans based on your physiology", "zh-Hans": "基于你的生理状态定制方案"],
    "auth_feature_sync": ["en": "Seamless Sync", "zh-Hans": "无缝同步"],
    "auth_feature_sync_desc": ["en": "Your data, everywhere — powered by iCloud", "zh-Hans": "你的数据随处可用——由 iCloud 驱动"],
    "auth_skip": ["en": "Continue without signing in", "zh-Hans": "不登录，直接使用"],
    "auth_privacy_note": ["en": "We only use your Apple ID to sync your data. No tracking, no ads.", "zh-Hans": "我们仅使用你的 Apple ID 同步数据。无追踪，无广告。"],
    // MARK: - Plan Food Serving Sizes (DGA 2025-2030)
    "plan_food_protein_serving_size": ["en": "1 serving = 85g (3oz) cooked meat/fish, 1 egg, ¼ cup beans, or 30g nuts", "zh-Hans": "1 份 = 85g 熟肉/鱼、1 个鸡蛋、¼ 杯豆类或 30g 坚果"],
    "plan_food_seafood_serving_size": ["en": "1 serving = 115g (4oz) cooked fish or shellfish", "zh-Hans": "1 份 = 115g 熟鱼或贝类"],
    "plan_food_dairy_serving_size": ["en": "1 serving = 240ml milk, 170g yogurt, or 45g cheese", "zh-Hans": "1 份 = 240ml 牛奶、170g 酸奶或 45g 奶酪"],
    "plan_food_vegetables_serving_size": ["en": "1 serving = 1 cup raw leafy greens or ½ cup cooked", "zh-Hans": "1 份 = 1 杯生菜叶或 ½ 杯熟蔬菜"],
    "plan_food_fruit_serving_size": ["en": "1 serving = 1 medium fruit or ½ cup berries", "zh-Hans": "1 份 = 1 个中等水果或 ½ 杯浆果"],
    "plan_food_fats_serving_size": ["en": "1 serving = 1 tbsp olive oil, ¼ avocado, or 15g nuts", "zh-Hans": "1 份 = 1 汤匙橄榄油、¼ 个牛油果或 15g 坚果"],
    "plan_food_grains_serving_size": ["en": "1 serving = 1 slice whole-grain bread or ½ cup cooked rice", "zh-Hans": "1 份 = 1 片全麦面包或 ½ 杯熟米饭"],
    "plan_food_fermented_serving_size": ["en": "1 serving = 120ml kefir, 60g kimchi, or 1 tbsp miso", "zh-Hans": "1 份 = 120ml 开菲尔、60g 泡菜或 1 汤匙味噌"],

    // MARK: - Plan Food Phase Tips
    "plan_food_protein_phase_adaptation": ["en": "Extra protein helps manage hunger during adaptation — aim for the upper range", "zh-Hans": "适应期多摄入蛋白质有助于控制饥饿感——尽量取上限"],
    "plan_food_protein_phase_repair": ["en": "Autophagy peaks now — protein timing matters. Eat protein in your first meal to break the fast gently", "zh-Hans": "自噬高峰期——蛋白质时机很重要。用蛋白质温和地开始第一餐"],
    "plan_food_fats_phase_fat_adapt": ["en": "Your body is learning to burn fat — healthy fats in your eating window help the transition", "zh-Hans": "身体正在学习燃烧脂肪——进食窗口的健康脂肪有助于过渡"],

    // MARK: - Plan Food Extras
    "plan_food_fermented": ["en": "Fermented Foods", "zh-Hans": "发酵食品"],
    "plan_food_fermented_detail": ["en": "Kimchi, sauerkraut, kefir, miso, yogurt — gut health allies", "zh-Hans": "泡菜、酸菜、开菲尔、味噌、酸奶——肠道健康的盟友"],
    "plan_food_fermented_science": ["en": "Fermented foods increase microbiome diversity by 5-10% in 10 weeks (Wastyk et al. 2021, Stanford)", "zh-Hans": "发酵食品在 10 周内可增加 5-10% 的肠道微生物多样性 (Wastyk et al. 2021, 斯坦福)"],
    "plan_food_limit_processed": ["en": "Limit ultra-processed foods and added sugars — they spike insulin and undo fasting benefits. DGA recommends <6% of calories from added sugar.", "zh-Hans": "限制超加工食品和添加糖——它们会飙升胰岛素并抵消断食的好处。DGA 建议添加糖不超过总热量的 6%。"],
]
}
