//
//  MeView.swift
//  Fasting
//

import SwiftUI
import SwiftData

struct MeView: View {
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Spacing.lg) {
                    ProfileCardView()

                    PlateCabinetView()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.Tab.me)
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
        }
    }
}

#Preview("Me Tab") {
    MeView()
        .modelContainer(for: [FastingRecord.self, UserSettings.self, UserProfile.self, FastingPlan.self, MoodRecord.self], inMemory: true)
}
