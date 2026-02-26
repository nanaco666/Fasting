//
//  TimerView.swift
//  Fasting
//

import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FastingRecord.startTime, order: .reverse) private var records: [FastingRecord]
    @Query(filter: #Predicate<FastingPlan> { $0.isActive }) private var activePlans: [FastingPlan]
    @State private var fastingService = FastingService.shared
    @State private var showPresetSheet = false
    @State private var showConfirmEnd = false
    @State private var showEditStart = false
    @State private var editedStartTime = Date()
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
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Week strip
                        weekStrip
                            .padding(.horizontal, 20)
                        
                        // Timer card (dial + pills + action button — all in one)
                        timerCard
                            .padding(.horizontal, 20)
                        
                        // Health-style cards
                        if fastingService.isFasting {
                            moodCard
                                .padding(.horizontal, 20)
                            
                            bodyPhaseCard
                                .padding(.horizontal, 20)
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
                            .symbolRenderingMode(.hierarchical)
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
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        }
    }
    
    // MARK: - Week Strip (Zero-style top bar)
    
    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(weekStripDays, id: \.self) { day in
                let isToday = Calendar.current.isDateInToday(day)
                let completed = dayCompleted(day)
                
                VStack(spacing: 6) {
                    Text(weekdayLabel(day))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isToday ? .primary : .tertiary)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.12), lineWidth: 3)
                        
                        if completed {
                            Circle()
                                .stroke(Color.fastingGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        } else if isToday && fastingService.isFasting {
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.fastingGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    Haptic.selection()
                    // Future: Navigate to day details
                }
            }
        }
    }
    
    private var weekStripDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-6...0).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }
    
    private func weekdayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }
    
    private func dayCompleted(_ date: Date) -> Bool {
        let cal = Calendar.current
        return records.contains {
            $0.status == .completed
            && ($0.actualDuration ?? 0) >= $0.targetDuration
            && cal.isDate($0.startTime, inSameDayAs: date)
        }
    }
    
    // MARK: - Unified Timer Card (ring + elapsed + remaining + STARTED/GOAL)
    
    private var timerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let _ = context.date
            VStack(spacing: 16) {
                // Timer dial (switchable styles)
                TimerDial(
                    style: dialStyle,
                    progress: progress,
                    elapsed: fastingService.isFasting ? elapsed : (lastCompleted?.actualDuration ?? 0),
                    target: fastingService.currentFast?.targetDuration ?? (lastCompleted?.targetDuration ?? 0),
                    startTime: fastingService.currentFast?.startTime,
                    isFasting: fastingService.isFasting,
                    isGoalAchieved: isGoalAchieved
                )
                .padding(.top, 12)
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
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            timeInfoPill(label: "STARTED", value: formatTimeShort(start))
                        }
                        .buttonStyle(.plain)
                        
                        // Fasting: GOAL display
                        if let targetDur = fastingService.currentFast?.targetDuration {
                            let preset = fastingService.currentFast?.presetType.displayName ?? ""
                            timeInfoPill(label: "\(preset) GOAL", value: formatTimeShort(start.addingTimeInterval(targetDur)))
                        }
                    } else {
                        // Idle: START = now
                        timeInfoPill(label: "START", value: formatTimeShort(Date()))
                        
                        // Idle: GOAL — tappable, opens preset picker & starts
                        Button {
                            showPresetSheet = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                
                // Action button inside card
                actionButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .glassCard(cornerRadius: CornerRadius.extraLarge)
            .onChange(of: isGoalAchieved) { _, achieved in
                if achieved && !hasShownGoalCelebration {
                    hasShownGoalCelebration = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    @AppStorage("defaultPreset") private var idleDefaultPreset: String = "sixteen8"
    
    private var idlePresetLabel: String {
        let preset = FastingPreset(rawValue: idleDefaultPreset) ?? .sixteen8
        return preset.displayName
    }
    
    private func formatTimeShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, HH:mm"
        return f.string(from: date).uppercased()
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        } else {
            // Start button in idle
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
            // Header
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "figure.walk")
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
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.fastSpring) {
                    isPhaseExpanded.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
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
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    // MARK: - Plan Progress (Week Timeline)
    
    private var planProgressSection: some View {
        Group {
            if let plan = activePlans.first {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Plan Progress".localized)
                        .font(.title3.weight(.bold))
                        .padding(.horizontal, Spacing.xs)
                    
                    PlanWeekTimeline(plan: plan, records: records)
                }
            }
        }
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
        if fastingService.isFasting {
            guard let target = fastingService.currentFast?.targetDuration, target > 0 else { return 0 }
            return min(elapsed / target, 1.0)
        }
        // Show last fast's real progress when idle
        if let last = lastCompleted, let actual = last.actualDuration, last.targetDuration > 0 {
            return min(actual / last.targetDuration, 1.0)
        }
        return 0
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
        if let last = lastCompleted, let actual = last.actualDuration {
            return FastingRecord.formatDuration(actual)
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

// MARK: - Plan Week Timeline

struct PlanWeekTimeline: View {
    let plan: FastingPlan
    let records: [FastingRecord]
    
    private var currentWeek: Int {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: plan.startDate, to: Date()).weekOfYear ?? 0
        return min(max(weeks + 1, 1), plan.durationWeeks)
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Week indicator
            HStack {
                Text(String(format: "week_number".localized, currentWeek))
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "week_progress".localized, currentWeek, plan.durationWeeks))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Week progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                    
                    Capsule()
                        .fill(Color.fastingGreen.gradient)
                        .frame(width: geo.size.width * Double(currentWeek) / Double(max(plan.durationWeeks, 1)))
                        .animation(.easeInOut, value: currentWeek)
                }
            }
            .frame(height: 8)
            
            // This week's days
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let completed = hasFastingRecord(on: day)
                    let isToday = Calendar.current.isDateInToday(day)
                    
                    VStack(spacing: 6) {
                        Text(dayLabel(day))
                            .font(.caption)
                            .foregroundStyle(isToday ? .primary : .secondary)
                        
                        ZStack {
                            Circle()
                                .fill(completed ? Color.fastingGreen : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            if completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else if isToday {
                                Circle()
                                    .stroke(Color.fastingGreen, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Spacing.lg)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func hasFastingRecord(on date: Date) -> Bool {
        let calendar = Calendar.current
        return records.contains { record in
            record.status == .completed
            && calendar.isDate(record.startTime, inSameDayAs: date)
            && (record.actualDuration ?? 0) >= record.targetDuration
        }
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(2))
    }
}



