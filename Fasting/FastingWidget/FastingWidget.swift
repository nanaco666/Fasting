//
//  FastingWidget.swift
//  FastingWidget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct FastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: .now, state: .preview)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        let state = SharedFastingData.load()
        completion(FastingEntry(date: .now, state: state))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let state = SharedFastingData.load()
        var entries: [FastingEntry] = []
        let now = Date()
        
        if state.isFasting {
            // Update every minute for live countdown
            for minuteOffset in 0..<60 {
                let date = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
                entries.append(FastingEntry(date: date, state: state))
            }
        } else {
            entries.append(FastingEntry(date: now, state: state))
        }
        
        let policy: TimelineReloadPolicy = state.isFasting ? .after(
            Calendar.current.date(byAdding: .minute, value: 30, to: now)!
        ) : .never
        
        completion(Timeline(entries: entries, policy: policy))
    }
}

// MARK: - Entry

struct FastingEntry: TimelineEntry {
    let date: Date
    let state: SharedFastingState
    
    var elapsed: TimeInterval {
        guard state.isFasting, let start = state.startTime else { return 0 }
        return date.timeIntervalSince(start)
    }
    
    var progress: Double {
        guard state.isFasting, state.targetDuration > 0 else { return 0 }
        return min(elapsed / state.targetDuration, 1.0)
    }
    
    var remaining: TimeInterval {
        max(state.targetDuration - elapsed, 0)
    }
    
    var isGoalAchieved: Bool {
        state.isFasting && elapsed >= state.targetDuration
    }
    
    /// For display: use Date() for real-time in views that support it
    var liveElapsed: TimeInterval {
        guard state.isFasting, let start = state.startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    var liveProgress: Double {
        guard state.isFasting, state.targetDuration > 0 else { return 0 }
        return min(liveElapsed / state.targetDuration, 1.0)
    }
    
    var liveRemaining: TimeInterval {
        max(state.targetDuration - liveElapsed, 0)
    }
}

extension SharedFastingState {
    static let preview = SharedFastingState(
        isFasting: true,
        startTime: Date().addingTimeInterval(-6 * 3600),
        targetDuration: 16 * 3600,
        presetName: "16:8",
        lastUpdated: Date()
    )
}

// MARK: - Widget Views

struct FastingWidgetSmall: View {
    let entry: FastingEntry
    
    var body: some View {
        if entry.state.isFasting {
            fastingView
        } else {
            idleView
        }
    }
    
    private var endDate: Date {
        (entry.state.startTime ?? Date()).addingTimeInterval(entry.state.targetDuration)
    }
    
    private var fastingView: some View {
        VStack(spacing: 0) {
            // Top right: ring
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 36, height: 36)
            }
            
            Spacer()
            
            // Main content: left aligned
            VStack(alignment: .leading, spacing: 4) {
                Text("Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if entry.isGoalAchieved {
                    Text("Done ✅")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                } else {
                    Text(endDate, style: .timer)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                
                Text(entry.state.presetName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var idleView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 5)
                }
                .frame(width: 36, height: 36)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Not Fasting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Tap to start")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FastingWidgetMedium: View {
    let entry: FastingEntry
    
    var body: some View {
        if entry.state.isFasting {
            fastingView
        } else {
            idleView
        }
    }
    
    private var endDate: Date {
        (entry.state.startTime ?? Date()).addingTimeInterval(entry.state.targetDuration)
    }
    
    private var fastingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: preset + ring
            HStack(alignment: .top) {
                Text(entry.state.presetName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.green)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            // Bottom: label + big timer
            Text("Remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if entry.isGoalAchieved {
                Text("Done ✅")
                    .font(.system(.title, design: .rounded, weight: .bold))
            } else {
                Text(endDate, style: .timer)
                    .font(.system(size: 34, weight: .regular, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
    
    private var idleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("Fasting")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                }
                .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            Text("Not Fasting")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Tap to start")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }
}

// Lock screen widget
struct FastingWidgetAccessory: View {
    let entry: FastingEntry
    
    var body: some View {
        if entry.state.isFasting {
            ZStack {
                AccessoryWidgetBackground()
                
                VStack(spacing: 2) {
                    Gauge(value: entry.progress) {
                        Image(systemName: "flame.fill")
                    }
                    .gaugeStyle(.accessoryCircular)
                    
                    Text(entry.remaining.shortFormat)
                        .font(.system(.caption2, design: .rounded))
                        .monospacedDigit()
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "fork.knife")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Widget Definition

struct FastingWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FastingEntry
    
    var body: some View {
        #if os(watchOS)
        FastingWidgetAccessory(entry: entry)
        #else
        switch family {
        case .systemMedium:
            FastingWidgetMedium(entry: entry)
        case .accessoryCircular:
            FastingWidgetAccessory(entry: entry)
        default:
            FastingWidgetSmall(entry: entry)
        }
        #endif
    }
}

struct FastingWidget: Widget {
    let kind = "FastingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            FastingWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "fasting://timer"))
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your fasting progress")
        #if os(watchOS)
        .supportedFamilies([.accessoryCircular])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
        #endif
    }
}

// MARK: - TimeInterval Formatting

private extension TimeInterval {
    var shortFormat: String {
        let total = Int(self)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    FastingWidget()
} timeline: {
    FastingEntry(date: .now, state: .preview)
    FastingEntry(date: .now, state: .idle)
}

#Preview("Medium", as: .systemMedium) {
    FastingWidget()
} timeline: {
    FastingEntry(date: .now, state: .preview)
}
