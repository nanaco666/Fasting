//
//  MoodCheckInView.swift
//  Fasting
//
//  情绪 Check-in — Apple Journal 风格滑块 + 流体 orb
//

import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let fastingHours: Double
    
    @State private var moodValue: Double = 0.5  // 0 = struggling, 1 = great
    @State private var selectedSymptoms: Set<MoodSymptom> = []
    @State private var showSymptoms = false
    @State private var showResponse = false
    @State private var companionResponse = ""
    @State private var animationPhase: CGFloat = 0
    
    private var currentMood: Mood {
        switch moodValue {
        case 0..<0.2: return .struggling
        case 0.2..<0.4: return .tough
        case 0.4..<0.6: return .neutral
        case 0.6..<0.8: return .good
        default: return .great
        }
    }
    
    private var moodColor: Color {
        let t = moodValue
        if t < 0.5 {
            // Orange → Warm gray
            return Color(
                red: 0.95 - t * 0.3,
                green: 0.65 + t * 0.2,
                blue: 0.45 + t * 0.5
            )
        } else {
            // Warm gray → Teal green
            let s = (t - 0.5) * 2
            return Color(
                red: 0.8 - s * 0.45,
                green: 0.75 + s * 0.12,
                blue: 0.7 - s * 0.05
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Ambient background that shifts with mood
                moodColor.opacity(0.08)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: moodValue)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Fluid orb
                    moodOrb
                        .frame(height: 200)
                    
                    // Mood label
                    Text(currentMood.localizedLabel)
                        .font(.title2.weight(.semibold))
                        .contentTransition(.interpolate)
                        .animation(.spring(response: 0.4), value: currentMood)
                        .padding(.top, 16)
                    
                    // Phase context
                    Text(String(format: "checkin_hours".localized, Int(fastingHours)))
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    // Mood slider
                    moodSlider
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                    
                    // Symptoms (appear after slider interaction)
                    if showSymptoms {
                        symptomChips
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Companion response
                    if showResponse {
                        responseCard
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Save button
                    saveButton
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                .animation(.spring(response: 0.5), value: showSymptoms)
                .animation(.spring(response: 0.5), value: showResponse)
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
                // Trigger symptom section after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSymptoms = true
                }
            }
        }
    }
    
    // MARK: - Fluid Mood Orb
    
    private var moodOrb: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius: CGFloat = 50 + moodValue * 20
                
                // Outer glow layers (3 concentric, breathing)
                for i in (0..<4).reversed() {
                    let layerFraction = CGFloat(i) / 3.0
                    let breathe = sin(t * 1.2 + Double(i) * 0.8) * 0.06
                    let radius = baseRadius * (1.0 + layerFraction * 0.8 + breathe)
                    let opacity = (1.0 - layerFraction) * 0.25
                    
                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    
                    let gradient = Gradient(colors: [
                        moodColor.opacity(opacity),
                        moodColor.opacity(opacity * 0.3),
                        .clear
                    ])
                    
                    ctx.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            gradient,
                            center: center,
                            startRadius: 0,
                            endRadius: radius
                        )
                    )
                }
                
                // Core orb — solid, bright
                let coreRadius = baseRadius * 0.4
                let coreRect = CGRect(
                    x: center.x - coreRadius,
                    y: center.y - coreRadius,
                    width: coreRadius * 2,
                    height: coreRadius * 2
                )
                ctx.fill(
                    Circle().path(in: coreRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            .white.opacity(0.9),
                            moodColor.opacity(0.6),
                            moodColor.opacity(0.2)
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: coreRadius
                    )
                )
            }
        }
    }
    
    // MARK: - Mood Slider
    
    private var moodSlider: some View {
        VStack(spacing: 8) {
            // Custom slider track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.gray.opacity(0.12))
                    
                    // Filled portion
                    Capsule()
                        .fill(moodColor.opacity(0.3))
                        .frame(width: geo.size.width * moodValue)
                    
                    // Thumb
                    Circle()
                        .fill(.white)
                        .shadow(color: moodColor.opacity(0.3), radius: 8, y: 2)
                        .frame(width: 28, height: 28)
                        .offset(x: (geo.size.width - 28) * moodValue)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let new = value.location.x / geo.size.width
                                    moodValue = min(max(new, 0), 1)
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    updateResponse()
                                }
                        )
                }
            }
            .frame(height: 28)
            
            // Labels
            HStack {
                Text("mood_very_unpleasant".localized)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                Spacer()
                Text("mood_very_pleasant".localized)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
            }
        }
    }
    
    // MARK: - Symptom Chips
    
    private var symptomChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("symptom_question".localized)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(MoodSymptom.allCases) { symptom in
                    let selected = selectedSymptoms.contains(symptom)
                    Button {
                        withAnimation(.spring(response: 0.3)) {
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
                            selected
                                ? moodColor.opacity(0.15)
                                : Color.gray.opacity(0.06),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(selected ? moodColor.opacity(0.4) : .clear, lineWidth: 1.5)
                        )
                        .foregroundStyle(selected ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(selected ? 1.03 : 1.0)
                    .animation(.spring(response: 0.25), value: selected)
                }
            }
        }
    }
    
    // MARK: - Response Card
    
    private var responseCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.body)
                .foregroundStyle(moodColor)
            
            Text(companionResponse)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(moodColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Save
    
    private var saveButton: some View {
        Button {
            save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } label: {
            Text("Save".localized)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(moodColor.gradient, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Logic
    
    private func updateResponse() {
        companionResponse = CompanionEngine.moodResponse(
            mood: currentMood,
            hours: fastingHours,
            symptoms: Array(selectedSymptoms)
        )
        if !showResponse {
            withAnimation { showResponse = true }
        }
    }
    
    private func save() {
        let record = MoodRecord(
            mood: currentMood,
            symptoms: Array(selectedSymptoms),
            fastingHours: fastingHours,
            note: nil
        )
        modelContext.insert(record)
        try? modelContext.save()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
