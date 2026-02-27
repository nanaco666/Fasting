//
//  MoodCheckInView.swift
//  Fasting
//
//  身心福祉 Check-in — 布辛格量表 + 陪伴式引导
//  "我们不只是在收集数据，我们在陪你走过每一个小时。"
//

import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let fastingHours: Double
    
    // MARK: - State
    
    @State private var pwb: Double = 5          // Physical 0-10
    @State private var ewb: Double = 5          // Emotional 0-10
    @State private var isHungry: Bool = false
    @State private var ketoneLevel: KetoneLevel? = nil
    @State private var selectedSymptoms: Set<MoodSymptom> = []
    @State private var showKetoneInfo = false
    @State private var showResponse = false
    @State private var companionResponse = ""
    @State private var lastHapticPWB: Double = 5
    @State private var lastHapticEWB: Double = 5
    @State private var animateIn = false
    
    private var derivedMood: Mood {
        Mood.from(pwb: Int(pwb.rounded()), ewb: Int(ewb.rounded()))
    }
    
    private var pwbLevel: WellbeingLevel { WellbeingLevel(score: Int(pwb.rounded())) }
    private var ewbLevel: WellbeingLevel { WellbeingLevel(score: Int(ewb.rounded())) }
    
    // Blended color from PWB + EWB
    private var ambientColor: Color {
        let avg = (pwb + ewb) / 2.0
        if avg >= 7 { return Color.fastingGreen }
        if avg >= 5 { return Color.fastingTeal }
        if avg >= 3 { return Color.fastingOrange }
        return Color.fastingOrange
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ambientColor.opacity(0.06)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: ambientColor)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Greeting
                        greetingSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        
                        // Body section
                        bodySection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        
                        // Mind section
                        mindSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                        
                        // Hunger
                        hungerSection
                            .opacity(animateIn ? 1 : 0)
                        
                        // Symptoms
                        symptomSection
                            .opacity(animateIn ? 1 : 0)
                        
                        // Ketone (optional)
                        ketoneSection
                            .opacity(animateIn ? 1 : 0)
                        
                        // Companion response
                        if showResponse {
                            responseSection
                                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
                        }
                        
                        // Save
                        saveButton
                            .padding(.top, 4)
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.smoothSpring.delay(0.2)) {
                    animateIn = true
                }
            }
            .sheet(isPresented: $showKetoneInfo) {
                ketoneInfoSheet
            }
        }
    }
    
    // MARK: - Greeting
    
    private var greetingSection: some View {
        VStack(spacing: 8) {
            Text(greetingTitle)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            
            Text(String(format: "checkin_hours".localized, Int(fastingHours)))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 12)
    }
    
    private var greetingTitle: String {
        if fastingHours < 4 {
            return "checkin_greeting_early".localized
        } else if fastingHours < 12 {
            return "checkin_greeting_mid".localized
        } else if fastingHours < 18 {
            return "checkin_greeting_late".localized
        } else {
            return "checkin_greeting_extended".localized
        }
    }
    
    // MARK: - Body (PWB)
    
    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.subheadline)
                    .foregroundStyle(pwbLevel.color)
                Text("checkin_body_title".localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            // Question
            Text("checkin_body_question".localized)
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Score display
            HStack {
                Text("\(Int(pwb.rounded()))")
                    .font(AppFont.stat())
                    .foregroundStyle(pwbLevel.color)
                    .contentTransition(.numericText())
                    .animation(.fastSpring, value: Int(pwb.rounded()))
                
                Spacer()
                
                Text(pwbLevel.localizedLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(pwbLevel.color)
                    .contentTransition(.interpolate)
            }
            
            // Slider
            wellbeingSlider(value: $pwb, color: pwbLevel.color, lastHaptic: $lastHapticPWB)
            
            // Subtle context
            if Int(pwb.rounded()) <= 4 {
                Text("checkin_body_low_hint".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: CornerRadius.large)
        .onChange(of: Int(pwb.rounded())) { _, _ in updateResponse() }
    }
    
    // MARK: - Mind (EWB)
    
    private var mindSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.subheadline)
                    .foregroundStyle(ewbLevel.color)
                Text("checkin_mind_title".localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            Text("checkin_mind_question".localized)
                .font(.body)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("\(Int(ewb.rounded()))")
                    .font(AppFont.stat())
                    .foregroundStyle(ewbLevel.color)
                    .contentTransition(.numericText())
                    .animation(.fastSpring, value: Int(ewb.rounded()))
                
                Spacer()
                
                Text(ewbLevel.localizedLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ewbLevel.color)
                    .contentTransition(.interpolate)
            }
            
            wellbeingSlider(value: $ewb, color: ewbLevel.color, lastHaptic: $lastHapticEWB)
            
            if Int(ewb.rounded()) <= 4 {
                Text("checkin_mind_low_hint".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: CornerRadius.large)
        .onChange(of: Int(ewb.rounded())) { _, _ in updateResponse() }
    }
    
    // MARK: - Wellbeing Slider (reusable)
    
    private func wellbeingSlider(value: Binding<Double>, color: Color, lastHaptic: Binding<Double>) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                    
                    // Fill
                    Capsule()
                        .fill(color.opacity(0.25))
                        .frame(width: geo.size.width * (value.wrappedValue / 10.0))
                    
                    // Thumb
                    Circle()
                        .fill(.white)
                        .shadow(color: color.opacity(0.25), radius: 6, y: 2)
                        .frame(width: 26, height: 26)
                        .offset(x: (geo.size.width - 26) * (value.wrappedValue / 10.0))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    let raw = drag.location.x / geo.size.width * 10.0
                                    let snapped = (raw * 2).rounded() / 2  // snap to 0.5
                                    let clamped = min(max(snapped, 0), 10)
                                    value.wrappedValue = clamped
                                    if abs(clamped - lastHaptic.wrappedValue) >= 1.0 {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        lastHaptic.wrappedValue = clamped
                                    }
                                }
                        )
                }
            }
            .frame(height: 26)
            
            // Scale labels
            HStack {
                Text("0")
                Spacer()
                Text("5")
                Spacer()
                Text("10")
            }
            .font(.caption2)
            .foregroundStyle(.quaternary)
        }
    }
    
    // MARK: - Hunger
    
    private var hungerSection: some View {
        HStack {
            Image(systemName: "fork.knife")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("checkin_hunger_question".localized)
                .font(.subheadline)
            
            Spacer()
            
            // Soft toggle
            Button {
                withAnimation(.fastSpring) {
                    isHungry.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                updateResponse()
            } label: {
                Text(isHungry ? "checkin_yes".localized : "checkin_no".localized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isHungry ? .white : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        isHungry ? Color.fastingOrange : Color.gray.opacity(0.08),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    // MARK: - Symptoms
    
    private var symptomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("checkin_symptoms_title".localized)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            // Physical
            Text("checkin_symptoms_physical".localized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            
            FlowLayout(spacing: 8) {
                ForEach(MoodSymptom.physicalSymptoms) { symptom in
                    symptomChip(symptom)
                }
            }
            
            // Mental
            Text("checkin_symptoms_mental".localized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .padding(.top, 4)
            
            FlowLayout(spacing: 8) {
                ForEach(MoodSymptom.mentalSymptoms) { symptom in
                    symptomChip(symptom)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: CornerRadius.large)
    }
    
    private func symptomChip(_ symptom: MoodSymptom) -> some View {
        let selected = selectedSymptoms.contains(symptom)
        let chipColor = symptom.isNegative ? Color.fastingOrange : Color.fastingGreen
        
        return Button {
            withAnimation(.fastSpring) {
                if selected {
                    selectedSymptoms.remove(symptom)
                } else {
                    selectedSymptoms.insert(symptom)
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            updateResponse()
        } label: {
            HStack(spacing: 4) {
                Text(symptom.emoji)
                    .font(.callout)
                Text(symptom.localizedLabel)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                selected ? chipColor.opacity(0.12) : Color.gray.opacity(0.06),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(selected ? chipColor.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(selected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.03 : 1.0)
        .animation(.fastSpring, value: selected)
    }
    
    // MARK: - Ketone (Optional)
    
    private var ketoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.fastingTeal)
                
                Text("checkin_ketone_title".localized)
                    .font(.subheadline.weight(.semibold))
                
                Text("checkin_optional".localized)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.08), in: Capsule())
                
                Spacer()
                
                Button {
                    showKetoneInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("checkin_ketone_question".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Ketone level pills
            HStack(spacing: 6) {
                ForEach(KetoneLevel.allCases) { (level: KetoneLevel) in
                    let selected: Bool = ketoneLevel == level
                    Button {
                        withAnimation(.fastSpring) {
                            ketoneLevel = selected ? nil : level
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        updateResponse()
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(level.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(selected ? Color.primary : Color.clear, lineWidth: 2)
                                )
                            Text(level.mmolRange)
                                .font(.caption2.weight(.medium).monospacedDigit())
                                .foregroundStyle(selected ? .primary : .quaternary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
            
            if let level = ketoneLevel {
                Text(level.localizedLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: CornerRadius.large)
        .animation(.fastSpring, value: ketoneLevel)
    }
    
    // MARK: - Ketone Info Sheet
    
    private var ketoneInfoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero
                    VStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.fastingTeal)
                        Text("ketone_info_title".localized)
                            .font(.title3.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    
                    Text("ketone_info_what".localized)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    // Color guide
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ketone_info_guide_title".localized)
                            .font(.subheadline.weight(.semibold))
                        
                        ForEach(KetoneLevel.allCases) { (level: KetoneLevel) in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 20, height: 20)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(level.localizedLabel)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(level.mmolRange) mmol/L")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
                    
                    Text("ketone_info_tips".localized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    // Safety note
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.fastingOrange)
                        Text("ketone_info_safety".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.fastingOrange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { showKetoneInfo = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Companion Response
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(ambientColor)
                Text("checkin_guidance_title".localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ambientColor)
            }
            
            Text(companionResponse)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(16)
        .background(ambientColor.opacity(0.06), in: RoundedRectangle(cornerRadius: CornerRadius.large))
    }
    
    // MARK: - Save
    
    private var saveButton: some View {
        Button {
            save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } label: {
            Text("checkin_save".localized)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ambientColor.gradient, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Logic
    
    private func updateResponse() {
        companionResponse = CompanionEngine.wellbeingResponse(
            pwb: Int(pwb.rounded()),
            ewb: Int(ewb.rounded()),
            isHungry: isHungry,
            ketone: ketoneLevel,
            symptoms: Array(selectedSymptoms),
            hours: fastingHours
        )
        if !showResponse && !companionResponse.isEmpty {
            withAnimation(.smoothSpring) { showResponse = true }
        }
    }
    
    private func save() {
        let record = MoodRecord(
            pwb: Int(pwb.rounded()),
            ewb: Int(ewb.rounded()),
            isHungry: isHungry,
            ketoneLevel: ketoneLevel,
            symptoms: Array(selectedSymptoms),
            fastingHours: fastingHours
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}
