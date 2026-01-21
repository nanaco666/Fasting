//
//  Theme.swift
//  Fasting
//
//  Design system inspired by Apple Health & Journal
//

import SwiftUI

// MARK: - App Colors

extension Color {
    // Primary gradient colors (Health/Fitness inspired)
    static let fastingGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let fastingTeal = Color(red: 0.35, green: 0.78, blue: 0.98)
    static let fastingBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let fastingOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let fastingPurple = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let fastingPink = Color(red: 1.0, green: 0.18, blue: 0.33)
    
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

// MARK: - Spacing Constants

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius Constants

enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
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
