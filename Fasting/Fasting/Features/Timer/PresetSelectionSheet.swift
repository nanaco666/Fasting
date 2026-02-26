//
//  PresetSelectionSheet.swift
//  Fasting
//

import SwiftUI

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
            }
            .navigationTitle(L10n.Preset.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let custom = selectedPreset == .custom
                            ? Double(customHours * 3600 + customMinutes * 60)
                            : nil
                        onSelect(selectedPreset, custom)
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.fastingGreen)
                            .font(.title3)
                    }
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
