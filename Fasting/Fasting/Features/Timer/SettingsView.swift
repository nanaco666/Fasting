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
            Section {
                Picker(selection: $defaultPreset) {
                    ForEach(FastingPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset.rawValue)
                    }
                } label: {
                    Label(L10n.Settings.defaultPlan, systemImage: "clock")
                        .foregroundStyle(.primary)
                }
                
                Toggle(isOn: $notificationsOn) {
                    Label(L10n.Settings.notifications, systemImage: "bell")
                        .foregroundStyle(.primary)
                }
                .tint(Color.fastingGreen)
            } header: {
                Text(L10n.Settings.fastingSettings)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - Appearance
            Section {
                Picker(selection: $appearanceMode) {
                    Text("System".localized).tag(0)
                    Text("Light".localized).tag(1)
                    Text("Dark".localized).tag(2)
                } label: {
                    Label("Appearance".localized, systemImage: "circle.lefthalf.filled")
                        .foregroundStyle(.primary)
                }
                
                Picker(selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { languageManager.currentLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                } label: {
                    Label(L10n.Settings.language, systemImage: "globe")
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("Appearance".localized)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - Data
            Section {
                Button {
                    Task { await healthService.requestAuthorization() }
                } label: {
                    HStack {
                        Label(L10n.Settings.healthSync, systemImage: "heart")
                            .foregroundStyle(.primary)
                        Spacer()
                        if healthService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.fastingGreen)
                        } else {
                            Text("Connect".localized)
                                .font(.subheadline)
                                .foregroundStyle(Color.fastingTeal)
                        }
                    }
                }
                
                HStack {
                    Label(L10n.Settings.iCloudSync, systemImage: "icloud")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.fastingGreen)
                }
            } header: {
                Text(L10n.Settings.data)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            // MARK: - About
            Section {
                HStack {
                    Label(L10n.Settings.version, systemImage: "info.circle")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(L10n.Settings.about)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
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
