//
//  HolidayService.swift
//  Fasting
//
//  节假日数据 + 断食建议
//

import Foundation

// MARK: - Holiday

struct Holiday: Identifiable {
    let id = UUID()
    let name: String
    let nameZh: String
    let date: DateComponents  // month + day (solar), or computed for lunar
    let type: HolidayType
    let fastingAdvice: FastingAdvice
    
    var localizedName: String {
        LanguageManager.shared.currentLanguage == .chinese ? nameZh : name
    }
}

enum HolidayType {
    case national      // 法定节假日（放假）
    case traditional   // 传统节日
    case international // 国际节日
    case solar         // 节气
}

struct FastingAdvice {
    let emoji: String
    let summary: String
    let summaryZh: String
    let detail: String
    let detailZh: String
    let suggestedPreset: SuggestedPreset
    
    var localizedSummary: String {
        LanguageManager.shared.currentLanguage == .chinese ? summaryZh : summary
    }
    var localizedDetail: String {
        LanguageManager.shared.currentLanguage == .chinese ? detailZh : detail
    }
}

enum SuggestedPreset {
    case normal       // 正常执行
    case shorter      // 缩短断食窗口 (14:10 or 12:12)
    case skip         // 建议跳过当天
    case flexible     // 弹性，看个人
    case extended     // 节后加长
}

// MARK: - Holiday Service

enum HolidayService {
    
    // MARK: - Query
    
    /// Get holiday for a specific date, if any
    static func holiday(on date: Date) -> Holiday? {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let day = cal.component(.day, from: date)
        
        // Check solar holidays
        if let h = solarHolidays.first(where: { $0.date.month == month && $0.date.day == day }) {
            return h
        }
        
        // Check lunar holidays for the current year
        let year = cal.component(.year, from: date)
        if let lunars = lunarDatesCache[year] {
            for (key, lunarDate) in lunars {
                if cal.isDate(date, inSameDayAs: lunarDate), let h = lunarHolidayMap[key] {
                    return h
                }
            }
        }
        
        return nil
    }
    
    /// Get holidays in a date range (for calendar display)
    static func holidays(in month: Date) -> [(Date, Holiday)] {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        
        var result: [(Date, Holiday)] = []
        var d = interval.start
        while d < interval.end {
            if let h = holiday(on: d) {
                result.append((d, h))
            }
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }
        return result
    }
    
    /// Get upcoming holidays within N days (for proactive advice)
    static func upcomingHolidays(within days: Int = 7) -> [(Date, Holiday)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var result: [(Date, Holiday)] = []
        
        for offset in 0..<days {
            let d = cal.date(byAdding: .day, value: offset, to: today)!
            if let h = holiday(on: d) {
                result.append((d, h))
            }
        }
        return result
    }
    
    // MARK: - Solar Holidays (fixed date)
    
