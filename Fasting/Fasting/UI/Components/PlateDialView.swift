//
//  PlateDialView.swift
//  Fasting
//
//  Plate-style timer — Empty plate with filled sector
//  Arc starts from 12 o'clock (top), sweeps clockwise
//  Hour marks show fasting hours (0h → target)
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
    
    private var targetHours: Int { max(Int(target / 3600), 1) }
    
    var body: some View {
        ZStack {
            plateRing
            fastingSector
            hourMarks
            if isFasting { currentDot }
            centerPlate
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
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(.systemBackground).opacity(0.8), Color.gray.opacity(0.05)],
                        center: .center,
                        startRadius: dialSize * 0.35,
                        endRadius: dialSize * 0.5
                    )
                )
                .frame(width: dialSize, height: dialSize)
            
            Circle()
                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                .frame(width: dialSize, height: dialSize)
            
            Circle()
                .stroke(Color.gray.opacity(0.06), lineWidth: 0.5)
                .frame(width: dialSize * 0.75, height: dialSize * 0.75)
        }
    }
    
    // MARK: - Fasting Sector (starts from top)
    
    private var fastingSector: some View {
        let arcProgress = appeared ? min(progress, 1.0) : 0
        let startA = Angle.degrees(-90) // 12 o'clock
        let sweepDegrees = arcProgress * 360
        
        return ZStack {
            SectorShape(startAngle: startA, endAngle: startA + .degrees(sweepDegrees))
                .fill(sectorGradient(sweep: sweepDegrees))
                .frame(width: dialSize * 0.88, height: dialSize * 0.88)
                .opacity(0.85)
                .animation(.smoothSpring, value: progress)
            
            // Glow at leading edge
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
    
    private func sectorGradient(sweep: Double) -> some ShapeStyle {
        if isGoalAchieved {
            return AnyShapeStyle(
                AngularGradient(
                    colors: [.fastingGreen.opacity(0.5), .fastingTeal.opacity(0.4), .fastingGreen.opacity(0.5)],
                    center: .center
                )
            )
        }
        return AnyShapeStyle(
            AngularGradient(
                colors: [.fastingGreen.opacity(0.5), .fastingTeal.opacity(0.35), .fastingOrange.opacity(0.4)],
                center: .center,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + sweep)
            )
        )
    }
    
    // MARK: - Hour Marks (fasting hours from 0h)
    
    private var hourMarks: some View {
        let outerR = dialSize * 0.44
        let totalH = targetHours
        let majorInterval = totalH <= 12 ? 2 : (totalH <= 24 ? 3 : 6)
        
        return ZStack {
            ForEach(0...totalH, id: \.self) { hour in
                let fraction = Double(hour) / Double(totalH)
                let angle = Angle.degrees(fraction * 360 - 90)
                let isMajor = hour % majorInterval == 0
                let isPast = fraction <= progress
                
                // Tick
                Rectangle()
                    .fill(Color.white.opacity(isPast && isFasting ? 0.8 : (isMajor ? 0.4 : 0.2)))
                    .frame(width: isMajor ? 1.5 : 0.8, height: isMajor ? 8 : 4)
                    .offset(y: -(outerR - (isMajor ? 4 : 2)))
                    .rotationEffect(angle)
                
                // Label
                if isMajor {
                    let labelR = outerR - 18
                    let a = fraction * 2 * .pi - .pi / 2
                    Text("\(hour)h")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(isPast && isFasting ? 0.8 : 0.4))
                        .position(
                            x: dialSize / 2 + labelR * Foundation.cos(a),
                            y: dialSize / 2 + labelR * Foundation.sin(a)
                        )
                }
            }
        }
        .frame(width: dialSize, height: dialSize)
    }
    
    // MARK: - Current Position Dot
    
    private var currentDot: some View {
        let r = dialSize * 0.44
        let arcProgress = min(progress, 1.0)
        let a = -Double.pi / 2 + arcProgress * 2 * .pi
        
        return Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .shadow(color: .white.opacity(0.5), radius: 4)
            .offset(
                x: r * Foundation.cos(a),
                y: r * Foundation.sin(a)
            )
    }
    
    // MARK: - Center Plate
    
    private var centerPlate: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
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

#Preview("Plate - 10h/16h") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        PlateDialView(
            progress: 10.0 / 16.0, elapsed: 10 * 3600, target: 16 * 3600,
            startTime: Date().addingTimeInterval(-10 * 3600), isFasting: true, isGoalAchieved: false
        )
    }
}
