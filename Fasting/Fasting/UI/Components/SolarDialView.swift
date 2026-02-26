//
//  SolarDialView.swift
//  Fasting
//
//  Solar Dial inspired — premium dark-mode fasting timer
//  Multi-ring, light wedge with gradient falloff, fine tick marks
//

import SwiftUI

struct SolarDialView: View {
    let progress: Double
    let elapsed: TimeInterval
    let target: TimeInterval
    let startTime: Date?
    let isFasting: Bool
    let isGoalAchieved: Bool
    
    @State private var breathePhase: CGFloat = 0
    @State private var appeared = false
    
    private let size: CGFloat = 290
    private var targetHours: Int { max(Int(target / 3600), 1) }
    
    // Rings (outside → inside)
    private var outerR: CGFloat { size / 2 }           // 145
    private var tickRingR: CGFloat { size / 2 - 8 }     // 137 — fine ticks
    private var majorRingR: CGFloat { size / 2 - 24 }   // 121 — hour numbers
    private var wedgeR: CGFloat { size / 2 - 36 }       // 109 — light wedge
    private var innerRingR: CGFloat { size / 2 * 0.42 } // 61  — center plate
    
    var body: some View {
        ZStack {
            // Layer 1: Outer bezel
            outerBezel
            
            // Layer 2: Fine tick marks (60 divisions)
            fineTicks
            
            // Layer 3: Hour marks + labels
            hourMarks
            
            // Layer 4: Light wedge (the hero)
            lightWedge
            
            // Layer 5: Sun/progress indicator
            progressIndicator
            
            // Layer 6: Inner circle
            innerCircle
            
            // Layer 7: Center content
            centerContent
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathePhase = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
    
    // MARK: - Layer 1: Outer Bezel
    
    private var outerBezel: some View {
        ZStack {
            // Dark base
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: size, height: size)
            
            // Subtle metallic rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(white: 0.25), Color(white: 0.12), Color(white: 0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size, height: size)
            
            // Inner rim
            Circle()
                .stroke(Color(white: 0.15), lineWidth: 0.5)
                .frame(width: size - 16, height: size - 16)
        }
    }
    
    // MARK: - Layer 2: Fine Ticks (60 divisions)
    
    private var fineTicks: some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outerTick = tickRingR
            
            for i in 0..<120 {
                let fraction = Double(i) / 120
                let angle = fraction * 2 * .pi - .pi / 2
                let isMajor = i % 10 == 0   // every 10th = hour mark position
                let isMid = i % 5 == 0       // every 5th = half mark
                
                let len: CGFloat = isMajor ? 8 : (isMid ? 5 : 3)
                let width: CGFloat = isMajor ? 1.2 : (isMid ? 0.8 : 0.5)
                let alpha: CGFloat = isMajor ? 0.6 : (isMid ? 0.35 : 0.18)
                
                let outer = CGPoint(
                    x: center.x + outerTick * Foundation.cos(angle),
                    y: center.y + outerTick * Foundation.sin(angle)
                )
                let inner = CGPoint(
                    x: center.x + (outerTick - len) * Foundation.cos(angle),
                    y: center.y + (outerTick - len) * Foundation.sin(angle)
                )
                
                var path = Path()
                path.move(to: outer)
                path.addLine(to: inner)
                ctx.stroke(path, with: .color(.white.opacity(alpha)), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Layer 3: Hour Marks + Labels
    
    private var hourMarks: some View {
        let totalH = targetHours
        let interval = totalH <= 12 ? 2 : (totalH <= 24 ? 4 : 6)
        
        return ZStack {
            ForEach(Array(stride(from: 0, through: totalH, by: interval)), id: \.self) { hour in
                let fraction = Double(hour) / Double(totalH)
                let a = fraction * 2 * .pi - .pi / 2
                let isPast = fraction <= progress && isFasting
                
                // Hour label
                Text("\(hour)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(isPast ? 0.9 : 0.35))
                    .position(
                        x: size / 2 + majorRingR * Foundation.cos(a),
                        y: size / 2 + majorRingR * Foundation.sin(a)
                    )
            }
        }
        .frame(width: size, height: size)
    }
    
    // MARK: - Layer 4: Light Wedge (Solar Dial hero effect)
    
    private var lightWedge: some View {
        let arcProgress = appeared ? min(progress, 1.0) : 0
        
        return Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = wedgeR
            let startA = -Double.pi / 2
            let sweep = arcProgress * 2 * .pi
            
            guard sweep > 0.005 else { return }
            
            // Draw the wedge as radial segments with light falloff
            let segments = max(Int(sweep / 0.008), 8)
            
            for i in 0..<segments {
                let t = Double(i) / Double(segments)
                let nextT = Double(i + 1) / Double(segments)
                let a0 = startA + t * sweep
                let a1 = startA + nextT * sweep
                
                // Light intensity: brightest at leading edge, fades toward start
                // Simulates sunlight casting across the dial
                let intensity = lightIntensity(t: t)
                
                // Color: warm highlight at bright end, cool blue at dim end
                let color = wedgeColor(intensity: intensity, t: t)
                
                // Draw filled sector segment
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                path.closeSubpath()
                
                ctx.fill(path, with: .color(color))
            }
            
            // Soft edge glow at the leading edge
            if isFasting && !isGoalAchieved {
                let edgeA = startA + sweep
                let glowCenter = CGPoint(
                    x: center.x + (radius * 0.7) * Foundation.cos(edgeA),
                    y: center.y + (radius * 0.7) * Foundation.sin(edgeA)
                )
                let glowSize: CGFloat = 30
                let glowRect = CGRect(
                    x: glowCenter.x - glowSize / 2,
                    y: glowCenter.y - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                )
                ctx.fill(
                    Circle().path(in: glowRect),
                    with: .color(isGoalAchieved ? .fastingTeal.opacity(0.2) : .fastingGreen.opacity(0.15 + breathePhase * 0.1))
                )
            }
        }
        .frame(width: size, height: size)
        .blur(radius: 0.5) // Subtle softness to the wedge edges
    }
    
    /// Light intensity curve — bright at leading edge (current time), dim at start
    private func lightIntensity(t: Double) -> Double {
        // t=0 is start (oldest), t=1 is leading edge (current)
        // Exponential falloff from bright to dim
        let base = pow(t, 0.6)  // 0.6 exponent = slower falloff at start, brighter at end
        return 0.05 + base * 0.55  // range: 0.05 → 0.6
    }
    
    /// Wedge color — warm green/teal at bright, deep blue at dim
    private func wedgeColor(intensity: Double, t: Double) -> Color {
        if isGoalAchieved {
            return Color(
                red: 0.1 * intensity,
                green: 0.85 * intensity,
                blue: 0.65 * intensity
            ).opacity(intensity * 1.2)
        }
        // Gradient: deep teal (start) → bright green (current)
        let r = (0.05 + t * 0.15) * intensity
        let g = (0.4 + t * 0.45) * intensity
        let b = (0.5 - t * 0.2) * intensity
        return Color(red: r, green: g, blue: b).opacity(intensity * 1.3)
    }
    
    // MARK: - Layer 5: Progress Indicator (sun dot)
    
    private var progressIndicator: some View {
        let arcProgress = min(progress, 1.0)
        let a = -Double.pi / 2 + arcProgress * 2 * .pi
        let dotR = wedgeR + 4
        
        return Group {
            if isFasting && arcProgress > 0.005 {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.white.opacity(0.15 + breathePhase * 0.1))
                        .frame(width: 16, height: 16)
                        .blur(radius: 4)
                    
                    // Core dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                    
                    // Inner bright
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3, height: 3)
                }
                .offset(
                    x: dotR * Foundation.cos(a),
                    y: dotR * Foundation.sin(a)
                )
            }
        }
    }
    
