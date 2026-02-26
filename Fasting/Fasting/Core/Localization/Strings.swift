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
    "mood_very_unpleasant": ["en": "VERY UNPLEASANT", "zh-Hans": "非常不舒服"],
    "mood_very_pleasant": ["en": "VERY PLEASANT", "zh-Hans": "非常舒适"],
    "mood_question": ["en": "How are you feeling right now?", "zh-Hans": "你现在感觉怎么样？"],
    "symptom_question": ["en": "Any symptoms?", "zh-Hans": "有什么症状吗？"],
    "note_optional": ["en": "Notes (optional)", "zh-Hans": "备注（可选）"],
    "note_placeholder": ["en": "Anything you want to remember about this moment...", "zh-Hans": "想记录下这一刻的任何想法..."],
    "companion_says": ["en": "For you", "zh-Hans": "给你"],
    "checkin_hours": ["en": "You're %d hours into your fast", "zh-Hans": "你已断食 %d 小时"],
    
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
]
}
