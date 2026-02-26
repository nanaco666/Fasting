//
//  WatchDialView.swift
//  Fasting
//
//  24h clock dial — shows REAL time of day
//  0(midnight) at top, 12(noon) at bottom, clockwise
//  Fasting arc fills between start time and current real time
//

import SwiftUI

struct WatchDialView: View {
    let progress: Double
    let elapsed: TimeInterval
    let target: TimeInterval
    let startTime: Date?
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    @State private var breathePhase: CGFloat = 0
    @State private var appeared = false
    
    private let dialSize: CGFloat = 280
    private let ringWidth: CGFloat = 18
    
    // Current real time
    private var now: Date { Date() }
    
    var body: some View {
        ZStack {
            // Dial face with real hour positions
            dialFace
            
            // Fasting arc (real time positions)
            if isFasting || (!isFasting && startTime == nil) {
                fastingArc
            }
            
            // Current time hand
            if isFasting {
                currentTimeHand
            }
            
            // Start & goal markers
            if let start = startTime {
                timeMarkers(start: start)
            }
            
            // Center
            centerContent
        }
        .frame(width: dialSize, height: dialSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Hour → Angle (real 24h clock)
    // 0h (midnight) = top (-90°), 6h = right, 12h = bottom, 18h = left
    
    private func hourToAngle(_ hour: Double) -> Angle {
        .degrees(hour / 24 * 360 - 90)
    }
    
    private func hourToRadians(_ hour: Double) -> Double {
        hour / 24 * 2 * .pi - .pi / 2
    }
    
    private func dateToHour(_ date: Date) -> Double {
        let cal = Calendar.current
        return Double(cal.component(.hour, from: date)) + Double(cal.component(.minute, from: date)) / 60.0
    }
    
    // MARK: - Dial Face
    
    private var dialFace: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        
        return ZStack {
            // Outer rim
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                .frame(width: dialSize, height: dialSize)
            
            // Track ring
            Circle()
                .stroke(Color.gray.opacity(0.06), lineWidth: ringWidth)
                .frame(width: trackR * 2, height: trackR * 2)
            
            // Hour ticks + labels
            ForEach(0..<24, id: \.self) { hour in
                let isMajor = hour % 3 == 0
                
                // Tick mark
                tickMark(hour: hour, isMajor: isMajor)
                
                // Label (every 3 hours)
                if isMajor {
                    hourLabelView(hour: hour, radius: dialSize / 2 - ringWidth - 18)
                }
            }
            
            // Night/day subtle background
            nightDayOverlay
        }
    }
    
    private func tickMark(hour: Int, isMajor: Bool) -> some View {
        let outerR = dialSize / 2 - ringWidth
        let len: CGFloat = isMajor ? 10 : 5
        let width: CGFloat = isMajor ? 1.5 : 0.8
        let inRange = isHourInFastedRange(Double(hour))
        
        return Rectangle()
            .fill(inRange && isFasting ? Color.primary.opacity(0.6) : Color.gray.opacity(isMajor ? 0.3 : 0.15))
            .frame(width: width, height: len)
            .offset(y: -(outerR - len / 2))
            .rotationEffect(hourToAngle(Double(hour)))
    }
    
    private func hourLabelView(hour: Int, radius: CGFloat) -> some View {
        let center = dialSize / 2
        let a = hourToRadians(Double(hour))
        let inRange = isHourInFastedRange(Double(hour))
        
        return Text(formatHourLabel(hour))
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(inRange && isFasting ? Color.primary : Color.secondary.opacity(0.4))
            .position(
                x: center + radius * Foundation.cos(a),
                y: center + radius * Foundation.sin(a)
            )
    }
    
    private func formatHourLabel(_ hour: Int) -> String {
        // Show as clock hours: 0, 3, 6, 9, 12, 15, 18, 21
        return "\(hour)"
    }
    
    private func isHourInFastedRange(_ hour: Double) -> Bool {
        guard isFasting, let start = startTime else { return false }
        let startH = dateToHour(start)
        let diff = (hour - startH + 24).truncatingRemainder(dividingBy: 24)
        return diff <= elapsed / 3600
    }
    
    // Night/day subtle overlay (dark top half = night, lighter bottom = day)
    private var nightDayOverlay: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        return ZStack {
            // Very subtle night indicator (top half: 0-12)
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(Color.primary.opacity(0.03), lineWidth: ringWidth - 4)
                .frame(width: trackR * 2, height: trackR * 2)
                .rotationEffect(.degrees(-90))
        }
    }
    
    // MARK: - Fasting Arc
    
    private var fastingArc: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        let arcProgress = appeared ? min(progress, 1.0) : 0
        
