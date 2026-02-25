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
]
}
