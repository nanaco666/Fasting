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
            // Fallback: try without CloudKit, then in-memory
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            if let container = try? ModelContainer(for: schema, configurations: [fallbackConfig]) {
                return container
            }
            // Last resort: in-memory so the app at least launches
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }()
    
    // MARK: - Body
    
    // Notification permission is now requested at first fast start, not app launch
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var auth = AuthService.shared
    @State private var selectedTab = 0
    @State private var languageRefresh = UUID()
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        if !auth.isSignedIn {
            AuthView()
                .transition(.opacity)
        } else {
        TabView(selection: $selectedTab) {
            // Timer
            TimerView()
                .tabItem {
                    Label(L10n.Tab.timer, systemImage: "timer")
                }
                .tag(0)
            
            // Plan (includes calendar + history)
            PlanView()
                .tabItem {
                    Label(L10n.Tab.plan, systemImage: "target")
                }
                .tag(1)

            // Me
            MeView()
                .tabItem {
                    Label(L10n.Tab.me, systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .onAppear {
            UITabBar.appearance().tintColor = UIColor(Color.fastingGreen)
        }
        .id(languageRefresh)
        .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            languageRefresh = UUID()
        }
        .preferredColorScheme(appearanceMode == 1 ? .light : appearanceMode == 2 ? .dark : nil)
        .onChange(of: scenePhase) { _, phase in
            // Keep widget shared state aligned when returning from background / after SwiftData+CloudKit updates
            if phase == .active {
                FastingService.shared.refresh()
            }
        }
        .onOpenURL { url in
            if url.host == "timer" { selectedTab = 0 }
            else if url.host == "plan" || url.host == "history" { selectedTab = 1 }
            else if url.host == "me" { selectedTab = 2 }
        }
        } // else (signed in)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [FastingRecord.self, UserSettings.self, UserProfile.self, FastingPlan.self, MoodRecord.self], inMemory: true)
}