        return ZStack {
            Canvas { ctx, size in
                guard let start = startTime else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = trackR
                let startA = hourToRadians(dateToHour(start))
                let sweepA = arcProgress * (target / 3600) / 24 * 2 * .pi
                // Actually: the arc covers (elapsed hours / 24) of the circle
                let realSweep = (elapsed / 3600) / 24 * 2 * .pi
                
                guard realSweep > 0.001 else { return }
                
                let segments = max(Int(realSweep / 0.02), 2)
                for i in 0..<segments {
                    let t0 = Double(i) / Double(segments)
                    let t1 = Double(i + 1) / Double(segments)
                    let a0 = startA + t0 * realSweep
                    let a1 = startA + t1 * realSweep
                    
                    var path = Path()
                    path.addArc(center: center, radius: radius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                    
                    // Green at current end, orange at start
                    let color = arcColor(at: 1.0 - t0)
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                }
            }
            .frame(width: dialSize, height: dialSize)
            
            // Glow at current time position
            if isFasting && !isGoalAchieved {
                let currentA = hourToRadians(dateToHour(now))
                Circle()
                    .fill(Color.fastingGreen.opacity(0.25 + breathePhase * 0.15))
                    .frame(width: ringWidth + 10, height: ringWidth + 10)
                    .blur(radius: 8)
                    .offset(
                        x: trackR * Foundation.cos(currentA),
                        y: trackR * Foundation.sin(currentA)
                    )
            }
        }
    }
    
    private func arcColor(at t: Double) -> Color {
        if isGoalAchieved {
            return Color.fastingGreen
        }
        return Color(
            red: 0.2 + t * 0.8,
            green: 0.78 - t * 0.13,
            blue: 0.35 - t * 0.15
        )
    }
    
    // MARK: - Current Time Hand
    
    private var currentTimeHand: some View {
        let innerR = dialSize / 2 - ringWidth - 30
        let outerR = dialSize / 2 - ringWidth + 2
        let currentA = hourToRadians(dateToHour(now))
        
        return ZStack {
            // Thin hand line
            Rectangle()
                .fill(Color.fastingGreen)
                .frame(width: 2, height: outerR - innerR / 2)
                .offset(y: -(innerR / 2 + (outerR - innerR / 2) / 2))
                .rotationEffect(hourToAngle(dateToHour(now)))
            
            // Dot at the tip on the ring
            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .shadow(color: Color.fastingGreen.opacity(0.5), radius: 3)
                .offset(
                    x: (dialSize / 2 - ringWidth / 2) * Foundation.cos(currentA),
                    y: (dialSize / 2 - ringWidth / 2) * Foundation.sin(currentA)
                )
        }
    }
    
    // MARK: - Time Markers (start + goal)
    
    private func timeMarkers(start: Date) -> some View {
        let trackR = dialSize / 2
        let startA = hourToRadians(dateToHour(start))
        let goalDate = start.addingTimeInterval(target)
        let goalA = hourToRadians(dateToHour(goalDate))
        
        return ZStack {
            // Start: small orange dot on outer edge
            Circle()
                .fill(Color.fastingOrange)
                .frame(width: 6, height: 6)
                .offset(
                    x: (trackR - ringWidth / 2) * Foundation.cos(startA),
                    y: (trackR - ringWidth / 2) * Foundation.sin(startA)
                )
            
            // Goal: triangle or checkmark on outer edge
            Group {
                if isGoalAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fastingGreen)
                } else {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.gray.opacity(0.4))
                        .rotationEffect(.radians(goalA + .pi / 2))
                }
            }
            .offset(
                x: (trackR + 6) * Foundation.cos(goalA),
                y: (trackR + 6) * Foundation.sin(goalA)
            )
        }
    }
    
    // MARK: - Center Content
    
    private var centerContent: some View {
        VStack(spacing: 4) {
            Text(formattedElapsed)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            
            if isFasting {
                if isGoalAchieved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .symbolEffect(.bounce, value: isGoalAchieved)
                        Text("COMPLETED")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(Color.fastingGreen)
                    .tracking(1)
                } else {
                    Text(formattedRemaining)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            } else {
                Text("LAST FAST")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(1)
            }
        }
    }
    
    // MARK: - Formatting
    
    private var formattedElapsed: String {
        FastingRecord.formatDuration(elapsed)
    }
    
    private var formattedRemaining: String {
        FastingRecord.formatShortDuration(max(target - elapsed, 0))
    }
}

// MARK: - Preview

#Preview("16:8 started 20:00, now 06:00 (+10h)") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 10.0 / 16.0,
            elapsed: 10 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date().addingTimeInterval(-10 * 3600)),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}

#Preview("Started 13:43, 2h in") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 2.0 / 16.0,
            elapsed: 2 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 13, minute: 43, second: 0, of: Date()),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}