    private static let solarHolidays: [Holiday] = [
        // 元旦
        Holiday(
            name: "New Year's Day", nameZh: "元旦",
            date: DateComponents(month: 1, day: 1),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🎆",
                summary: "Flexible day",
                summaryZh: "弹性安排",
                detail: "New year celebration. A 14:10 or skip is fine — start fresh tomorrow.",
                detailZh: "新年第一天，14:10 或跳过都行。明天重新开始。",
                suggestedPreset: .flexible
            )
        ),
        // 情人节
        Holiday(
            name: "Valentine's Day", nameZh: "情人节",
            date: DateComponents(month: 2, day: 14),
            type: .international,
            fastingAdvice: FastingAdvice(
                emoji: "💝",
                summary: "Enjoy your dinner",
                summaryZh: "享受晚餐",
                detail: "If dining out, shift your eating window to evening. A shorter fast (14:10) keeps balance.",
                detailZh: "约会日，进食窗口移到晚间。14:10 保持节奏不断。",
                suggestedPreset: .shorter
            )
        ),
        // 妇女节
        Holiday(
            name: "Women's Day", nameZh: "妇女节",
            date: DateComponents(month: 3, day: 8),
            type: .international,
            fastingAdvice: FastingAdvice(
                emoji: "💐",
                summary: "Normal plan",
                summaryZh: "正常执行",
                detail: "Celebrate yourself. Normal fasting plan works perfectly.",
                detailZh: "宠爱自己的一天，正常断食即可。",
                suggestedPreset: .normal
            )
        ),
        // 清明节
        Holiday(
            name: "Qingming Festival", nameZh: "清明节",
            date: DateComponents(month: 4, day: 5),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🌿",
                summary: "Light fasting day",
                summaryZh: "轻断食日",
                detail: "Outdoor activities and family gatherings. Stick to plan if possible, or do a lighter 14:10.",
                detailZh: "踏青祭祖日，尽量保持计划，或轻松做 14:10。",
                suggestedPreset: .flexible
            )
        ),
        // 劳动节
        Holiday(
            name: "Labor Day", nameZh: "劳动节",
            date: DateComponents(month: 5, day: 1),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🏖",
                summary: "Vacation mode",
                summaryZh: "假期模式",
                detail: "Holiday week — maintain rhythm with shorter fasts. Don't guilt-trip if you skip one day.",
                detailZh: "五一假期，缩短断食窗口保持节奏。偶尔跳一天没关系。",
                suggestedPreset: .shorter
            )
        ),
        // 端午节 (approximate solar, actual is lunar 5/5)
        // Will be in lunar section
        
        // 儿童节
        Holiday(
            name: "Children's Day", nameZh: "儿童节",
            date: DateComponents(month: 6, day: 1),
            type: .international,
            fastingAdvice: FastingAdvice(
                emoji: "🧒",
                summary: "Normal plan",
                summaryZh: "正常执行",
                detail: "Stay young at heart, stay on plan.",
                detailZh: "保持童心，保持计划。",
                suggestedPreset: .normal
            )
        ),
        // 国庆节
        Holiday(
            name: "National Day", nameZh: "国庆节",
            date: DateComponents(month: 10, day: 1),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🇨🇳",
                summary: "Holiday week — be flexible",
                summaryZh: "黄金周，弹性安排",
                detail: "7-day holiday. Aim for 4-5 fasting days. Social meals are ok — shift windows, don't abandon ship.",
                detailZh: "七天长假，目标完成4-5天。聚餐时移动窗口，别完全放弃。",
                suggestedPreset: .shorter
            )
        ),
        // 平安夜 + 圣诞
        Holiday(
            name: "Christmas Eve", nameZh: "平安夜",
            date: DateComponents(month: 12, day: 24),
            type: .international,
            fastingAdvice: FastingAdvice(
                emoji: "🎄",
                summary: "Flexible",
                summaryZh: "弹性安排",
                detail: "Holiday dinner? Shift eating window to evening.",
                detailZh: "晚餐聚会？进食窗口移到晚间即可。",
                suggestedPreset: .flexible
            )
        ),
        Holiday(
            name: "Christmas", nameZh: "圣诞节",
            date: DateComponents(month: 12, day: 25),
            type: .international,
            fastingAdvice: FastingAdvice(
                emoji: "🎅",
                summary: "Skip or shorten",
                summaryZh: "跳过或缩短",
                detail: "It's Christmas. Enjoy. Get back on track the 26th.",
                detailZh: "圣诞快乐。享受就好。26号重回正轨。",
                suggestedPreset: .skip
            )
        ),
    ]
    
    // MARK: - Lunar Holidays (need year-specific dates)
    
    private static let lunarHolidayMap: [String: Holiday] = [
        "spring_eve": Holiday(
            name: "Chinese New Year's Eve", nameZh: "除夕",
            date: DateComponents(),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🧧",
                summary: "Skip fasting",
                summaryZh: "跳过断食",
                detail: "年夜饭 is sacred. Skip fasting, enjoy family. Plan resumes after Day 3.",
                detailZh: "年夜饭是团圆饭，跳过断食。初三后恢复计划。",
                suggestedPreset: .skip
            )
        ),
        "spring_1": Holiday(
            name: "Spring Festival", nameZh: "春节",
            date: DateComponents(),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🏮",
                summary: "Skip fasting",
                summaryZh: "跳过断食",
                detail: "Happy New Year! Eat well, rest well. Fasting resumes after the holiday.",
                detailZh: "新年快乐！好好吃，好好休息。假期后恢复断食。",
                suggestedPreset: .skip
            )
        ),
        "lantern": Holiday(
            name: "Lantern Festival", nameZh: "元宵节",
            date: DateComponents(),
            type: .traditional,
            fastingAdvice: FastingAdvice(
                emoji: "🏮",
                summary: "Flexible — enjoy tangyuan",
                summaryZh: "弹性安排 — 吃汤圆",
                detail: "Last day of Spring Festival celebrations. Tangyuan is high-carb — plan your window around it.",
                detailZh: "春节收官日。汤圆高碳水，安排好进食窗口。",
                suggestedPreset: .shorter
            )
        ),
        "dragon_boat": Holiday(
            name: "Dragon Boat Festival", nameZh: "端午节",
            date: DateComponents(),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🐉",
                summary: "Flexible — mind the zongzi",
                summaryZh: "弹性 — 粽子要适量",
                detail: "Zongzi are calorie-dense. One is fine within your window. Don't skip the festival.",
                detailZh: "粽子热量高，窗口内吃一个就好。别为断食错过节日。",
                suggestedPreset: .flexible
            )
        ),
        "mid_autumn": Holiday(
            name: "Mid-Autumn Festival", nameZh: "中秋节",
            date: DateComponents(),
            type: .national,
            fastingAdvice: FastingAdvice(
                emoji: "🥮",
                summary: "Shorten fast — mooncakes ahead",
                summaryZh: "缩短断食 — 月饼来了",
                detail: "One mooncake slice ≈ 400kcal. Budget wisely. A 14:10 keeps you in the game.",
                detailZh: "一块月饼 ≈ 400大卡。精打细算。14:10 保持节奏。",
                suggestedPreset: .shorter
            )
        ),
        "double_nine": Holiday(
            name: "Double Ninth Festival", nameZh: "重阳节",
            date: DateComponents(),
            type: .traditional,
            fastingAdvice: FastingAdvice(
                emoji: "🏔",
                summary: "Great fasting day",
                summaryZh: "登高好日子",
                detail: "Hiking + fasting = fat burning boost. Perfect combo.",
                detailZh: "登高+断食=加速燃脂。完美组合。",
                suggestedPreset: .normal
            )
        ),
    ]
    
    // MARK: - Lunar Date Cache
    // Pre-computed lunar → solar mappings per year
    // Update annually or compute via Chinese calendar
    
    private static let lunarDatesCache: [Int: [String: Date]] = {
        let cal = Calendar.current
        func d(_ y: Int, _ m: Int, _ d: Int) -> Date {
            cal.date(from: DateComponents(year: y, month: m, day: d))!
        }
        return [
            2025: [
                "spring_eve": d(2025, 1, 28),
                "spring_1": d(2025, 1, 29),
                "lantern": d(2025, 2, 12),
                "dragon_boat": d(2025, 5, 31),
                "mid_autumn": d(2025, 10, 6),
                "double_nine": d(2025, 10, 29),
            ],
            2026: [
                "spring_eve": d(2026, 2, 16),
                "spring_1": d(2026, 2, 17),
                "lantern": d(2026, 3, 3),
                "dragon_boat": d(2026, 6, 19),
                "mid_autumn": d(2026, 9, 25),
                "double_nine": d(2026, 10, 18),
            ],
            2027: [
                "spring_eve": d(2027, 2, 5),
                "spring_1": d(2027, 2, 6),
                "lantern": d(2027, 2, 20),
                "dragon_boat": d(2027, 6, 9),
                "mid_autumn": d(2027, 10, 15),
                "double_nine": d(2027, 11, 7),
            ],
        ]
    }()
}
