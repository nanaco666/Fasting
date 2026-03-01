//
//  TimerView.swift
//  Fasting
//

import SwiftUI
import SwiftData

private enum TimerFormatters {
    static let timeShort: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, HH:mm"; return f
    }()
    static let hourMinute: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
}

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @State private var fastingService = FastingService.shared
    @State private var showPresetSheet = false
    @State private var showConfirmEnd = false
    @State private var showEditStart = false
    @State private var editedStartTime = Date()
    @State private var showEditGoal = false
    @State private var editedGoalHours: Double = 16
    @State private var hasShownGoalCelebration = false
    @State private var showMoodCheckIn = false
    @State private var showRefeedGuide = false
    @State private var lastFastDuration: TimeInterval = 0
    @State private var lastFastGoalMet = false
    @AppStorage("timerDialStyle") private var dialStyleRaw: String = TimerDialStyle.simple.rawValue
    
    private var dialStyle: TimerDialStyle {
        TimerDialStyle(rawValue: dialStyleRaw) ?? .simple
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                TableclothBackground(theme: ThemeManager.shared.currentTheme)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Timer card (dial + pills + action button — all in one)
                        timerCard
                            .padding(.horizontal, 20)
                        
                        // Health-style cards
                        if fastingService.isFasting {
                            TimelineView(.periodic(from: .now, by: 1)) { _ in
                                VStack(spacing: 20) {
                                    moodCard
                                    
                                    bodyPhaseCard
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            BodyJourneyIdleCard()
                                .padding(.horizontal, 20)
                        }
                        
                        // Upcoming holiday
                        upcomingHolidaySection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                    .padding(.top, 8)
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
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                fastingService.configure(with: modelContext)
            }
            .sheet(isPresented: $showPresetSheet) {
                PresetSelectionSheet { preset, customDuration in
                    fastingService.startFasting(preset: preset, customDuration: customDuration)
                    showPresetSheet = false
                }
                .presentationDetents([.medium, .large])
            }
            .alert(
                L10n.Timer.confirmEnd,
                isPresented: $showConfirmEnd
            ) {
                Button(L10n.Timer.endFasting, role: .destructive) {
                    lastFastDuration = elapsed
                    lastFastGoalMet = isGoalAchieved
                    fastingService.endFasting()
                    Haptic.success()
                    // Show refeed guide after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showRefeedGuide = true
                    }
                }
                Button(L10n.Timer.cancel, role: .cancel) {}
            } message: {
                Text("\(L10n.Timer.confirmEndMessage) \(formattedElapsed)")
            }
            .sheet(isPresented: $showMoodCheckIn) {
                MoodCheckInView(fastingHours: elapsed / 3600)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showRefeedGuide) {
                RefeedGuideView(duration: lastFastDuration, wasGoalMet: lastFastGoalMet)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showEditStart) {
                EditStartTimeSheet(startTime: $editedStartTime) {
                    fastingService.currentFast?.startTime = editedStartTime
                    try? modelContext.save()
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showEditGoal) {
                EditGoalSheet(targetHours: $editedGoalHours) {
                    fastingService.currentFast?.targetDuration = editedGoalHours * 3600
                    try? modelContext.save()
                    fastingService.syncToWidget()
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Plate + Dial (hero element)
    
    private var plateWithDial: some View {
        let theme = ThemeManager.shared.currentTheme
        
        return GeometryReader { geo in
            let size = min(geo.size.width - 40, geo.size.height)
            ZStack {
                if let plateImg = theme.plateImage {
                    Image(plateImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
                }
                
                TimerDial(
                    style: dialStyle,
                    progress: fastingService.isFasting ? progress : 0,
                    elapsed: fastingService.isFasting ? elapsed : 0,
                    target: fastingService.currentFast?.targetDuration ?? 0,
                    startTime: fastingService.currentFast?.startTime,
                    isFasting: fastingService.isFasting,
                    isGoalAchieved: isGoalAchieved
                )
                .scaleEffect(theme.hasPlate ? 1.0 / theme.plateScale : 1.0)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 20)
    }
    
    private var timerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let _ = context.date
            VStack(spacing: 8) {
                // Timer dial (switchable styles)
                plateWithDial
                .accessibilityElement(children: .combine)
                .accessibilityLabel(timerAccessibilityLabel)
                .onLongPressGesture(perform: switchDialStyle)
                
                // STARTED / GOAL row — always visible
                HStack(spacing: 12) {
                    if fastingService.isFasting, let start = fastingService.currentFast?.startTime {
                        // Fasting: STARTED tappable to edit
                        Button {
                            editedStartTime = start
                            showEditStart = true
                            Haptic.light()
                        } label: {
                            timeInfoPill(label: "STARTED", value: formatTimeShort(start))
                        }
                        .buttonStyle(.plain)
                        
                        // Fasting: GOAL — tappable to edit
                        if let targetDur = fastingService.currentFast?.targetDuration {
                            let preset = fastingService.currentFast?.presetType.displayName ?? ""
                            Button {
                                editedGoalHours = targetDur / 3600
                                showEditGoal = true
                                Haptic.light()
                            } label: {
                                timeInfoPill(label: "\(preset) GOAL", value: formatTimeShort(start.addingTimeInterval(targetDur)))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Idle: START = now
                        timeInfoPill(label: "START", value: formatTimeShort(Date()))
                        
                        // Idle: GOAL — tappable, opens preset picker & starts
                        Button {
                            showPresetSheet = true
                            Haptic.light()
                        } label: {
                            VStack(spacing: 4) {
                                Text("GOAL")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                    .tracking(0.5)
                                HStack(spacing: 4) {
                                    Text(idlePresetLabel)
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(Color.fastingGreen)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(Color.fastingGreen.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                
                // Action button inside card
                actionButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .glassCard(cornerRadius: CornerRadius.extraLarge)
            .onChange(of: isGoalAchieved) { _, achieved in
                if achieved && !hasShownGoalCelebration {
                    hasShownGoalCelebration = true
                    Haptic.success()
                }
            }
        }
    }
    
    private func timeInfoPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.fastingGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    @AppStorage("defaultPreset") private var idleDefaultPreset: String = "sixteen8"
    
    private var idlePresetLabel: String {
        let preset = FastingPreset(rawValue: idleDefaultPreset) ?? .sixteen8
        return preset.displayName
    }
    
    private func formatTimeShort(_ date: Date) -> String {
        TimerFormatters.timeShort.string(from: date).uppercased()
    }
    
    private func switchDialStyle() {
        Haptic.medium()
        withAnimation(.fastSpring) {
            dialStyleRaw = dialStyle.next.rawValue
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        if fastingService.isFasting {
            // End fast — subtle, not prominent
            Button {
                Haptic.medium()
                showConfirmEnd = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "stop.fill")
                    Text(L10n.Timer.endFasting)
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        } else {
            // Start button in idle
            Button {
                Haptic.medium()
                let preset = FastingPreset(rawValue: idleDefaultPreset) ?? .sixteen8
                fastingService.startFasting(preset: preset, customDuration: nil)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "play.fill")
                    Text(L10n.Timer.startFasting)
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.fastingGreen.gradient, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.fastingGreen.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Upcoming Holiday
    
    private var upcomingHolidaySection: some View {
        Group {
            let upcoming = HolidayService.upcomingHolidays(within: 3)
            if let (date, holiday) = upcoming.first {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text(holiday.fastingAdvice.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holiday.localizedName)
                                .font(.subheadline.weight(.semibold))
                            Text(daysUntilText(date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(holiday.fastingAdvice.localizedSummary)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(holiday.fastingAdvice.localizedDetail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.lg)
                .glassCard(cornerRadius: CornerRadius.large)
            }
        }
    }
    
    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days == 0 { return "Today".localized }
        if days == 1 { return "Tomorrow".localized }
        return "\(days) " + "days away".localized
    }
    
    // MARK: - Current Phase (unified: physiology + psychology + guidance + mood)
    
    // MARK: - Mood Card (standalone)
    
    private var moodCard: some View {
        Button {
            showMoodCheckIn = true
            Haptic.light()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "heart.text.clipboard")
                        .font(.subheadline)
                        .foregroundStyle(Color.fastingOrange)
                    Text("mood_checkin_title".localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.fastingOrange)
                    
                    Spacer()
                    
                    if let record = recentMoodRecord {
                        Text(formatTime(record.timestamp))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.quaternary)
                }
                
                // Content
                if let record = recentMoodRecord {
                    Text(record.mood.localizedLabel)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                } else {
                    Text("mood_checkin_subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: CornerRadius.large)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Body Phase Card (standalone, with expand/collapse)
    
    @State private var isPhaseExpanded = false
    
    private var bodyPhaseCard: some View {
        let phase = FastingPhaseManager.currentPhase(for: elapsed)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Header + collapsed summary — entire area tappable
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "figure.equestrian.sports")
                        .font(.subheadline)
                        .foregroundStyle(Color.fastingGreen)
                    Text("Body Journey".localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.fastingGreen)
                    
                    Spacer()
                    
                    if let timeToNext = FastingPhaseManager.timeToNextPhase(for: elapsed) {
                        Text(formatShortInterval(timeToNext))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.quaternary)
                        .rotationEffect(.degrees(isPhaseExpanded ? 180 : 0))
                }
                .padding(16)
                
                // Phase summary (only when collapsed)
                if !isPhaseExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phase.name)
                            .font(.title2.weight(.bold))
                        
                        Text(phase.companionMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.fastSpring) {
                    isPhaseExpanded.toggle()
                }
                Haptic.light()
            }
            
            // Expanded: phase timeline with auto-scroll to current
            if isPhaseExpanded {
                Divider().opacity(0.3)
                
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        ForEach(FastingPhaseManager.phases) { p in
                            let isUnlocked = elapsed / 3600 >= p.startHour
                            let isCurrent = p.id == phase.id
                            
                            PhaseTimelineRow(
                                phase: p,
                                isUnlocked: isUnlocked,
                                isCurrent: isCurrent,
                                duration: elapsed
                            )
                            .id(p.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.smoothSpring) {
                                proxy.scrollTo(phase.id, anchor: .center)
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .glassCard(cornerRadius: CornerRadius.extraLarge)
        .animation(.fastSpring, value: isPhaseExpanded)
    }
    
    private func formatShortInterval(_ interval: TimeInterval) -> String {
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    
    // MARK: - Mood Check-in Row (inside phase card)
    
    @Query(sort: \MoodRecord.timestamp, order: .reverse) private var moodRecords: [MoodRecord]
    
    private var recentMoodRecord: MoodRecord? {
        // Find mood record from this fasting session
        guard let start = fastingService.currentFast?.startTime else { return nil }
        return moodRecords.first { $0.timestamp >= start }
    }
    

    
    private func formatTime(_ date: Date) -> String {
        TimerFormatters.hourMinute.string(from: date)
    }

    // MARK: - Computed
    
    /// Last completed fast (for idle ring display)
    private var lastCompleted: FastingRecord? {
        records.first { $0.status == .completed }
    }
    
    private var elapsed: TimeInterval {
        guard let start = fastingService.currentFast?.startTime,
              fastingService.isFasting else { return 0 }
        return Date().timeIntervalSince(start)
    }
    
    private var progress: Double {
        guard fastingService.isFasting,
              let target = fastingService.currentFast?.targetDuration, target > 0 else { return 0 }
        return min(elapsed / target, 1.0)
    }
    
    private var isGoalAchieved: Bool {
        guard let target = fastingService.currentFast?.targetDuration else { return false }
        return elapsed >= target
    }
    
    private var remaining: TimeInterval {
        guard let target = fastingService.currentFast?.targetDuration else { return 0 }
        return max(target - elapsed, 0)
    }
    
    private var formattedElapsed: String {
        if fastingService.isFasting {
            return FastingRecord.formatDuration(elapsed)
        }
        return FastingRecord.formatDuration(0)
    }
    
    private var timerAccessibilityLabel: String {
        if fastingService.isFasting {
            if isGoalAchieved {
                return "\(formattedElapsed), completed"
            }
            return "\(formattedElapsed) elapsed, \(formattedRemaining) remaining, \(Int(progress * 100)) percent"
        } else if lastCompleted != nil {
            return "Last fast: \(formattedElapsed)"
        }
        return "No active fast"
    }
    
    private var formattedRemaining: String {
        FastingRecord.formatShortDuration(remaining)
    }
}
