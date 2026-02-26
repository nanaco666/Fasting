//
//  MoodCheckInView.swift
//  Fasting
//
//  情绪 check-in — 断食中定时弹出
//

import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let fastingHours: Double
    
    @State private var selectedMood: Mood?
    @State private var selectedSymptoms: Set<MoodSymptom> = []
    @State private var note: String = ""
    @State private var showResponse = false
    @State private var responseText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Mood selection
                    moodSection
                    
                    // Symptoms (shown after mood selected)
                    if selectedMood != nil {
                        symptomSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Response from companion
                    if showResponse {
                        responseSection
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(24)
            }
            .navigationTitle("How are you feeling?".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.General.done) {
                        saveAndDismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(String(format: "checkin_hours".localized, Int(fastingHours)))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            let msg = CompanionEngine.phaseMessage(hours: fastingHours)
            Text(msg.title)
                .font(.title3.bold())
            Text(msg.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Mood
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your mood".localized)
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    moodButton(mood)
                }
            }
        }
    }
    
    private func moodButton(_ mood: Mood) -> some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                selectedMood = mood
                generateResponse()
            }
            Haptic.selection()
        } label: {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 36))
                Text(mood.localizedLabel)
                    .font(.caption2)
                    .foregroundStyle(selectedMood == mood ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                selectedMood == mood
                    ? Color.fastingGreen.opacity(0.12)
                    : Color.gray.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedMood == mood ? Color.fastingGreen : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedMood == mood ? 1.05 : 1.0)
    }
    
    // MARK: - Symptoms
    
    private var symptomSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Any symptoms?".localized)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(MoodSymptom.allCases) { symptom in
                    symptomChip(symptom)
                }
            }
        }
    }
    
    private func symptomChip(_ symptom: MoodSymptom) -> some View {
        let selected = selectedSymptoms.contains(symptom)
        return Button {
            withAnimation(.spring(response: 0.3)) {
                if selected {
                    selectedSymptoms.remove(symptom)
                } else {
                    selectedSymptoms.insert(symptom)
                }
                generateResponse()
            }
            Haptic.light()
        } label: {
            HStack(spacing: 4) {
                Text(symptom.emoji)
                    .font(.caption)
                Text(symptom.localizedLabel)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                selected
                    ? (symptom.isNegative ? Color.orange.opacity(0.12) : Color.fastingGreen.opacity(0.12))
                    : Color.gray.opacity(0.06),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(selected ? (symptom.isNegative ? Color.orange : Color.fastingGreen) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Response
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.clipboard")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.fastingGreen)
                Text("For you".localized)
                    .font(.headline)
            }
            
            Text(responseText)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fastingGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Logic
    
    private func generateResponse() {
        guard let mood = selectedMood else { return }
        responseText = CompanionEngine.moodResponse(
            mood: mood,
            hours: fastingHours,
            symptoms: Array(selectedSymptoms)
        )
        withAnimation(.spring(response: 0.4)) {
            showResponse = true
        }
    }
    
    private func saveAndDismiss() {
        if let mood = selectedMood {
            let record = MoodRecord(
                mood: mood,
                symptoms: Array(selectedSymptoms),
                fastingHours: fastingHours,
                note: note.isEmpty ? nil : note
            )
            modelContext.insert(record)
            try? modelContext.save()
        }
        dismiss()
    }
}
