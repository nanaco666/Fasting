//
//  SettingsView.swift
//  Fasting
//

import SwiftUI

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

