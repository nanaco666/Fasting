//
//  EditNameSheet.swift
//  Fasting
//

import SwiftUI

struct EditNameSheet: View {
    @Binding var name: String
    @State private var draft: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                TextField("Enter your name".localized, text: $draft)
                    .font(.title3)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, Spacing.lg)

                Spacer()
            }
            .padding(.top, Spacing.xl)
            .navigationTitle("Edit Name".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        name = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { draft = name }
        }
    }
}
