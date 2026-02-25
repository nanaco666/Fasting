//
//  SharedFastingData.swift
//  Fasting
//
//  App ↔ Widget 共享数据层 (via App Groups UserDefaults)
//

import Foundation
import WidgetKit

/// Shared fasting state stored in App Group UserDefaults
struct SharedFastingState: Codable {
    var isFasting: Bool
    var startTime: Date?
    var targetDuration: TimeInterval
    var presetName: String
    var lastUpdated: Date
    
    /// Elapsed seconds since start
    var elapsed: TimeInterval {
        guard isFasting, let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    /// Progress 0.0 - 1.0
    var progress: Double {
        guard isFasting, targetDuration > 0 else { return 0 }
        return min(elapsed / targetDuration, 1.0)
    }
    
    /// Remaining seconds
    var remaining: TimeInterval {
        max(targetDuration - elapsed, 0)
    }
    
    var isGoalAchieved: Bool {
        isFasting && elapsed >= targetDuration
    }
    
    static let idle = SharedFastingState(
        isFasting: false, startTime: nil,
        targetDuration: 0, presetName: "",
        lastUpdated: Date()
    )
}

enum SharedFastingData {
    private static let suiteName = "group.com.nana.fasting"
    private static let stateKey = "fastingState"
    
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    /// Write state from main app
    static func save(_ state: SharedFastingState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults?.set(data, forKey: stateKey)
        // Tell widget to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Read state (from widget or app)
    static func load() -> SharedFastingState {
        guard let data = defaults?.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(SharedFastingState.self, from: data)
        else { return .idle }
        return state
    }
}
