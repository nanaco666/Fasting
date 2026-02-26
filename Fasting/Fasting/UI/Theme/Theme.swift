//
//  Theme.swift
//  Fasting
//
//  Design system inspired by Apple Health & Journal
//

import SwiftUI

// MARK: - App Colors

extension Color {
    // Primary palette — 3 colors only (ADA discipline)
    // Hero: system green (adapts to light/dark automatically)
    static let fastingGreen = Color.green
    // Accent: warm teal for secondary elements
    static let fastingTeal = Color.teal
    // Alert: system orange for warnings/streaks
    static let fastingOrange = Color.orange
    
    // Legacy aliases (will remove after full migration)
    static let fastingBlue = Color.blue
    static let fastingPurple = Color.purple
    static let fastingPink = Color.pink
    
    // Semantic colors
    static let fastingActive = Color.fastingGreen
    static let fastingComplete = Color.fastingTeal
    static let streakFire = Color.fastingOrange
}

// MARK: - Gradients

struct AppGradients {
    // Main timer gradient
    static let timerActive = LinearGradient(
        colors: [.fastingGreen, .fastingTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let timerInactive = LinearGradient(
        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Background gradients (subtle, like Journal)
    static let backgroundLight = LinearGradient(
        colors: [
            Color(red: 0.98, green: 0.98, blue: 1.0),
            Color(red: 0.95, green: 0.97, blue: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let backgroundDark = LinearGradient(
        colors: [
            Color(red: 0.11, green: 0.11, blue: 0.12),
            Color(red: 0.08, green: 0.08, blue: 0.09)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Card gradients
    static let streakCard = LinearGradient(
        colors: [.fastingOrange.opacity(0.15), .fastingOrange.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let progressCard = LinearGradient(
        colors: [.fastingGreen.opacity(0.15), .fastingTeal.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let statsCard = LinearGradient(
        colors: [.fastingBlue.opacity(0.12), .fastingPurple.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Noise Texture

struct NoiseTexture: View {
    var opacity: Double = 0.03
    
    var body: some View {
        GeometryReader { geometry in
            Image(systemName: "circle.fill")
                .resizable()
                .foregroundStyle(.white.opacity(opacity))
                .frame(width: 1, height: 1)
                .blur(radius: 0)
                .drawingGroup()
                .overlay {
                    Canvas { context, size in
                        for _ in 0..<Int(size.width * size.height * 0.02) {
                            let x = Double.random(in: 0..<size.width)
                            let y = Double.random(in: 0..<size.height)
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                                with: .color(.white.opacity(Double.random(in: 0.02...0.06)))
                            )
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Gradient Background View

struct GradientBackground: View {
    @Environment(\.colorScheme) var colorScheme
    var addNoise: Bool = true
    
    var body: some View {
        ZStack {
            // Base gradient
            (colorScheme == .dark ? AppGradients.backgroundDark : AppGradients.backgroundLight)
                .ignoresSafeArea()
            
            // Subtle noise texture
            if addNoise {
                NoiseTexture(opacity: colorScheme == .dark ? 0.04 : 0.025)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Glass Card Style

struct GlassCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Tinted Card Style

struct TintedCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var tint: Color = .clear
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tint.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    }
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 12, x: 0, y: 6)
            }
    }
}

extension View {
    func tintedCard(_ tint: Color = .clear, cornerRadius: CGFloat = 20) -> some View {
        modifier(TintedCard(tint: tint, cornerRadius: cornerRadius))
    }
}

// MARK: - Typography

enum AppFont {
    static func hero(_ size: CGFloat = 56) -> Font {
        .system(size: size, weight: .light, design: .rounded)
    }
    static func stat(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func label() -> Font {
        .caption.weight(.medium)
    }
}

// MARK: - Spacing Constants

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16   // was 12
    static let lg: CGFloat = 24   // was 16
    static let xl: CGFloat = 32   // was 20
    static let xxl: CGFloat = 40  // was 24
    static let xxxl: CGFloat = 56 // was 32
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 28
    static let full: CGFloat = 9999
}

// MARK: - Animation Presets

extension Animation {
    static let fastSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.85)
}

// MARK: - Preview

#Preview("Theme Preview") {
    ZStack {
        GradientBackground()
        
        VStack(spacing: 20) {
            // Gradient samples
            HStack(spacing: 12) {
                Circle()
                    .fill(AppGradients.timerActive)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(Color.fastingGreen)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(Color.fastingOrange)
                    .frame(width: 60, height: 60)
            }
            
            // Glass card sample
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .font(.headline)
                Text("With subtle blur and shadow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
            .padding(.horizontal)
        }
    }
}
