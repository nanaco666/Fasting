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
    
    private let dialSize: CGFloat = 280
    private let ringWidth: CGFloat = 20
    
    // 24 hour marks
    private let majorHours = [0, 3, 6, 9, 12, 15, 18, 21]
    private let allHours = Array(0..<24)
    
    var body: some View {
        ZStack {
            // Outer bezel ring (dark, subtle)
            bezelRing
            
            // Hour tick marks
            tickMarks
            
            // Progress arc (the hero — colored fill)
            progressArc
            
            // Start/end markers
            if isFasting, let start = startTime {
                markers(start: start)
            }
            
            // Center content
            centerContent
        }
        .frame(width: dialSize, height: dialSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
        }
    }
    
    // MARK: - Bezel Ring
    
    private var bezelRing: some View {
        ZStack {
            // Outer edge
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                .frame(width: dialSize, height: dialSize)
            
            // Track ring (where progress fills)
            Circle()
                .stroke(Color.gray.opacity(0.06), lineWidth: ringWidth)
                .frame(width: dialSize - ringWidth, height: dialSize - ringWidth)
        }
    }
    
    // MARK: - Tick Marks
    
    private var tickMarks: some View {
        let radius = (dialSize - ringWidth) / 2
        
        return ZStack {
            ForEach(allHours, id: \.self) { hour in
                let angle = Angle.degrees(Double(hour) / 24 * 360 - 90)
                let isMajor = majorHours.contains(hour)
                let tickLength: CGFloat = isMajor ? 12 : 6
                let tickWidth: CGFloat = isMajor ? 2 : 1
                
                // Tick mark
                Rectangle()
                    .fill(isMajor ? Color.primary.opacity(0.5) : Color.gray.opacity(0.25))
                    .frame(width: tickWidth, height: tickLength)
                    .offset(y: -(radius - ringWidth / 2 - tickLength / 2 - 2))
                    .rotationEffect(angle)
                
                // Hour label (major only)
                if isMajor {
                    Text("\(hour)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(hourLabelColor(hour))
                        .position(hourLabelPosition(hour: hour, radius: radius - ringWidth - 16))
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
    
    private func hourLabelColor(_ hour: Int) -> Color {
        guard isFasting, let start = startTime else {
            return .secondary
        }
        let startHour24 = Calendar.current.component(.hour, from: start)
        let elapsedHours = elapsed / 3600
        let hourAngle = Double(hour)
        let startAngle = Double(startHour24) + Double(Calendar.current.component(.minute, from: start)) / 60.0
        
        // Check if this hour is within the fasted range
        let diff = (hourAngle - startAngle + 24).truncatingRemainder(dividingBy: 24)
        if diff <= elapsedHours {
            return .primary
        }
        return .secondary.opacity(0.5)
    }
    
    private func hourLabelPosition(hour: Int, radius: CGFloat) -> CGPoint {
        let center = dialSize / 2
        let angle = CGFloat(hour) / 24 * 2 * .pi - .pi / 2
        return CGPoint(
            x: center + radius * Foundation.cos(angle),
            y: center + radius * Foundation.sin(angle)
        )
    }
    
    // MARK: - Progress Arc
    
    private var progressArc: some View {
        let arcRadius = (dialSize - ringWidth) / 2
        
        return ZStack {
            // Filled arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: arcRadius * 2, height: arcRadius * 2)
                .rotationEffect(startAngle)
                .animation(.smoothSpring, value: progress)
            
            // Glow at the leading edge (breathing)
            if isFasting && !isGoalAchieved {
                Circle()
                    .fill(Color.fastingGreen.opacity(0.3 + breathePhase * 0.2))
                    .frame(width: ringWidth + 8, height: ringWidth + 8)
                    .blur(radius: 6)
                    .offset(y: -arcRadius)
                    .rotationEffect(startAngle + Angle.degrees(progress * 360))
            }
        }
    }
    
    private var startAngle: Angle {
        guard let start = startTime else { return .degrees(-90) }
        let cal = Calendar.current
        let hour = Double(cal.component(.hour, from: start))
        let minute = Double(cal.component(.minute, from: start))
        let fraction = (hour + minute / 60) / 24
        return .degrees(fraction * 360 - 90)
    }
    
    private var progressGradient: AngularGradient {
        if isGoalAchieved {
            return AngularGradient(
                colors: [.fastingGreen, .fastingTeal, .fastingGreen],
                center: .center
            )
        }
        return AngularGradient(
            colors: [.fastingOrange, .fastingGreen],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(progress * 360)
        )
    }
    
    // MARK: - Start/End Markers
    
    private func markers(start: Date) -> some View {
        let arcRadius = (dialSize - ringWidth) / 2
        let endDate = start.addingTimeInterval(target)
        
        return ZStack {
            // Start marker — small dot
            Circle()
                .fill(Color.fastingOrange)
                .frame(width: 8, height: 8)
                .offset(y: -arcRadius)
                .rotationEffect(dateAngle(start))
            
            // End/Goal marker — triangle or dot
            if target > 0 {
                Image(systemName: isGoalAchieved ? "checkmark.circle.fill" : "triangle.fill")
                    .font(.system(size: isGoalAchieved ? 14 : 8))
                    .foregroundStyle(isGoalAchieved ? Color.fastingGreen : Color.gray.opacity(0.5))
                    .offset(y: -(arcRadius + ringWidth / 2 + 10))
                    .rotationEffect(dateAngle(endDate))
            }
        }
    }
    
    private func dateAngle(_ date: Date) -> Angle {
        let cal = Calendar.current
        let hour = Double(cal.component(.hour, from: date))
        let minute = Double(cal.component(.minute, from: date))
        let fraction = (hour + minute / 60) / 24
        return .degrees(fraction * 360 - 90)
    }
    
    // MARK: - Center Content
    
    private var centerContent: some View {
        VStack(spacing: 4) {
            // Elapsed time — hero number
            Text(formattedElapsed)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            
            if isFasting {
                if isGoalAchieved {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                        Text("COMPLETED")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Color.fastingGreen)
                    .tracking(0.5)
                } else {
                    // Remaining
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
        let rem = max(target - elapsed, 0)
        return FastingRecord.formatShortDuration(rem)
    }
}

// MARK: - Preview

#Preview("Fasting - 10h into 16:8") {
    ZStack {
        Color.black.opacity(0.02).ignoresSafeArea()
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

#Preview("Goal Achieved") {
    ZStack {
        Color.black.opacity(0.02).ignoresSafeArea()
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
        Color.black.opacity(0.02).ignoresSafeArea()
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
