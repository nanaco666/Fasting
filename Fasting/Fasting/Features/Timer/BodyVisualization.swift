//
//  BodyVisualization.swift
//  Fasting
//
//  ADA-level animated body visualization
//  Shows metabolic processes in real-time during fasting
//

import SwiftUI

// MARK: - Particle

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var color: Color
    var velocity: CGSize
    var lifetime: Double
    var age: Double = 0
}

// MARK: - Body Visualization View

struct BodyVisualizationView: View {
    let duration: TimeInterval
    let isFasting: Bool
    
    @State private var particles: [Particle] = []
    @State private var animationPhase: Double = 0
    @State private var timer: Timer?
    
    private var hours: Double { duration / 3600 }
    
    private var currentPhase: FastingPhase {
        FastingPhaseManager.currentPhase(for: duration)
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Body silhouette
                bodySilhouette(w: w, h: h)
                
                // Metabolic particles
                TimelineView(.animation(minimumInterval: 1/30)) { context in
                    Canvas { ctx, size in
                        for particle in particles {
                            let rect = CGRect(
                                x: particle.x - particle.size/2,
                                y: particle.y - particle.size/2,
                                width: particle.size,
                                height: particle.size
                            )
                            ctx.opacity = particle.opacity * (1 - particle.age / particle.lifetime)
                            ctx.fill(Circle().path(in: rect), with: .color(particle.color))
                        }
                    }
                    .onChange(of: context.date) { _, _ in
                        updateParticles(w: w, h: h)
                    }
                }
                
                // Organ highlights
                organHighlights(w: w, h: h)
                
                // Phase label
                VStack {
                    Spacer()
                    phaseIndicator
                }
            }
        }
        .onAppear { startParticleSystem() }
        .onDisappear { stopParticleSystem() }
    }
    
    // MARK: - Body Silhouette
    
    private func bodySilhouette(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Outer body glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [currentPhase.color.opacity(0.08), .clear],
                        center: .center,
                        startRadius: w * 0.1,
                        endRadius: w * 0.45
                    )
                )
                .frame(width: w * 0.7, height: h * 0.85)
            
            // Body outline
            BodyShape()
                .stroke(
                    currentPhase.color.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
                .frame(width: w * 0.45, height: h * 0.8)
            
            // Inner body fill with phase-dependent opacity
            BodyShape()
                .fill(
                    LinearGradient(
                        colors: [
                            currentPhase.color.opacity(hours > 12 ? 0.06 : 0.03),
                            currentPhase.color.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: w * 0.45, height: h * 0.8)
        }
    }
    
    // MARK: - Organ Highlights
    
    private func organHighlights(w: CGFloat, h: CGFloat) -> some View {
        let cx = w / 2
        
        return ZStack {
            // Brain (top) — ketone activity after 12h
            if hours > 12 {
                PulsingOrgan(
                    position: CGPoint(x: cx, y: h * 0.12),
                    size: 24,
                    color: .blue,
                    intensity: min((hours - 12) / 12, 1.0)
                )
            }
            
            // Liver (center-right) — glycogen then ketone production
            PulsingOrgan(
                position: CGPoint(x: cx + w * 0.06, y: h * 0.35),
                size: 20,
                color: hours < 12 ? .orange : .blue,
                intensity: hours < 4 ? 0.8 : (hours < 12 ? max(0.2, 1 - hours/12) : min(hours/24, 0.9))
            )
            
            // Stomach (center-left) — shrinks over time
            PulsingOrgan(
                position: CGPoint(x: cx - w * 0.04, y: h * 0.38),
                size: max(10, 18 - hours * 0.5),
                color: .green,
                intensity: max(0.1, 1 - hours/16)
            )
            
            // Fat cells (sides) — activate after 4h
            if hours > 4 {
                let fatIntensity = min((hours - 4) / 20, 0.9)
                
                PulsingOrgan(
                    position: CGPoint(x: cx - w * 0.12, y: h * 0.45),
                    size: 16,
                    color: .orange,
                    intensity: fatIntensity
                )
                PulsingOrgan(
                    position: CGPoint(x: cx + w * 0.12, y: h * 0.45),
                    size: 16,
                    color: .orange,
                    intensity: fatIntensity
                )
            }
            
            // Cells (scattered) — autophagy after 24h
            if hours > 24 {
                let autoIntensity = min((hours - 24) / 24, 0.8)
                
                ForEach(0..<3, id: \.self) { i in
                    let positions: [CGPoint] = [
                        CGPoint(x: cx, y: h * 0.28),
                        CGPoint(x: cx - w * 0.08, y: h * 0.55),
                        CGPoint(x: cx + w * 0.08, y: h * 0.55),
                    ]
                    AutophagyBubble(
                        position: positions[i],
                        intensity: autoIntensity
                    )
                }
            }
        }
    }
    
    // MARK: - Phase Indicator
    
    private var phaseIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentPhase.color)
                .frame(width: 8, height: 8)
            
            Text(currentPhase.name)
                .font(.caption.weight(.semibold))
            
            Text("·")
                .foregroundStyle(.tertiary)
            
            Text(currentPhase.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    // MARK: - Particle System
    
    private func startParticleSystem() {
        guard isFasting else { return }
        // Particles are spawned in updateParticles
    }
    
    private func stopParticleSystem() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateParticles(w: CGFloat, h: CGFloat) {
        guard isFasting else { 
            particles.removeAll()
            return
        }
        
        let cx = w / 2
        let dt: Double = 1/30
        
        // Age and remove dead particles
        particles = particles.compactMap { var p = $0
            p.age += dt
            if p.age >= p.lifetime { return nil }
            p.x += p.velocity.width * dt
            p.y += p.velocity.height * dt
            return p
        }
        
        // Spawn new particles based on phase
        let maxParticles = 60
        guard particles.count < maxParticles else { return }
        
        // Glycogen particles (0-12h) — orange, from liver area, drift down
        if hours < 12 {
            let rate = max(0.3, 1 - hours/12)
            if Double.random(in: 0...1) < rate * 0.3 {
                particles.append(Particle(
                    x: cx + CGFloat.random(in: -10...10),
                    y: h * 0.35 + CGFloat.random(in: -5...5),
                    size: CGFloat.random(in: 3...5),
                    opacity: 0.6,
                    color: .orange.opacity(0.8),
                    velocity: CGSize(width: CGFloat.random(in: -15...15), height: CGFloat.random(in: 10...30)),
                    lifetime: Double.random(in: 1.5...3)
                ))
            }
        }
        
        // Fat burning particles (4h+) — yellow-orange, from sides, drift to center
        if hours > 4 {
            let rate = min((hours - 4) / 20, 0.8)
            if Double.random(in: 0...1) < rate * 0.2 {
                let side: CGFloat = Bool.random() ? -1 : 1
                particles.append(Particle(
                    x: cx + side * w * 0.12 + CGFloat.random(in: -5...5),
                    y: h * 0.45 + CGFloat.random(in: -10...10),
                    size: CGFloat.random(in: 2...4),
                    opacity: 0.5,
                    color: Color(hue: 0.08, saturation: 0.9, brightness: 0.95),
                    velocity: CGSize(width: -side * CGFloat.random(in: 8...20), height: CGFloat.random(in: -10...10)),
                    lifetime: Double.random(in: 2...4)
                ))
            }
        }
        
        // Ketone particles (12h+) — blue, from liver to brain
        if hours > 12 {
            let rate = min((hours - 12) / 12, 0.7)
            if Double.random(in: 0...1) < rate * 0.25 {
                particles.append(Particle(
                    x: cx + CGFloat.random(in: -8...8),
                    y: h * 0.35,
                    size: CGFloat.random(in: 2...4),
                    opacity: 0.7,
                    color: .blue.opacity(0.7),
                    velocity: CGSize(width: CGFloat.random(in: -5...5), height: CGFloat.random(in: (-25)...(-10))),
                    lifetime: Double.random(in: 2...5)
                ))
            }
        }
        
        // Autophagy sparkles (24h+) — purple/white, scattered pops
        if hours > 24 {
            if Double.random(in: 0...1) < 0.15 {
                particles.append(Particle(
                    x: cx + CGFloat.random(in: -w*0.15...w*0.15),
                    y: h * CGFloat.random(in: 0.2...0.6),
                    size: CGFloat.random(in: 1.5...3),
                    opacity: 0.9,
                    color: [Color.purple.opacity(0.8), .white, .blue.opacity(0.6)].randomElement()!,
                    velocity: CGSize(width: CGFloat.random(in: -5...5), height: CGFloat.random(in: -5...5)),
                    lifetime: Double.random(in: 0.5...1.5)
                ))
            }
        }
    }
}

