//
//  TimerView.swift
//  Fasting
//
//  Main timer interface - Apple Health/Journal inspired design
//

import SwiftUI
import SwiftData

struct TimerView: View {
    // MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var fastingService = FastingService.shared
    @State private var showPresetSheet = false
    @State private var showConfirmEndSheet = false
    @State private var timer: Timer?
    @State private var currentTime = Date()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background with noise
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Status pill
                        statusPill
                            .padding(.top, Spacing.md)
                        
                        // Main timer ring
                        timerRingSection
                        
                        // Action button
                        actionButton
                            .padding(.horizontal, Spacing.xxxl)
                        
                        // Quick stats
                        quickStatsSection
                            .padding(.horizontal, Spacing.lg)
                    }
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .navigationTitle(L10n.Tab.timer)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .onAppear {
                fastingService.configure(with: modelContext)
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
            .sheet(isPresented: $showPresetSheet) {
                PresetSelectionSheet { preset, customDuration in
                    startFasting(preset: preset, customDuration: customDuration)
                }
                .presentationDetents([.height(400)])
            }
            .confirmationDialog(
                L10n.Timer.confirmEnd,
                isPresented: $showConfirmEndSheet,
                titleVisibility: .visible
            ) {
                Button(L10n.Timer.endFasting, role: .destructive) {
                    endFasting()
                }
                Button(L10n.Timer.cancel, role: .cancel) {}
            } message: {
                Text("\(L10n.Timer.confirmEndMessage) \(formattedCurrentDuration)")
            }
        }
    }
    
    // MARK: - Status Pill
    
    private var statusPill: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(fastingService.isFasting ? Color.fastingGreen : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
                .shadow(color: fastingService.isFasting ? Color.fastingGreen.opacity(0.5) : .clear, radius: 4)
            
            Text(statusText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(fastingService.isFasting ? .primary : .secondary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
    }
    
    // MARK: - Timer Ring Section
    
    private var timerRingSection: some View {
        VStack(spacing: Spacing.lg) {
            // Main progress ring
            ZStack {
                // Outer glow when active
                if fastingService.isFasting {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.fastingGreen.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 100,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 20)
                }
                
                // Progress ring
                TimerProgressRing(
                    progress: currentProgress,
                    isActive: fastingService.isFasting
                ) {
                    // Center content
                    VStack(spacing: Spacing.sm) {
                        // Main time display - use computed property that depends on currentTime
                        Text(formattedCurrentDuration)
                            .font(.system(size: 52, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(fastingService.isFasting ? .primary : .secondary)
                            .contentTransition(.numericText())
                        
                        // Preset name
                        if let preset = fastingService.currentFast?.presetType {
                            Text(preset.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Remaining/Goal info
                        if fastingService.isFasting {
                            if isGoalAchieved {
                                Label(L10n.Timer.goalReached, systemImage: "checkmark.circle.fill")
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(Color.fastingGreen)
                            } else {
                                Text("\(formattedRemainingDuration) \(L10n.Timer.remaining)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .frame(width: 280, height: 280)
            }
            .frame(height: 320)
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            if fastingService.isFasting {
                showConfirmEndSheet = true
            } else {
                showPresetSheet = true
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: fastingService.isFasting ? "stop.fill" : "play.fill")
                    .font(.headline)
                Text(fastingService.isFasting ? L10n.Timer.endFasting : L10n.Timer.startFasting)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                fastingService.isFasting
                    ? AnyShapeStyle(Color.red.gradient)
                    : AnyShapeStyle(LinearGradient(colors: [.fastingGreen, .fastingTeal], startPoint: .leading, endPoint: .trailing))
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .shadow(color: (fastingService.isFasting ? Color.red : Color.fastingGreen).opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(L10n.Timer.quickStats)
                .font(.headline)
                .padding(.horizontal, Spacing.xs)
            
            HStack(spacing: Spacing.md) {
                // Streak card
                QuickStatCard(
                    title: L10n.Timer.currentStreak,
                    value: "\(currentStreak)",
                    unit: L10n.Timer.days,
                    icon: "flame.fill",
                    gradient: AppGradients.streakCard,
                    iconColor: Color.fastingOrange
                )
                
                // This week card
                QuickStatCard(
                    title: L10n.Timer.thisWeek,
                    value: "\(thisWeekCompleted)/7",
                    unit: nil,
                    icon: "checkmark.circle.fill",
                    gradient: AppGradients.progressCard,
                    iconColor: Color.fastingGreen
                )
            }
        }
    }
    
    // MARK: - Computed Properties (Time-dependent)
    
    /// Current duration - recalculates when currentTime changes
    private var calculatedCurrentDuration: TimeInterval {
        guard let startTime = fastingService.currentFast?.startTime,
              fastingService.isFasting else {
            return 0
        }
        // Use currentTime to ensure this recomputes on timer tick
        return currentTime.timeIntervalSince(startTime)
    }
    
    /// Current progress - recalculates when currentTime changes
    private var currentProgress: Double {
        guard fastingService.isFasting,
              let targetDuration = fastingService.currentFast?.targetDuration,
              targetDuration > 0 else {
            return 0
        }
        return min(calculatedCurrentDuration / targetDuration, 1.0)
    }
    
    /// Is goal achieved - based on currentTime
    private var isGoalAchieved: Bool {
        guard let targetDuration = fastingService.currentFast?.targetDuration else {
            return false
        }
        return calculatedCurrentDuration >= targetDuration
    }
    
    /// Remaining duration
    private var remainingDuration: TimeInterval {
        guard let targetDuration = fastingService.currentFast?.targetDuration else {
            return 0
        }
        return max(targetDuration - calculatedCurrentDuration, 0)
    }
    
    private var statusText: String {
        if fastingService.isFasting {
            return isGoalAchieved ? L10n.Timer.goalReached : L10n.Timer.fasting
        }
        return L10n.Timer.notFasting
    }
    
    private var formattedCurrentDuration: String {
        FastingRecord.formatDuration(calculatedCurrentDuration)
    }
    
    private var formattedRemainingDuration: String {
        FastingRecord.formatShortDuration(remainingDuration)
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let completedRecords = records.filter { $0.status == .completed }
        
        while true {
            let hasRecord = completedRecords.contains { record in
                calendar.isDate(record.startTime, inSameDayAs: checkDate)
            }
            
            if hasRecord {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var thisWeekCompleted: Int {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        return records.filter { record in
            record.status == .completed && record.startTime >= weekAgo
        }.count
    }
    
    // MARK: - Actions
    
    private func startFasting(preset: FastingPreset, customDuration: TimeInterval?) {
        fastingService.startFasting(preset: preset, customDuration: customDuration)
        showPresetSheet = false
    }
    
    private func endFasting() {
        fastingService.endFasting()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Timer Progress Ring

struct TimerProgressRing<Content: View>: View {
    let progress: Double
    let isActive: Bool
    @ViewBuilder let content: () -> Content
    
    private let lineWidth: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = (size - lineWidth) / 2
            
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.gray.opacity(0.15),
                        lineWidth: lineWidth
                    )
                
                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: isActive ? [.fastingGreen, .fastingTeal, .fastingGreen] : [.gray.opacity(0.3), .gray.opacity(0.2), .gray.opacity(0.3)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.smoothSpring, value: progress)
                
                // End cap glow
                if progress > 0.01 && isActive {
                    Circle()
                        .fill(Color.fastingTeal)
                        .frame(width: lineWidth, height: lineWidth)
                        .shadow(color: Color.fastingTeal.opacity(0.6), radius: 8)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(360 * min(progress, 1.0) - 90))
                        .animation(.smoothSpring, value: progress)
                }
                
                // Center content
                content()
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let unit: String?
    let icon: String
    let gradient: LinearGradient
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
            
            Spacer()
            
            // Value
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                if let unit = unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(gradient)
        .glassCard(cornerRadius: CornerRadius.large)
    }
}

// MARK: - Preset Selection Sheet (Updated with auto height)

struct PresetSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let onSelect: (FastingPreset, TimeInterval?) -> Void
    
    @State private var selectedPreset: FastingPreset = .sixteen8
    @State private var customHours: Double = 16
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Preset grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    ForEach(FastingPreset.allCases) { preset in
                        PresetCardView(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            withAnimation(.fastSpring) {
                                selectedPreset = preset
                            }
                        }
                    }
                }
                
                // Custom slider
                if selectedPreset == .custom {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text(L10n.Preset.customDuration)
                                .font(.headline)
                            Spacer()
                            Text("\(Int(customHours)) \(L10n.Preset.hours)")
                                .font(.title3.bold())
                                .foregroundStyle(Color.fastingGreen)
                        }
                        
                        Slider(value: $customHours, in: 1...72, step: 1)
                            .tint(Color.fastingGreen)
                    }
                    .padding(Spacing.lg)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                
                // Start button
                Button {
                    let customDuration = selectedPreset == .custom ? customHours * 3600 : nil
                    onSelect(selectedPreset, customDuration)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "play.fill")
                        Text(L10n.Timer.startFasting)
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.fastingGreen, .fastingTeal], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.lg)
            .navigationTitle(L10n.Preset.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Timer.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preset Card View

struct PresetCardView: View {
    let preset: FastingPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Text(preset.displayName)
                    .font(.title3.bold())
                
                Text("\(preset.fastingHours) \(L10n.Preset.hours)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Badge
                if preset == .sixteen8 {
                    Text(L10n.Preset.popular)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.fastingGreen, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(
                isSelected
                    ? AnyShapeStyle(AppGradients.progressCard)
                    : AnyShapeStyle(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isSelected ? Color.fastingGreen : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View (Updated)

struct SettingsView: View {
    @State private var languageManager = LanguageManager.shared
    
    var body: some View {
        List {
            Section(L10n.Settings.fastingSettings) {
                NavigationLink {
                    Text(L10n.Settings.defaultPlan)
                } label: {
                    Label(L10n.Settings.defaultPlan, systemImage: "clock")
                }
                
                NavigationLink {
                    Text(L10n.Settings.notifications)
                } label: {
                    Label(L10n.Settings.notifications, systemImage: "bell")
                }
            }
            
            Section(L10n.Settings.data) {
                Label(L10n.Settings.healthSync, systemImage: "heart")
                Label(L10n.Settings.iCloudSync, systemImage: "icloud")
            }
            
            Section {
                Picker(selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { languageManager.currentLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                } label: {
                    Label(L10n.Settings.language, systemImage: "globe")
                }
            }
            
            Section(L10n.Settings.about) {
                HStack {
                    Label(L10n.Settings.version, systemImage: "info.circle")
                    Spacer()
                    Text("1.1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.Settings.title)
    }
}

// MARK: - Preview

#Preview {
    TimerView()
        .modelContainer(for: FastingRecord.self, inMemory: true)
}
