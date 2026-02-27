//
//  EditGoalSheet.swift
//  Fasting
//
//  Edit fasting goal duration while fasting is in progress
//

import SwiftUI

struct EditGoalSheet: View {
    @Binding var targetHours: Double
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let presets: [(String, Double)] = [
        ("12:12", 12), ("14:10", 14), ("16:8", 16),
        ("18:6", 18), ("20:4", 20), ("24h", 24),
        ("36h", 36), ("48h", 48), ("72h", 72),
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current goal display
                VStack(spacing: 4) {
                    Text("goal_current".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(Int(targetHours))h")
                        .font(AppFont.stat(40))
                        .monospacedDigit()
                        .foregroundStyle(Color.fastingGreen)
                        .contentTransition(.numericText())
                }
                .padding(.top, 8)
                
                // Preset grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(presets, id: \.1) { name, hours in
                        Button {
                            withAnimation(.fastSpring) {
                                targetHours = hours
                            }
                            Haptic.selection()
                        } label: {
                            Text(name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(targetHours == hours ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    targetHours == hours
                                        ? AnyShapeStyle(Color.fastingGreen)
                                        : AnyShapeStyle(Color.gray.opacity(0.1)),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                
                // Custom stepper
                HStack(spacing: 20) {
                    Button {
                        withAnimation(.fastSpring) {
                            targetHours = max(1, targetHours - 1)
                        }
                        Haptic.light()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.fastingGreen)
                    }
                    
                    Text("\(Int(targetHours))h")
                        .font(.title3.bold())
                        .monospacedDigit()
                        .frame(width: 60)
                        .contentTransition(.numericText())
                    
                    Button {
                        withAnimation(.fastSpring) {
                            targetHours = min(168, targetHours + 1)
                        }
                        Haptic.light()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.fastingGreen)
                    }
                }
                
                Spacer()
                
                // Save button
                Button {
                    onSave()
                    Haptic.medium()
                    dismiss()
                } label: {
                    Text("save".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.fastingGreen, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
            .navigationTitle("edit_goal".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
