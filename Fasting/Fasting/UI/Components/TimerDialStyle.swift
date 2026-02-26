//
//  TimerDialStyle.swift
//  Fasting
//
//  Timer dial style selector — long press to switch
//

import SwiftUI

enum TimerDialStyle: String, CaseIterable {
    case simple = "simple"
    case clock = "clock"
    case plate = "plate"
    case solar = "solar"
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .clock: return "Clock"
        case .plate: return "Plate"
        case .solar: return "Solar"
        }
    }
    
    var icon: String {
        switch self {
        case .simple: return "circle.circle"
        case .clock: return "clock.fill"
        case .plate: return "circle.grid.2x1.fill"
        case .solar: return "sun.max.fill"
        }
    }
    
    var next: TimerDialStyle {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }
}

// MARK: - Unified Timer Dial

struct TimerDial: View {
    let style: TimerDialStyle
    let progress: Double
    let elapsed: TimeInterval
    let target: TimeInterval
    let startTime: Date?
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    var body: some View {
        Group {
            switch style {
            case .simple:
                SimpleDialView(
                    progress: progress,
                    elapsed: elapsed,
                    target: target,
                    isFasting: isFasting,
                    isGoalAchieved: isGoalAchieved
                )
            case .clock:
                WatchDialView(
                    progress: progress,
                    elapsed: elapsed,
                    target: target,
                    startTime: startTime,
                    isFasting: isFasting,
                    isGoalAchieved: isGoalAchieved
                )
            case .plate:
                PlateDialView(
                    progress: progress,
                    elapsed: elapsed,
                    target: target,
                    startTime: startTime,
                    isFasting: isFasting,
                    isGoalAchieved: isGoalAchieved
                )
            case .solar:
                SolarDialView(
                    progress: progress,
                    elapsed: elapsed,
                    target: target,
                    startTime: startTime,
                    isFasting: isFasting,
                    isGoalAchieved: isGoalAchieved
                )
            }
        }
        .id(style) // force re-render on switch
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
