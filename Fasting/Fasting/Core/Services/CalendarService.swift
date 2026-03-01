//
//  CalendarService.swift
//  Fasting
//
//  EventKit 集成 — 读取日历事件，生成智能断食调度建议
//

import EventKit
import Foundation

private enum CalendarFormatters {
    static let weekday: DateFormatter = {
        let f = DateFormatter(); f.locale = .current; f.dateFormat = "EEE"; return f
    }()
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M/d"; return f
    }()
    static let hourMinute: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
}

// MARK: - Day Schedule

struct DaySchedule: Identifiable {
    let id = UUID()
    let date: Date
    let events: [CalendarEvent]
    let suggestion: FastingSuggestion
    
    var dayOfWeek: String {
        CalendarFormatters.weekday.string(from: date)
    }
    
    var shortDate: String {
        CalendarFormatters.shortDate.string(from: date)
    }
    
    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var hasConflicts: Bool { suggestion.hasConflict }
}

// MARK: - Calendar Event

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    
    var startHour: Int { Calendar.current.component(.hour, from: startDate) }
    var endHour: Int { Calendar.current.component(.hour, from: endDate) }
    
    var timeRange: String {
        if isAllDay { return "All day".localized }
        return "\(CalendarFormatters.hourMinute.string(from: startDate))-\(CalendarFormatters.hourMinute.string(from: endDate))"
    }
    
    var isMealRelated: Bool {
        let kw = ["dinner", "lunch", "brunch", "breakfast", "eat", "restaurant",
                   "晚餐", "午餐", "早餐", "吃饭", "聚餐", "火锅", "烧烤", "饭局"]
        let lower = title.lowercased()
        return kw.contains(where: { lower.contains($0) })
    }
    
    var isSocialEvent: Bool {
        let kw = ["party", "birthday", "celebration", "wedding", "gathering",
                   "派对", "生日", "庆祝", "婚礼", "聚会"]
        let lower = title.lowercased()
        return kw.contains(where: { lower.contains($0) })
    }
}

// MARK: - Fasting Suggestion

struct FastingSuggestion {
    let eatingWindowStart: Int
    let eatingWindowEnd: Int
    let preset: FastingPreset
    let reason: String
    let hasConflict: Bool
    
    var eatingWindowDescription: String {
        String(format: "%02d:00-%02d:00", eatingWindowStart, eatingWindowEnd)
    }
}

// MARK: - Calendar Service

@MainActor
@Observable
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var weekSchedule: [DaySchedule] = []
    var isLoading = false
    
    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .fullAccess
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        } catch {
            print("[CalendarService] Auth error: \(error)")
            return false
        }
    }
    
    // MARK: - Generate Week Schedule
    
    func generateWeekSchedule(basePlan: FastingPreset, profile: UserProfile?) async {
        guard isAuthorized else { return }
        isLoading = true
        defer { isLoading = false }
        
        // Fetch events off main thread
        let store = self.store
        let allEvents: [[(String, String, Date, Date, Bool)]] = await Task.detached {
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            var result: [[(String, String, Date, Date, Bool)]] = []
            for dayOffset in 0..<7 {
                guard let dayStart = cal.date(byAdding: .day, value: dayOffset, to: today),
                      let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else {
                    result.append([])
                    continue
                }
                let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)
                let ekEvents = store.events(matching: predicate)
                result.append(ekEvents.map { (
                    $0.eventIdentifier ?? UUID().uuidString,
                    $0.title ?? "",
                    $0.startDate,
                    $0.endDate,
                    $0.isAllDay
                )})
            }
            return result
        }.value
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var schedules: [DaySchedule] = []
        var consecutiveSocialDays = 0
        
        for dayOffset in 0..<7 {
            guard let dayStart = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            let rawEvents = dayOffset < allEvents.count ? allEvents[dayOffset] : []
            let events = rawEvents.map { CalendarEvent(id: $0.0, title: $0.1, startDate: $0.2, endDate: $0.3, isAllDay: $0.4) }
            

            
            let hasSocial = events.contains(where: { $0.isMealRelated || $0.isSocialEvent })
            if hasSocial { consecutiveSocialDays += 1 } else { consecutiveSocialDays = 0 }
            
            let suggestion = makeSuggestion(
                events: events,
                basePlan: basePlan,
                profile: profile,
                consecutiveSocialDays: consecutiveSocialDays,
                isWeekend: cal.isDateInWeekend(dayStart)
            )
            
            schedules.append(DaySchedule(date: dayStart, events: events, suggestion: suggestion))
        }
        
        weekSchedule = schedules
    }
    
    // MARK: - Smart Suggestion
    
    private func makeSuggestion(
        events: [CalendarEvent],
        basePlan: FastingPreset,
        profile: UserProfile?,
        consecutiveSocialDays: Int,
        isWeekend: Bool
    ) -> FastingSuggestion {
        let defaultWindowHours = 24 - basePlan.fastingHours
        var windowStart = 12
        var windowEnd = windowStart + defaultWindowHours
        var preset = basePlan
        var reason = "schedule_default"
        var hasConflict = false
        
        let mealEvents = events.filter { $0.isMealRelated || $0.isSocialEvent }
        
        if !mealEvents.isEmpty {
            let earliest = mealEvents.map(\.startHour).min() ?? 12
            let latestEnd = mealEvents.map(\.endHour).max() ?? 20
            
            windowStart = max(earliest - 1, 6)
            windowEnd = min(latestEnd + 1, 23)
            
            let required = windowEnd - windowStart
            if required > defaultWindowHours {
                // Downgrade intensity
                if basePlan.fastingHours >= 20 {
                    preset = .eighteen6
                } else if basePlan.fastingHours >= 18 {
                    preset = .sixteen8
                }
                hasConflict = true
                reason = "schedule_meal_conflict"
            } else {
                windowEnd = windowStart + defaultWindowHours
                reason = "schedule_meal_adjusted"
            }
        } else if events.filter({ !$0.isAllDay }).isEmpty && isWeekend {
            if basePlan.fastingHours <= 16 && !(profile?.needsReducedIntensity ?? false) {
                preset = .eighteen6
                windowStart = 13
                windowEnd = 19
                reason = "schedule_free_weekend"
            }
        }
        
        if consecutiveSocialDays >= 2 {
            preset = basePlan
            reason = "schedule_consecutive_social"
        }
        
        if let profile, profile.needsReducedIntensity, preset.fastingHours > 16 {
            preset = .sixteen8
            windowStart = 11
            windowEnd = 19
            reason = "schedule_reduced_intensity"
        }
        
        windowEnd = min(windowEnd, 23)
        windowStart = max(windowStart, 6)
        
        return FastingSuggestion(
            eatingWindowStart: windowStart,
            eatingWindowEnd: windowEnd,
            preset: preset,
            reason: reason,
            hasConflict: hasConflict
        )
    }
}