    // MARK: - Layer 6: Inner Circle
    
    private var innerCircle: some View {
        ZStack {
            // Dark center plate
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.12), Color(white: 0.06)],
                        center: .center,
                        startRadius: 0,
                        endRadius: innerRingR
                    )
                )
                .frame(width: innerRingR * 2, height: innerRingR * 2)
            
            // Subtle rim
            Circle()
                .stroke(Color(white: 0.2), lineWidth: 0.5)
                .frame(width: innerRingR * 2, height: innerRingR * 2)
            
            // Inner fine ticks (minute markers on center ring)
            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                for i in 0..<60 {
                    let angle = Double(i) / 60 * 2 * .pi - .pi / 2
                    let isMajor = i % 5 == 0
                    let len: CGFloat = isMajor ? 4 : 2
                    let alpha: CGFloat = isMajor ? 0.4 : 0.15
                    
                    let outer = CGPoint(
                        x: center.x + innerRingR * Foundation.cos(angle),
                        y: center.y + innerRingR * Foundation.sin(angle)
                    )
                    let inner = CGPoint(
                        x: center.x + (innerRingR - len) * Foundation.cos(angle),
                        y: center.y + (innerRingR - len) * Foundation.sin(angle)
                    )
                    
                    var path = Path()
                    path.move(to: outer)
                    path.addLine(to: inner)
                    ctx.stroke(path, with: .color(.white.opacity(alpha)), style: StrokeStyle(lineWidth: isMajor ? 0.8 : 0.4, lineCap: .round))
                }
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Layer 7: Center Content
    
    private var centerContent: some View {
        VStack(spacing: 3) {
            Text(formattedElapsed)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
            
            if isFasting {
                if isGoalAchieved {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .symbolEffect(.bounce, value: isGoalAchieved)
                        Text("COMPLETED")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color.fastingGreen)
                    .tracking(1.5)
                } else {
                    Text(formattedRemaining)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .monospacedDigit()
                }
            } else {
                Text("LAST FAST")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
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

#Preview("Solar - 10h/16h") {
    ZStack {
        Color.black.ignoresSafeArea()
        SolarDialView(
            progress: 10.0 / 16.0, elapsed: 10 * 3600, target: 16 * 3600,
            startTime: Date().addingTimeInterval(-10 * 3600), isFasting: true, isGoalAchieved: false
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Solar - 2h/16h (early)") {
    ZStack {
        Color.black.ignoresSafeArea()
        SolarDialView(
            progress: 2.0 / 16.0, elapsed: 2 * 3600, target: 16 * 3600,
            startTime: Date().addingTimeInterval(-2 * 3600), isFasting: true, isGoalAchieved: false
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Solar - Completed") {
    ZStack {
        Color.black.ignoresSafeArea()
        SolarDialView(
            progress: 1.0, elapsed: 17 * 3600, target: 16 * 3600,
            startTime: Date().addingTimeInterval(-17 * 3600), isFasting: true, isGoalAchieved: true
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Solar - Idle") {
    ZStack {
        Color.black.ignoresSafeArea()
        SolarDialView(
            progress: 0.85, elapsed: 14 * 3600, target: 16 * 3600,
            startTime: nil, isFasting: false, isGoalAchieved: false
        )
    }
    .preferredColorScheme(.dark)
}
