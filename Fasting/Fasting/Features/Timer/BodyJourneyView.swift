//
//  BodyJourneyView.swift
//  Fasting
//
//  断食阶段可视化 — 身体旅程
//

import SwiftUI

// MARK: - Body Journey Card (嵌入TimerView)

struct BodyJourneyCard: View {
    let duration: TimeInterval
    let isFasting: Bool
    
    @State private var isExpanded = false
    
    private var currentPhase: FastingPhase {
        FastingPhaseManager.currentPhase(for: duration)
    }
    
    private var phaseProgress: Double {
        FastingPhaseManager.phaseProgress(for: duration)
    }
    
    private var unlockedPhases: [FastingPhase] {
        FastingPhaseManager.unlockedPhases(for: duration)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Current phase header — always visible
            currentPhaseHeader
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.smoothSpring) {
                        isExpanded.toggle()
                    }
                }
            
            // Expanded: full journey timeline
            if isExpanded {
                Divider()
                    .padding(.horizontal, Spacing.lg)
                
                journeyTimeline
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom),
                        removal: .push(from: .top)
                    ))
            }
        }
        .glassCard(cornerRadius: CornerRadius.large)
        .animation(.smoothSpring, value: isExpanded)
    }
    
    // MARK: - Current Phase Header
    
    private var currentPhaseHeader: some View {
        HStack(spacing: Spacing.md) {
            // Phase icon with progress ring
            ZStack {
                Circle()
                    .stroke(currentPhase.color.opacity(0.2), lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: isFasting ? phaseProgress : 0)
                    .stroke(currentPhase.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.smoothSpring, value: phaseProgress)
                
                Image(systemName: currentPhase.icon)
                    .font(.system(size: 28).weight(.semibold))
                    .foregroundStyle(currentPhase.color)
            }
            
            // Phase info
            VStack(alignment: .leading, spacing: 2) {
                Text(currentPhase.name)
                    .font(.subheadline.weight(.semibold))
                
                Text(currentPhase.companionMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Next phase indicator
            if isFasting, let timeToNext = FastingPhaseManager.timeToNextPhase(for: duration) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next".localized)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Text(formatShortTime(timeToNext))
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            // Expand chevron
            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .padding(Spacing.lg)
        .background(
            isFasting ? currentPhase.color.opacity(0.08) : Color.clear
        )
    }
    
    // MARK: - Journey Timeline
    
    private var journeyTimeline: some View {
        VStack(spacing: 0) {
            ForEach(FastingPhaseManager.phases) { phase in
                let isUnlocked = duration / 3600 >= phase.startHour
                let isCurrent = phase.id == currentPhase.id
                
                PhaseTimelineRow(
                    phase: phase,
                    isUnlocked: isUnlocked,
                    isCurrent: isCurrent && isFasting,
                    duration: duration
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    // MARK: - Helpers
    
    private func formatShortTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Phase Timeline Row

struct PhaseTimelineRow: View {
    let phase: FastingPhase
    let isUnlocked: Bool
    let isCurrent: Bool
    let duration: TimeInterval
    
    @State private var showDetail = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline connector
            VStack(spacing: 0) {
                // Dot
                ZStack {
                    if isCurrent {
                        Circle()
                            .fill(phase.color.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .fill(phase.color)
                            .frame(width: 12, height: 12)
                            .shadow(color: phase.color.opacity(0.4), radius: 4)
                    } else if isUnlocked {
                        Circle()
                            .fill(phase.color)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 10, height: 10)
                    }
                }
                .frame(width: 28, height: 28)
                
                // Connector line
                if phase.id < FastingPhaseManager.phases.count - 1 {
                    Rectangle()
                        .fill(isUnlocked ? phase.color.opacity(0.3) : Color.gray.opacity(0.15))
                        .frame(width: 2)
                        .frame(minHeight: showDetail ? 120 : 36)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: Spacing.sm) {
                            Text(phase.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(isUnlocked ? .primary : .tertiary)
                            
                            if isCurrent {
                                Text("NOW".localized)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(phase.color, in: Capsule())
                            }
                        }
                        
                        Text(phaseTimeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isUnlocked {
                        Button {
                            withAnimation(.fastSpring) {
                                showDetail.toggle()
                            }
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundStyle(phase.color.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Subtitle
                Text(phase.companionMessage)
                    .font(.subheadline)
                    .foregroundStyle(isUnlocked ? .secondary : .quaternary)
                
                // Warning banner for 36h+ phases
                if phase.startHour >= 36 && isUnlocked {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.fastingOrange)
                        Text(phase.startHour >= 48 ? "Medical supervision required".localized : "Listen to your body carefully".localized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.fastingOrange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.fastingOrange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                
                // Expanded detail
                if showDetail && isUnlocked {
                    phaseDetail
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(.bottom, Spacing.md)
        }
    }
    
    // MARK: - Phase Detail
    
    private var phaseDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Key events
            ForEach(phase.keyEvents) { event in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: event.icon)
                        .font(.caption)
                        .foregroundStyle(phase.color)
                        .frame(width: 16)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(event.title)
                            .font(.caption.weight(.semibold))
                        
                        Text(event.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            // Description
            Text(phase.scienceDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(phase.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        .padding(.top, Spacing.xs)
    }
    
    // MARK: - Helpers
    
    private var phaseTimeRange: String {
        let start = Int(phase.startHour)
        if phase.endHour == .infinity {
            return "\(start)h+"
        }
        return "\(start)h — \(Int(phase.endHour))h"
    }
}

// MARK: - Idle State (not fasting)

struct BodyJourneyIdleCard: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "figure.walk")
                .font(.title2)
                .foregroundStyle(.tertiary)
                .symbolEffect(.wiggle.byLayer, options: .repeat(.continuous))
            
            Text("Start fasting to begin your body's journey".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Phase preview
            HStack(spacing: Spacing.lg) {
                ForEach(FastingPhaseManager.phases.prefix(4)) { phase in
                    VStack(spacing: 4) {
                        Image(systemName: phase.icon)
                            .font(.caption)
                            .foregroundStyle(phase.color.opacity(0.4))
                        
                        Text("\(Int(phase.startHour))h")
                            .font(.caption2)
                            .foregroundStyle(.quaternary)
                    }
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: CornerRadius.large)
    }
}

// MARK: - Preview

#Preview("Body Journey - Fasting 14h") {
    ZStack {
        GradientBackground()
        
        ScrollView {
            VStack(spacing: 16) {
                BodyJourneyCard(
                    duration: 14 * 3600,  // 14 hours
                    isFasting: true
                )
                .padding(.horizontal)
            }
        }
    }
}

#Preview("Body Journey - Idle") {
    ZStack {
        GradientBackground()
        
        BodyJourneyIdleCard()
            .padding(.horizontal)
    }
}
