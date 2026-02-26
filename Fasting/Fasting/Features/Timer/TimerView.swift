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
    
    private var timer: Timer { Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Week strip (moved to top, like Zero)
                        weekStrip
                            .padding(.horizontal, 20)
                        
                        // Timer card
                        timerCard
                            .padding(.horizontal, 20)
                        
                        // Time info + action
                        if fastingService.isFasting {
                            timeInfoRow
                                .padding(.horizontal, 20)
                        }
                        actionButton
                            .padding(.horizontal, 20)
                        
                        // Mood check-in button (when fasting)
                        if fastingService.isFasting {
                            moodCheckInButton
                                .padding(.horizontal, 20)
                        }
                        
                        // Companion message + mood check-in
                        if fastingService.isFasting {
                            companionSection
                                .padding(.horizontal, 20)
                        }
                        
                        bodyJourneySection
                            .padding(.horizontal, 20)
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
    
    // MARK: - Timer Card
    
    private var timerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let _ = context.date
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.08), lineWidth: 16)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.fastingGreen,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: progress)
                    
                    VStack(spacing: 8) {
                        Text(formattedElapsed)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .onTapGesture {
                                if fastingService.isFasting, let start = fastingService.currentFast?.startTime {
                                    editedStartTime = start
                                    showEditStart = true
                                }
                            }
                        
                        if fastingService.isFasting {
                            Text(isGoalAchieved
                                 ? "COMPLETED ✓"
                                 : "ELAPSED (\(Int(progress * 100))%)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1)
                        } else if lastCompleted != nil {
                            Text("LAST FAST")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                                .tracking(1)
                        }
                    }
                }
                .frame(height: 280)
                .padding(20)
            }
            .glassCard(cornerRadius: 24)
            .onChange(of: isGoalAchieved) { _, achieved in
                if achieved && !hasShownGoalCelebration {
                    hasShownGoalCelebration = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
    
    // MARK: - Time Info Row (STARTED / GOAL)
    
    private var timeInfoRow: some View {
        HStack(spacing: 12) {
            if let start = fastingService.currentFast?.startTime {
                timeInfoPill(label: "STARTED", value: formatTimeShort(start))
            }
            if let start = fastingService.currentFast?.startTime,
               let target = fastingService.currentFast?.targetDuration {
                let preset = fastingService.currentFast?.presetType.displayName ?? ""
                timeInfoPill(label: "\(preset) GOAL", value: formatTimeShort(start.addingTimeInterval(target)))
            }
        }
    }
    
    private func timeInfoPill(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.fastingGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatTimeShort(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, HH:mm"
        return f.string(from: date).uppercased()
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if fastingService.isFasting {
                showConfirmEnd = true
            } else {
                showPresetSheet = true
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: fastingService.isFasting ? "stop.fill" : "play.fill")
                Text(fastingService.isFasting ? L10n.Timer.endFasting : L10n.Timer.startFasting)
                    .font(.title3.weight(.semibold))
            }
            .foregroundStyle(fastingService.isFasting ? AnyShapeStyle(.primary) : AnyShapeStyle(.white))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                if fastingService.isFasting {
                    // Subtle outline for "End Fast" (like Zero)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.06))
                } else {
                    // Bold green for "Start"
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.fastingGreen.gradient)
                        .shadow(color: Color.fastingGreen.opacity(0.3), radius: 12, y: 6)
                }
            }
        }
        .buttonStyle(.plain)
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
    
    // MARK: - Mood Check-in
    
    private var moodCheckInButton: some View {
        Button {
            Haptic.medium()
            showMoodCheckIn = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "heart.text.clipboard")
                    .symbolRenderingMode(.hierarchical)
                    .font(.title3)
                    .foregroundStyle(Color.fastingGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("How are you feeling?".localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("companion_checkin_subtitle".localized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Companion
    
    private var companionSection: some View {
        let msg = CompanionEngine.phaseMessage(hours: elapsed / 3600)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.fastingGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.title)
                    .font(.subheadline.weight(.semibold))
                Text(msg.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.fastingGreen.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Body Journey
    
    private var bodyJourneySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Body Journey".localized)
                .font(.title3.weight(.bold))
                .padding(.horizontal, 4)
            
            if fastingService.isFasting {
                BodyJourneyCard(duration: elapsed, isFasting: true)
            } else {
                BodyJourneyIdleCard()
            }
        }
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
                            .font(.caption2)
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

// MARK: - Preset Selection Sheet

struct PresetSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FastingPreset, TimeInterval?) -> Void
    
    @State private var selectedPreset: FastingPreset = .sixteen8
    @State private var customHours: Int = 16
    @State private var customMinutes: Int = 0
    
    var body: some View {
        NavigationStack {
            Form {
                presetSection
                if selectedPreset == .custom {
                    customDurationSection
                }
                startSection
            }
            .navigationTitle(L10n.Preset.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Timer.cancel) { dismiss() }
                }
            }
        }
    }
    
    private var presetSection: some View {
        Section {
            ForEach(FastingPreset.allCases) { preset in
                PresetRow(
                    preset: preset,
                    isSelected: selectedPreset == preset
                ) {
                    Haptic.selection()
                    withAnimation { selectedPreset = preset }
                }
            }
        } header: {
            Text("Fasting Plan".localized)
        }
    }
    
    private var customDurationSection: some View {
        Section {
            HStack {
                Picker("", selection: $customHours) {
                    ForEach(0..<73) { h in
                        Text("\(h) \(L10n.Preset.hours)").tag(h)
                    }
                }
                .pickerStyle(.wheel)
                
                Picker("", selection: $customMinutes) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.wheel)
            }
            .frame(height: 120)
        } header: {
            Text("Duration".localized)
        }
    }
    
    private var startSection: some View {
        Section {
            Button {
                let custom = selectedPreset == .custom
                    ? Double(customHours * 3600 + customMinutes * 60)
                    : nil
                onSelect(selectedPreset, custom)
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                    Text(L10n.Timer.startFasting).font(.headline)
                    Spacer()
                }
            }
            .listRowBackground(Color.fastingGreen)
            .foregroundStyle(.white)
        }
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: FastingPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.sm) {
                        Text(preset.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        if preset == .sixteen8 {
                            Text(L10n.Preset.popular)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.fastingGreen, in: Capsule())
                        }
                    }
                    
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(Color.fastingGreen) : AnyShapeStyle(.tertiary))
                    .font(.title3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var languageManager = LanguageManager.shared
    @State private var healthService = HealthKitService.shared
    
    @AppStorage("defaultPreset") private var defaultPreset: String = "sixteen8"
    @AppStorage("notificationsOn") private var notificationsOn = true
    
    var body: some View {
        List {
            Section(L10n.Settings.fastingSettings) {
                // Default preset
                Picker(selection: $defaultPreset) {
                    ForEach(FastingPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                } label: {
                    Label(L10n.Settings.defaultPlan, systemImage: "clock")
                }
                
                // Notifications
                Toggle(isOn: $notificationsOn) {
                    Label(L10n.Settings.notifications, systemImage: "bell")
                }
                .tint(Color.fastingGreen)
            }
            
            Section(L10n.Settings.data) {
                // HealthKit
                Button {
                    Task { await healthService.requestAuthorization() }
                } label: {
                    HStack {
                        Label(L10n.Settings.healthSync, systemImage: "heart")
                        Spacer()
                        if healthService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.fastingGreen)
                        } else {
                            Text("Connect".localized)
                                .font(.caption)
                                .foregroundStyle(Color.fastingGreen)
                        }
                    }
                }
                .foregroundStyle(.primary)
                
                // iCloud
                HStack {
                    Label(L10n.Settings.iCloudSync, systemImage: "icloud")
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.fastingGreen)
                }
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
                    Text("1.2.0").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.Settings.title)
    }
}

// MARK: - Edit Start Time Sheet

struct EditStartTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startTime: Date
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("Adjust Start Time".localized)
                    .font(.headline)
                
                DatePicker(
                    "",
                    selection: $startTime,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Button {
                    onSave()
                    dismiss()
                } label: {
                    Text("Save".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.fastingGreen, in: RoundedRectangle(cornerRadius: CornerRadius.large))
                }
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.top, Spacing.lg)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Timer.cancel) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TimerView()
        .modelContainer(for: [FastingRecord.self, FastingPlan.self], inMemory: true)
}
