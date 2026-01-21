# 技术架构文档

## 架构概览

本项目采用 **MVVM + Clean Architecture** 的分层架构，确保代码的可维护性、可测试性和可扩展性。

```
┌─────────────────────────────────────────────┐
│                   App Layer                  │
│  (FastingApp, ContentView, Navigation)       │
├─────────────────────────────────────────────┤
│               Features Layer                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────────┐   │
│  │  Timer  │ │ History │ │ Statistics  │   │
│  │  View   │ │  View   │ │    View     │   │
│  └────┬────┘ └────┬────┘ └──────┬──────┘   │
│       │           │              │          │
│  ┌────┴────┐ ┌────┴────┐ ┌──────┴──────┐   │
│  │  Timer  │ │ History │ │ Statistics  │   │
│  │ViewModel│ │ViewModel│ │  ViewModel  │   │
│  └────┬────┘ └────┬────┘ └──────┬──────┘   │
├───────┼───────────┼──────────────┼──────────┤
│       └───────────┼──────────────┘          │
│                   ▼                          │
│               Core Layer                     │
│  ┌─────────────────────────────────────┐   │
│  │           FastingService             │   │
│  │    (Business Logic & State Mgmt)     │   │
│  └─────────────────┬───────────────────┘   │
│                    │                         │
│  ┌─────────────────┴───────────────────┐   │
│  │              Models                  │   │
│  │  (FastingRecord, UserSettings)       │   │
│  └─────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│              Infrastructure                  │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐  │
│  │ SwiftData │ │ CloudKit  │ │HealthKit│  │
│  └───────────┘ └───────────┘ └──────────┘  │
└─────────────────────────────────────────────┘
```

---

## 目录结构

```
Fasting/
├── App/                        # 应用层
│   └── FastingApp.swift        # 应用入口 & 依赖注入
│
├── Features/                   # 功能模块层
│   ├── Timer/                  # 断食计时器
│   │   ├── TimerView.swift
│   │   └── TimerViewModel.swift (可选)
│   │
│   ├── History/                # 历史记录
│   │   ├── HistoryView.swift
│   │   └── HistoryViewModel.swift (可选)
│   │
│   ├── Statistics/             # 统计数据
│   │   ├── StatisticsView.swift
│   │   └── StatisticsViewModel.swift (可选)
│   │
│   └── Settings/               # 设置
│       └── SettingsView.swift
│
├── Core/                       # 核心层
│   ├── Models/                 # 数据模型
│   │   ├── FastingRecord.swift
│   │   └── UserSettings.swift
│   │
│   ├── Services/               # 服务层
│   │   ├── FastingService.swift
│   │   ├── NotificationService.swift
│   │   └── HealthKitService.swift
│   │
│   └── Extensions/             # 扩展
│       ├── Date+Extensions.swift
│       └── Color+Extensions.swift
│
├── UI/                         # UI 组件层
│   ├── Components/             # 可复用组件
│   │   ├── ProgressRing.swift
│   │   ├── StatCard.swift
│   │   └── PrimaryButton.swift
│   │
│   └── Theme/                  # 主题配置
│       └── Theme.swift
│
├── Resources/                  # 资源文件
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Tests/                      # 测试
    ├── UnitTests/
    └── UITests/
```

---

## 技术选型

### 1. UI 框架: SwiftUI

**理由**:
- 原生 Apple 框架，与系统深度集成
- 声明式语法，代码简洁
- 自动支持 Dynamic Type、VoiceOver
- 内置动画系统
- 支持 Previews，提高开发效率

**最低版本**: iOS 17.0

### 2. 数据持久化: SwiftData

**理由**:
- Apple 官方推荐的新一代持久化框架
- 与 SwiftUI 无缝集成
- 基于 Swift 宏，代码简洁
- 自动支持 CloudKit 同步

**替代方案**: Core Data (如需支持 iOS 16 及以下)

### 3. 图表: Swift Charts

**理由**:
- Apple 原生图表框架
- 与 SwiftUI 完美集成
- 自动适配深浅色模式
- 支持动画

