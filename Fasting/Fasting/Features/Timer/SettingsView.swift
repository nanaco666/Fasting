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
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0  // 0=system, 1=light, 2=dark
    
    var body: some View {
        List {
            // MARK: - Fasting
            Section("Fasting".localized) {
                Picker(L10n.Settings.defaultPlan, selection: $defaultPreset) {
                    ForEach(FastingPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                }
                
                Toggle(L10n.Settings.notifications, isOn: $notificationsOn)
            }
            
            // MARK: - Appearance
            Section("Appearance".localized) {
                Picker("Appearance".localized, selection: $appearanceMode) {
                    Text("System".localized).tag(0)
                    Text("Light".localized).tag(1)
                    Text("Dark".localized).tag(2)
                }
                
                Picker(L10n.Settings.language, selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { languageManager.currentLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }
            
            // MARK: - Data
            Section(L10n.Settings.data) {
                Button {
                    Task { await healthService.requestAuthorization() }
                } label: {
                    HStack {
                        Text(L10n.Settings.healthSync)
                            .foregroundStyle(.primary)
                        Spacer()
                        if healthService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Connect".localized)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text(L10n.Settings.iCloudSync)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            // MARK: - About
            Section(L10n.Settings.about) {
                HStack {
                    Text(L10n.Settings.version)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L10n.Settings.title)
        .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}

// MARK: - Edit Start Time Sheet
