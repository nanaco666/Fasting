//
//  SharedFastingData.swift
//  FastingWidget
//
//  Shared data layer — duplicated for widget target
//  Keep in sync with Fasting/Core/Services/SharedFastingData.swift
//

import Foundation

struct SharedFastingState: Codable {
    var isFasting: Bool
    var startTime: Date?
    var targetDuration: TimeInterval
    var presetName: String
    var lastUpdated: Date
    
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
    
    static func load() -> SharedFastingState {
        guard let data = defaults?.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(SharedFastingState.self, from: data)
        else { return .idle }
        return state
    }
}
