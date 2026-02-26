//
//  FastingApp.swift
//  Fasting
//
//  App entry point
//

import SwiftUI
import SwiftData

@main
struct FastingApp: App {
    // MARK: - Properties
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FastingRecord.self,
            UserSettings.self,
            UserProfile.self,
            FastingPlan.self,
            MoodRecord.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Body
    
    init() {
        NotificationService.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var languageRefresh = UUID()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Timer
            TimerView()
                .tabItem {
                    Label(L10n.Tab.timer, systemImage: "timer")
                }
                .tag(0)
            
            // History
            HistoryView()
                .tabItem {
                    Label(L10n.Tab.history, systemImage: "calendar")
                }
                .tag(1)
            
            // Plan
            PlanView()
                .tabItem {
                    Label("Plan".localized, systemImage: "target")
                }
                .tag(2)
            

        }
        .tint(Color.fastingGreen)
        .symbolRenderingMode(.hierarchical)
        .id(languageRefresh)
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            languageRefresh = UUID()
        }
        .preferredColorScheme(appearanceMode == 1 ? .light : appearanceMode == 2 ? .dark : nil)
        .onOpenURL { url in
            if url.host == "timer" { selectedTab = 0 }
            else if url.host == "history" { selectedTab = 1 }
            else if url.host == "plan" { selectedTab = 2 }

        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [FastingRecord.self, UserSettings.self, UserProfile.self, FastingPlan.self], inMemory: true)
}
