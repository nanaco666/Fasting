//
//  EditStartTimeSheet.swift
//  Fasting
//

import SwiftUI
import SwiftData

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