// MARK: - Body Shape (simplified human silhouette)

struct BodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        
        // Head
        path.addEllipse(in: CGRect(x: cx - w*0.15, y: 0, width: w*0.3, height: h*0.15))
        
        // Neck
        path.move(to: CGPoint(x: cx - w*0.06, y: h*0.14))
        path.addLine(to: CGPoint(x: cx - w*0.06, y: h*0.18))
        path.move(to: CGPoint(x: cx + w*0.06, y: h*0.14))
        path.addLine(to: CGPoint(x: cx + w*0.06, y: h*0.18))
        
        // Torso
        path.move(to: CGPoint(x: cx - w*0.2, y: h*0.18))
        path.addQuadCurve(
            to: CGPoint(x: cx - w*0.25, y: h*0.22),
            control: CGPoint(x: cx - w*0.3, y: h*0.18)
        )
        // Left arm hint
        path.addQuadCurve(
            to: CGPoint(x: cx - w*0.35, y: h*0.45),
            control: CGPoint(x: cx - w*0.32, y: h*0.35)
        )
        path.move(to: CGPoint(x: cx - w*0.22, y: h*0.25))
        path.addQuadCurve(
            to: CGPoint(x: cx - w*0.18, y: h*0.55),
            control: CGPoint(x: cx - w*0.22, y: h*0.4)
        )
        // Hip
        path.addQuadCurve(
            to: CGPoint(x: cx - w*0.15, y: h*0.6),
            control: CGPoint(x: cx - w*0.18, y: h*0.58)
        )
        // Left leg
        path.addQuadCurve(
            to: CGPoint(x: cx - w*0.12, y: h*0.95),
            control: CGPoint(x: cx - w*0.16, y: h*0.8)
        )
        path.addLine(to: CGPoint(x: cx - w*0.05, y: h*0.95))
        
        // Right side (mirror)
        path.move(to: CGPoint(x: cx + w*0.2, y: h*0.18))
        path.addQuadCurve(
            to: CGPoint(x: cx + w*0.25, y: h*0.22),
            control: CGPoint(x: cx + w*0.3, y: h*0.18)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx + w*0.35, y: h*0.45),
            control: CGPoint(x: cx + w*0.32, y: h*0.35)
        )
        path.move(to: CGPoint(x: cx + w*0.22, y: h*0.25))
        path.addQuadCurve(
            to: CGPoint(x: cx + w*0.18, y: h*0.55),
            control: CGPoint(x: cx + w*0.22, y: h*0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx + w*0.15, y: h*0.6),
            control: CGPoint(x: cx + w*0.18, y: h*0.58)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx + w*0.12, y: h*0.95),
            control: CGPoint(x: cx + w*0.16, y: h*0.8)
        )
        path.addLine(to: CGPoint(x: cx + w*0.05, y: h*0.95))
        
        return path
    }
}

// MARK: - Pulsing Organ

struct PulsingOrgan: View {
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let intensity: Double
    
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(intensity * 0.15))
                .frame(width: size * 2.5, height: size * 2.5)
                .scaleEffect(pulse ? 1.2 : 0.9)
            
            // Core
            Circle()
                .fill(color.opacity(intensity * 0.4))
                .frame(width: size, height: size)
                .shadow(color: color.opacity(intensity * 0.5), radius: size * 0.5)
        }
        .position(position)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Autophagy Bubble

struct AutophagyBubble: View {
    let position: CGPoint
    let intensity: Double
    
    @State private var scale: CGFloat = 1
    @State private var visible = true
    
    var body: some View {
        Circle()
            .stroke(Color.purple.opacity(intensity * 0.5), lineWidth: 1)
            .frame(width: 14, height: 14)
            .scaleEffect(scale)
            .opacity(visible ? intensity : 0)
            .position(position)
            .onAppear {
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                    scale = 0.3
                    visible = false
                }
            }
    }
}
