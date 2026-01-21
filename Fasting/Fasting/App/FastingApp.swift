//
//  FastingApp.swift
//  Fasting
//
//  应用入口
//

import SwiftUI
import SwiftData

@main
struct FastingApp: App {
    // MARK: - Properties
    
    /// SwiftData 模型容器
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FastingRecord.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // 启用 iCloud 同步
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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 计时器页面
            TimerView()
                .tabItem {
                    Label("断食", systemImage: "timer")
                }
                .tag(0)
            
            // 历史记录页面
            HistoryView()
                .tabItem {
                    Label("历史", systemImage: "calendar")
                }
                .tag(1)
            
            // 统计页面
            StatisticsView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [FastingRecord.self, UserSettings.self], inMemory: true)
}
