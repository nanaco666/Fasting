//
//  WatchDialView.swift
//  Fasting
//
//  Clock-style timer dial
//  Arc starts from 12 o'clock (top), sweeps clockwise with progress
//  Hour marks show fasting hours (0h → target)
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
    
    private var targetHours: Int {
        max(Int(target / 3600), 1)
    }
    
    var body: some View {
        ZStack {
            dialFace
            fastingArc
            goalMarker
            currentPositionDot
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
            
            // Hour ticks + labels based on target duration
            hourTicks(trackR: trackR)
        }
    }
    
    private func hourTicks(trackR: CGFloat) -> some View {
        let totalHours = targetHours
        // Determine tick interval: show every hour if ≤24, every 2h if >24
        let majorInterval = totalHours <= 12 ? 2 : (totalHours <= 24 ? 3 : 6)
        
        return ZStack {
            ForEach(0...totalHours, id: \.self) { hour in
                let fraction = Double(hour) / Double(totalHours)
                let angle = Angle.degrees(fraction * 360 - 90)
                let isMajor = hour % majorInterval == 0
                let isPast = (Double(hour) / Double(totalHours)) <= progress
                
                // Tick
                let outerR = dialSize / 2 - ringWidth
                let len: CGFloat = isMajor ? 10 : 5
                let wid: CGFloat = isMajor ? 1.5 : 0.8
                
                Rectangle()
                    .fill(isPast && isFasting ? Color.primary.opacity(0.5) : Color.gray.opacity(isMajor ? 0.25 : 0.12))
                    .frame(width: wid, height: len)
                    .offset(y: -(outerR - len / 2))
                    .rotationEffect(angle)
                
                // Label (major ticks only)
                if isMajor {
                    let labelR = dialSize / 2 - ringWidth - 18
                    let a = fraction * 2 * .pi - .pi / 2
                    Text("\(hour)h")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(isPast && isFasting ? Color.primary : Color.secondary.opacity(0.35))
                        .position(
                            x: dialSize / 2 + labelR * Foundation.cos(a),
                            y: dialSize / 2 + labelR * Foundation.sin(a)
                        )
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
    
    // MARK: - Fasting Arc (starts from top, sweeps clockwise)
    
    private var fastingArc: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        let arcProgress = appeared ? min(progress, 1.0) : 0
        
        return ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let startA = -Double.pi / 2  // 12 o'clock = top
                let sweepA = arcProgress * 2 * .pi
                
                guard sweepA > 0.005 else { return }
                
                let segments = max(Int(sweepA / 0.02), 2)
                for i in 0..<segments {
                    let t0 = Double(i) / Double(segments)
                    let t1 = Double(i + 1) / Double(segments)
                    let a0 = startA + t0 * sweepA
                    let a1 = startA + t1 * sweepA
                    
                    var path = Path()
                    path.addArc(center: center, radius: trackR, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                    
                    // Green at leading edge (current), orange at trailing (start)
                    let color = arcColor(at: 1.0 - t0)
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                }
            }
            .frame(width: dialSize, height: dialSize)
            
            // Glow at leading edge
            if isFasting && !isGoalAchieved && arcProgress > 0.01 {
                let endA = -Double.pi / 2 + arcProgress * 2 * .pi
                Circle()
                    .fill(Color.fastingGreen.opacity(0.25 + breathePhase * 0.15))
                    .frame(width: ringWidth + 10, height: ringWidth + 10)
                    .blur(radius: 8)
                    .offset(
                        x: trackR * Foundation.cos(endA),
                        y: trackR * Foundation.sin(endA)
                    )
            }
        }
    }
    
    private func arcColor(at t: Double) -> Color {
        if isGoalAchieved {
            return Color.fastingGreen
        }
        // t=0 → green (leading), t=1 → orange (trailing/start)
        return Color(
            red: 0.2 + t * 0.8,
            green: 0.78 - t * 0.13,
            blue: 0.35 - t * 0.15
        )
    }
    
    // MARK: - Goal Marker (at 100% = 12 o'clock = full circle)
    
    private var goalMarker: some View {
        // Goal is at the top (360° = 0° = 12 o'clock)
        // Show a subtle marker just outside the ring at the start/top
        let outerR = dialSize / 2 + 4
        
        return Group {
            if isFasting {
                if isGoalAchieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fastingGreen)
                } else {
                    // Small triangle at top pointing down
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.gray.opacity(0.35))
                }
            }
        }
        .offset(y: -outerR) // top center
    }
    
    // MARK: - Current Position Dot
    
    private var currentPositionDot: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        let arcProgress = min(progress, 1.0)
        let currentA = -Double.pi / 2 + arcProgress * 2 * .pi
        
        return Group {
            if isFasting && arcProgress > 0.005 {
                Circle()
                    .fill(Color.white)
                    .frame(width: 7, height: 7)
                    .shadow(color: Color.fastingGreen.opacity(0.5), radius: 3)
                    .offset(
                        x: trackR * Foundation.cos(currentA),
                        y: trackR * Foundation.sin(currentA)
                    )
            }
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

#Preview("16:8 — 10h in") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 10.0 / 16.0,
            elapsed: 10 * 3600,
            target: 16 * 3600,
            startTime: Date().addingTimeInterval(-10 * 3600),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}

#Preview("16:8 — 2h in") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 2.0 / 16.0,
            elapsed: 2 * 3600,
            target: 16 * 3600,
            startTime: Date().addingTimeInterval(-2 * 3600),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}

#Preview("Completed") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 1.0,
            elapsed: 17 * 3600,
            target: 16 * 3600,
            startTime: Date().addingTimeInterval(-17 * 3600),
            isFasting: true,
            isGoalAchieved: true
        )
    }
}
