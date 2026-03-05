//
//  FastingWidget.swift
//  FastingWidget
//
//  Widget with plate theme integration — matches main app tablecloth + colors
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
        
        let refreshWindow: TimeInterval = 60
        let step: TimeInterval = state.isFasting ? 1 : refreshWindow
        let end = now.addingTimeInterval(refreshWindow)
        var cursor = now
        
        while cursor <= end {
            entries.append(FastingEntry(date: cursor, state: state))
            cursor = cursor.addingTimeInterval(step)
        }
        
        let policy: TimelineReloadPolicy = .after(now.addingTimeInterval(refreshWindow))
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
}

extension SharedFastingState {
    static let preview = SharedFastingState(
        isFasting: true,
        startTime: Date().addingTimeInterval(-6 * 3600),
        targetDuration: 16 * 3600,
        presetName: "16:8",
        lastUpdated: Date(),
        themeId: "classic"
    )
}

// MARK: - Widget Theme Colors (lightweight, no PlateTheme dependency)

private struct WidgetThemeColors {
    let accent: Color
    let track: Color
    let tableclothAsset: String?  // nil = solid bg
    let blendColor: Color
    
    static func from(themeId: String) -> WidgetThemeColors {
        switch themeId {
        case "minimal":
            return WidgetThemeColors(
                accent: .green, track: .gray.opacity(0.15),
                tableclothAsset: nil, blendColor: .clear
            )
        case "classic":
            return WidgetThemeColors(
                accent: .green, track: .gray.opacity(0.15),
                tableclothAsset: "tablecloth_linen",
                blendColor: Color(red: 0.96, green: 0.94, blue: 0.90)
            )
        case "ironwood":
            return WidgetThemeColors(
                accent: .orange, track: .white.opacity(0.08),
                tableclothAsset: "tablecloth_darkwood",
                blendColor: Color(red: 0.12, green: 0.10, blue: 0.08)
            )
        case "marble":
            return WidgetThemeColors(
                accent: .teal, track: .teal.opacity(0.1),
                tableclothAsset: "tablecloth_marble",
                blendColor: Color(red: 0.92, green: 0.92, blue: 0.93)
            )
        case "washi":
            return WidgetThemeColors(
                accent: .green, track: .brown.opacity(0.1),
                tableclothAsset: "tablecloth_washi",
                blendColor: Color(red: 0.95, green: 0.93, blue: 0.88)
            )
        default:
            return .from(themeId: "classic")
        }
    }
}

// MARK: - Themed Widget Background

private struct WidgetThemeBackground: View {
    let colors: WidgetThemeColors
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if let asset = colors.tableclothAsset {
            ZStack {
                (colorScheme == .dark ? Color(.systemBackground) : colors.blendColor)
                Image(asset)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(colorScheme == .dark ? 0.3 : 0.6)
            }
        } else {
            Color(.systemBackground)
        }
    }
}

// MARK: - Small Widget

struct FastingWidgetSmall: View {
    let entry: FastingEntry
    private var tc: WidgetThemeColors { .from(themeId: entry.state.themeId) }
    
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
            HStack {
                Spacer()
                // Mini plate ring
                ZStack {
                    Circle()
                        .stroke(tc.track, lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(tc.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    if entry.isGoalAchieved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(tc.accent)
                    }
                }
                .frame(width: 36, height: 36)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if entry.isGoalAchieved {
                    Label("Complete", systemImage: "checkmark.seal.fill")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(tc.accent)
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
                        .stroke(tc.track, lineWidth: 5)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
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

// MARK: - Medium Widget

struct FastingWidgetMedium: View {
    let entry: FastingEntry
    private var tc: WidgetThemeColors { .from(themeId: entry.state.themeId) }
    
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
            HStack(alignment: .top) {
                Text(entry.state.presetName)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(tc.accent)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(tc.track, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: entry.progress)
                        .stroke(tc.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    if entry.isGoalAchieved {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.body)
                            .foregroundStyle(tc.accent)
                    } else {
                        Text("\(Int(entry.progress * 100))%")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 50, height: 50)
            }
            
            Spacer()
            
            Text("Remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if entry.isGoalAchieved {
                Label("Complete", systemImage: "checkmark.seal.fill")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(tc.accent)
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
                        .stroke(tc.track, lineWidth: 6)
                    Image(systemName: "fork.knife")
                        .font(.body)
                        .foregroundStyle(.tertiary)
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

// MARK: - Lock Screen Widget

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
            let tc = WidgetThemeColors.from(themeId: entry.state.themeId)
            FastingWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetThemeBackground(colors: tc)
                }
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
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
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