### 4. 状态管理: @Observable (Observation 框架)

**理由**:
- iOS 17 新特性，性能更优
- 比 ObservableObject 更简洁
- 细粒度更新，减少不必要的重绘

### 5. 异步编程: Swift Concurrency

**理由**:
- 原生 async/await 支持
- 结构化并发
- Actor 模型保证线程安全

---

## 核心组件设计

### FastingService

职责：
- 管理断食状态（开始/结束/取消）
- 维护当前断食记录
- 计算进度和剩余时间
- 处理应用生命周期

```swift
@Observable
final class FastingService {
    private(set) var currentFast: FastingRecord?
    var isFasting: Bool { ... }
    var progress: Double { ... }
    
    func startFasting(preset:customDuration:) -> FastingRecord
    func endFasting()
    func cancelFasting()
}
```

### FastingRecord

职责：
- 存储断食记录数据
- 计算衍生属性（进度、是否达标等）
- 格式化输出

```swift
@Model
final class FastingRecord {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var targetDuration: TimeInterval
    var actualDuration: TimeInterval?
    var presetType: FastingPreset
    var status: FastingStatus
}
```

---

## 数据流

### 1. 开始断食流程

```
用户点击"开始断食"
       ↓
PresetSelectionSheet 显示
       ↓
用户选择方案
       ↓
FastingService.startFasting()
       ↓
创建 FastingRecord (状态: inProgress)
       ↓
存入 SwiftData
       ↓
保存 ID 到 UserDefaults (防止应用被杀)
       ↓
UI 更新显示计时器
```

### 2. 结束断食流程

```
用户点击"结束断食"
       ↓
确认对话框
       ↓
FastingService.endFasting()
       ↓
更新 FastingRecord (状态: completed)
       ↓
计算实际时长
       ↓
存入 SwiftData
       ↓
清除 UserDefaults 中的 ID
       ↓
触发成功反馈 (Haptic)
       ↓
UI 更新显示空闲状态
```

### 3. 应用恢复流程

```
应用启动/前台恢复
       ↓
FastingService.refresh()
       ↓
从 UserDefaults 读取保存的断食 ID
       ↓
从 SwiftData 查询对应记录
       ↓
如果存在且状态为 inProgress
       ↓
恢复 currentFast
       ↓
UI 继续显示计时器
```

---

## 未来扩展

### 1. Apple Watch 应用

```
FastingWatch/
├── FastingWatchApp.swift
├── ContentView.swift
├── ComplicationController.swift
└── ExtensionDelegate.swift
```

需要共享：
- Core/Models
- Core/Services (部分)

### 2. Widget

```
FastingWidget/
├── FastingWidget.swift
├── FastingWidgetBundle.swift
└── Provider.swift
```

支持：
- Small: 显示当前状态和进度
- Medium: 显示状态 + 本周统计
- Lock Screen: 进度环

### 3. Live Activities

```swift
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingAttributes.self) { context in
            // Live Activity UI
        } dynamicIsland: { context in
            // Dynamic Island UI
        }
    }
}
```

### 4. Siri Shortcuts

```swift
// App Intents
struct StartFastingIntent: AppIntent {
    static var title: LocalizedStringResource = "开始断食"
    
    func perform() async throws -> some IntentResult {
        FastingService.shared.startFasting(preset: .sixteen8)
        return .result()
    }
}
```

---

## 测试策略

### 单元测试

- `FastingServiceTests`: 测试断食服务逻辑
- `FastingRecordTests`: 测试模型计算属性
- `StatisticsCalculatorTests`: 测试统计计算

### UI 测试

- 断食流程 E2E 测试
- 历史记录浏览测试
- 设置变更测试

### 性能测试

- 启动时间
- 内存占用
- 图表渲染性能

---

## 依赖管理

本项目**不使用第三方依赖**，全部使用 Apple 原生框架：

- SwiftUI
- SwiftData
- Swift Charts
- Observation
- CloudKit
- HealthKit
- UserNotifications
- WidgetKit (后续)
- ActivityKit (后续)
