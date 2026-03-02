//
//  AuthView.swift
//  Fasting
//
//  Welcome + Apple Sign In screen
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @ObservedObject private var auth = AuthService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showContent = false
    @State private var showButtons = false
    
    private var themeColor: Color { ThemeManager.shared.currentTheme.progressColor }
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Hero
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 64))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(themeColor)
                        .symbolEffect(.breathe, options: .repeating)
                    
                    VStack(spacing: Spacing.sm) {
                        Text("auth_welcome_title".localized)
                            .font(.largeTitle.bold())
                        
                        Text("auth_welcome_subtitle".localized)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Features
                VStack(spacing: Spacing.md) {
                    featureRow(icon: "timer", color: themeColor,
                               title: "auth_feature_timer".localized,
                               subtitle: "auth_feature_timer_desc".localized)
                    featureRow(icon: "chart.line.uptrend.xyaxis", color: .fastingOrange,
                               title: "auth_feature_insights".localized,
                               subtitle: "auth_feature_insights_desc".localized)
                    featureRow(icon: "icloud.fill", color: .fastingTeal,
                               title: "auth_feature_sync".localized,
                               subtitle: "auth_feature_sync_desc".localized)
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)
                
                Spacer()
                
                // Buttons
                VStack(spacing: Spacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        auth.handleAuthorization(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 54)
                    .cornerRadius(16)
                    
                    Button {
                        auth.skipSignIn()
                    } label: {
                        Text("auth_skip".localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 10)
                
                Text("auth_privacy_note".localized)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 16)
                    .opacity(showButtons ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showButtons = true
            }
        }
    }
    
    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AuthView()
}
