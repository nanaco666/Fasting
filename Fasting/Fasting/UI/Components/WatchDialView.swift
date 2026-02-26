//
//  WatchDialView.swift
//  Fasting
//
//  Watch-dial inspired timer — 24h clock face with progress arc
//  Inspired by Apple Watch California/Solar Dial
//

import SwiftUI

struct WatchDialView: View {
    let progress: Double        // 0.0 - 1.0
    let elapsed: TimeInterval
    let target: TimeInterval
    let startTime: Date?
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    @State private var breathePhase: CGFloat = 0
    @State private var appeared = false
    
    private let dialSize: CGFloat = 280
    private let ringWidth: CGFloat = 18
    private let majorHours = [0, 3, 6, 9, 12, 15, 18, 21]
    
    var body: some View {
        ZStack {
            // Dial face
            dialFace
            
            // Progress arc
            progressArc
            
            // Markers
            if isFasting, let start = startTime {
                startMarker(start: start)
                goalMarker(start: start)
            }
            
            // Center
            centerContent
        }
        .frame(width: dialSize, height: dialSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            withAnimation(.smoothSpring.delay(0.2)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Dial Face
    
    private var dialFace: some View {
        let outerR = dialSize / 2
        let trackR = outerR - ringWidth / 2
        
        return ZStack {
            // Subtle outer ring
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .frame(width: dialSize, height: dialSize)
            
            // Track
            Circle()
                .stroke(Color.gray.opacity(0.06), lineWidth: ringWidth)
                .frame(width: trackR * 2, height: trackR * 2)
            
            // Tick marks + labels
            ForEach(0..<24, id: \.self) { hour in
                let isMajor = majorHours.contains(hour)
                let angle = hourAngle(hour)
                
                // Tick
                tick(hour: hour, isMajor: isMajor)
                    .rotationEffect(angle)
                
                // Label (major hours only)
                if isMajor {
                    hourLabel(hour: hour, radius: outerR - ringWidth - 20)
                }
            }
        }
    }
    
    private func tick(hour: Int, isMajor: Bool) -> some View {
        let outerR = dialSize / 2
        let len: CGFloat = isMajor ? 10 : 5
        let width: CGFloat = isMajor ? 1.5 : 0.8
        let inFastedRange = isHourInFastedRange(hour)
        
        return Rectangle()
            .fill(inFastedRange && isFasting ? Color.primary.opacity(0.6) : Color.gray.opacity(isMajor ? 0.3 : 0.15))
            .frame(width: width, height: len)
            .offset(y: -(outerR - ringWidth - len / 2 - 1))
    }
    
    private func hourLabel(hour: Int, radius: CGFloat) -> some View {
        let center = dialSize / 2
        let a = CGFloat(hour) / 24 * 2 * .pi - .pi / 2
        let inRange = isHourInFastedRange(hour)
        
        return Text("\(hour)")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(inRange && isFasting ? Color.primary : Color.secondary.opacity(0.4))
            .position(
                x: center + radius * Foundation.cos(a),
                y: center + radius * Foundation.sin(a)
            )
    }
    
    private func isHourInFastedRange(_ hour: Int) -> Bool {
        guard isFasting, let start = startTime else { return false }
        let cal = Calendar.current
        let startH = Double(cal.component(.hour, from: start)) + Double(cal.component(.minute, from: start)) / 60
        let h = Double(hour)
        let elapsedH = elapsed / 3600
        let diff = (h - startH + 24).truncatingRemainder(dividingBy: 24)
        return diff <= elapsedH
    }
    
    private func hourAngle(_ hour: Int) -> Angle {
        .degrees(Double(hour) / 24 * 360 - 90)
    }
    
    // MARK: - Progress Arc
    
    private var progressArc: some View {
        let trackR = dialSize / 2 - ringWidth / 2
        let arcProgress = appeared ? min(progress, 1.0) : 0
        
        return ZStack {
            // Main arc — draw manually via Canvas for proper gradient along path
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = trackR
                let startA = startAngleRadians
                let sweepA = arcProgress * 2 * .pi
                
                guard sweepA > 0.001 else { return }
                
                // Draw arc as series of small segments with interpolated color
                let segments = max(Int(sweepA / 0.02), 2)
                for i in 0..<segments {
                    let t0 = Double(i) / Double(segments)
                    let t1 = Double(i + 1) / Double(segments)
                    let a0 = startA + t0 * sweepA
                    let a1 = startA + t1 * sweepA
                    
                    var path = Path()
                    path.addArc(center: center, radius: radius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                    
                    // Color: green at leading (current), orange at trailing (start)
                    let color = arcColor(at: 1.0 - t0)
                    ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                }
            }
            .frame(width: dialSize, height: dialSize)
            .animation(.smoothSpring, value: progress)
            
            // Glow at leading edge
            if isFasting && !isGoalAchieved && arcProgress > 0.01 {
                let endA = startAngleRadians + arcProgress * 2 * .pi
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
        // t=0 → leading edge (green), t=1 → trailing edge (orange)
        if isGoalAchieved {
            return Color.fastingGreen
        }
        // Interpolate orange → green
        return Color(
            red: 0.2 + t * 0.8,      // 0.2 (green) → 1.0 (orange)
            green: 0.78 - t * 0.13,    // 0.78 (green) → 0.65 (orange)
            blue: 0.35 - t * 0.15      // 0.35 → 0.2
        )
    }
    
    private var startAngleRadians: Double {
        guard let start = startTime else { return -.pi / 2 }
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: start))
        let m = Double(cal.component(.minute, from: start))
        let fraction = (h + m / 60) / 24
        return fraction * 2 * .pi - .pi / 2
    }
    
    // MARK: - Markers
    
    private func startMarker(start: Date) -> some View {
        let trackR = dialSize / 2 - ringWidth / 2
        let a = dateAngleRadians(start)
        
        return Circle()
            .fill(Color.white)
            .frame(width: 6, height: 6)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            .offset(
                x: trackR * Foundation.cos(a),
                y: trackR * Foundation.sin(a)
            )
    }
    
    private func goalMarker(start: Date) -> some View {
        let trackR = dialSize / 2 + 4
        let goalDate = start.addingTimeInterval(target)
        let a = dateAngleRadians(goalDate)
        
        return Group {
            if isGoalAchieved {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fastingGreen)
            } else {
                // Small triangle pointing inward
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .rotationEffect(.radians(a + .pi / 2))
            }
        }
        .offset(
            x: trackR * Foundation.cos(a),
            y: trackR * Foundation.sin(a)
        )
    }
    
    private func dateAngleRadians(_ date: Date) -> Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: date))
        let m = Double(cal.component(.minute, from: date))
        return (h + m / 60) / 24 * 2 * .pi - .pi / 2
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

#Preview("Fasting - 10h into 16:8") {
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

#Preview("Fasting - 2h into 16:8 (afternoon start)") {
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

#Preview("Goal Achieved") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 1.0,
            elapsed: 17 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date().addingTimeInterval(-17 * 3600)),
            isFasting: true,
            isGoalAchieved: true
        )
    }
}

#Preview("Idle") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        WatchDialView(
            progress: 1.0,
            elapsed: 16.5 * 3600,
            target: 16 * 3600,
            startTime: nil,
            isFasting: false,
            isGoalAchieved: false
        )
    }
}
