//
//  PlateDialView.swift
//  Fasting
//
//  Plate-style timer — Empty plate metaphor with filled sector
//  Inspired by Apple Watch Solar Dial + app icon (empty plate)
//  Fasting time shown as a colored wedge on the "plate"
//

import SwiftUI

struct PlateDialView: View {
    let progress: Double
    let elapsed: TimeInterval
    let target: TimeInterval
    let startTime: Date?
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    @State private var breathePhase: CGFloat = 0
    @State private var appeared = false
    
    private let dialSize: CGFloat = 280
    
    var body: some View {
        ZStack {
            // The "plate" — outer ring
            plateRing
            
            // Filled sector (the fasting wedge)
            fastingSector
            
            // 24h hour marks (subtle, on the inner edge)
            hourMarks
            
            // Light/dark divider line (like Solar Dial's day/night)
            if isFasting, let start = startTime {
                dividerLines(start: start)
            }
            
            // Center circle (inner plate)
            centerPlate
            
            // Center content
            centerContent
        }
        .frame(width: dialSize, height: dialSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            withAnimation(.smoothSpring.delay(0.1)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Plate Ring
    
    private var plateRing: some View {
        ZStack {
            // Outer plate — gradient for depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(.systemBackground).opacity(0.8),
                            Color.gray.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: dialSize * 0.35,
                        endRadius: dialSize * 0.5
                    )
                )
                .frame(width: dialSize, height: dialSize)
            
            // Subtle rim
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                .frame(width: dialSize, height: dialSize)
            
            // Inner rim
            Circle()
                .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
                .frame(width: dialSize * 0.75, height: dialSize * 0.75)
        }
    }
    
    // MARK: - Fasting Sector (the key visual)
    
    private var fastingSector: some View {
        let startA = startAngle
        let sweepDegrees = (appeared ? min(progress, 1.0) : 0) * 360
        
        return ZStack {
            // Main sector fill
            SectorShape(startAngle: startA, endAngle: startA + .degrees(sweepDegrees))
                .fill(sectorGradient)
                .frame(width: dialSize * 0.88, height: dialSize * 0.88)
                .opacity(0.85)
                .animation(.smoothSpring, value: progress)
            
            // Glow at the leading edge
            if isFasting && !isGoalAchieved && sweepDegrees > 1 {
                let edgeA = (startA + .degrees(sweepDegrees)).radians
                let r = dialSize * 0.44 * 0.7
                Circle()
                    .fill(Color.fastingGreen.opacity(0.3 + breathePhase * 0.15))
                    .frame(width: 20, height: 20)
                    .blur(radius: 10)
                    .offset(
                        x: r * Foundation.cos(edgeA),
                        y: r * Foundation.sin(edgeA)
                    )
            }
        }
    }
    
    private var sectorGradient: some ShapeStyle {
        if isGoalAchieved {
            return AnyShapeStyle(
                AngularGradient(
                    colors: [
                        Color.fastingGreen.opacity(0.5),
                        Color.fastingTeal.opacity(0.4),
                        Color.fastingGreen.opacity(0.5)
                    ],
                    center: .center,
                    startAngle: startAngle,
                    endAngle: startAngle + .degrees(360)
                )
            )
        }
        return AnyShapeStyle(
            AngularGradient(
                colors: [
                    Color.fastingGreen.opacity(0.5),
                    Color.fastingTeal.opacity(0.35),
                    Color.fastingOrange.opacity(0.4),
                ],
                center: .center,
                startAngle: startAngle,
                endAngle: startAngle + .degrees(min(progress, 1.0) * 360)
            )
        )
    }
    
    private var startAngle: Angle {
        guard let start = startTime else { return .degrees(-90) }
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: start))
        let m = Double(cal.component(.minute, from: start))
        return .degrees((h + m / 60) / 24 * 360 - 90)
    }
    
    // MARK: - Hour Marks
    
    private var hourMarks: some View {
        let outerR = dialSize * 0.44
        
        return ZStack {
            ForEach(0..<24, id: \.self) { hour in
                let isMajor = hour % 3 == 0
                let angle = Angle.degrees(Double(hour) / 24 * 360 - 90)
                let len: CGFloat = isMajor ? 8 : 4
                let width: CGFloat = isMajor ? 1.5 : 0.8
                
                Rectangle()
                    .fill(Color.white.opacity(isMajor ? 0.8 : 0.4))
                    .frame(width: width, height: len)
                    .offset(y: -(outerR - len / 2))
                    .rotationEffect(angle)
                
                if isMajor {
                    let labelR = outerR - 18
                    let a = CGFloat(hour) / 24 * 2 * .pi - .pi / 2
                    Text("\(hour)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .position(
                            x: dialSize / 2 + labelR * Foundation.cos(a),
                            y: dialSize / 2 + labelR * Foundation.sin(a)
                        )
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
        .opacity(isFasting ? 1 : 0.3)
    }
    
    // MARK: - Divider Lines (start/end markers)
    
    private func dividerLines(start: Date) -> some View {
        let startA = self.startAngle
        let goalDate = start.addingTimeInterval(target)
        let goalA = Angle.degrees(
            (Double(Calendar.current.component(.hour, from: goalDate)) +
             Double(Calendar.current.component(.minute, from: goalDate)) / 60) / 24 * 360 - 90
        )
        
        return ZStack {
            // Start line
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 1.5, height: dialSize * 0.44)
                .offset(y: -dialSize * 0.22)
                .rotationEffect(startA)
            
            // Goal line (dashed when not reached)
            if !isGoalAchieved {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: dialSize * 0.44)
                    .offset(y: -dialSize * 0.22)
                    .rotationEffect(goalA)
            }
            
            // Current time indicator (bright dot on the edge)
            let currentA = startA + .degrees(min(progress, 1.0) * 360)
            let dotR = dialSize * 0.44
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .shadow(color: Color.white.opacity(0.5), radius: 4)
                .offset(
                    x: dotR * Foundation.cos(currentA.radians),
                    y: dotR * Foundation.sin(currentA.radians)
                )
        }
    }
    
    // MARK: - Center Plate
    
    private var centerPlate: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: dialSize * 0.3
                )
            )
            .frame(width: dialSize * 0.6, height: dialSize * 0.6)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    // MARK: - Center Content
    
    private var centerContent: some View {
        VStack(spacing: 4) {
            Text(formattedElapsed)
                .font(.system(size: 36, weight: .bold, design: .rounded))
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

// MARK: - Sector Shape

struct SectorShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.radians, endAngle.radians) }
        set {
            startAngle = .radians(newValue.first)
            endAngle = .radians(newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Plate - 10h into 16:8") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        PlateDialView(
            progress: 10.0 / 16.0,
            elapsed: 10 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date().addingTimeInterval(-10 * 3600)),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}

#Preview("Plate - Early fasting") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        PlateDialView(
            progress: 2.0 / 16.0,
            elapsed: 2 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()),
            isFasting: true,
            isGoalAchieved: false
        )
    }
}

#Preview("Plate - Completed") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        PlateDialView(
            progress: 1.0,
            elapsed: 17 * 3600,
            target: 16 * 3600,
            startTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date().addingTimeInterval(-17 * 3600)),
            isFasting: true,
            isGoalAchieved: true
        )
    }
}
