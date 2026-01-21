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
            UserSettings.self
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
            
            // Insights
            StatisticsView()
                .tabItem {
                    Label(L10n.Tab.insights, systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .id(languageRefresh)
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            languageRefresh = UUID()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [FastingRecord.self, UserSettings.self], inMemory: true)
}
