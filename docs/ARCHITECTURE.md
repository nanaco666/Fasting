# 技术架构文档

## 架构概览

**轻量 Feature-Sliced 架构**，无 ViewModel 层。View 直接持有 `@Query` 和调用 `@Observable` Service。

```
┌─────────────────────────────────────────────┐
│                   App Layer                  │
│  FastingApp.swift — TabView + auth gate      │
├─────────────────────────────────────────────┤
│               Features Layer                 │
│  ┌─────────┐ ┌─────────┐ ┌──────────────┐  │
│  │  Timer  │ │  Plan   │ │    Auth      │  │
│  │  Views  │ │  Views  │ │    View      │  │
│  └────┬────┘ └────┬────┘ └──────┬───────┘  │
│       │           │              │          │
│       └───────────┼──────────────┘          │
│                   ▼                          │
│               Core Layer                     │
│  ┌─────────┐ ┌─────────┐ ┌──────────────┐  │
│  │ Models  │ │Services │ │ Localization │  │
│  └─────────┘ └─────────┘ └──────────────┘  │
├─────────────────────────────────────────────┤
│                UI Layer                      │
│  ┌───────────┐ ┌───────────────────────┐   │
│  │Components │ │  Theme (Design Sys)   │   │
│  └───────────┘ └───────────────────────┘   │
├─────────────────────────────────────────────┤
│              Infrastructure                  │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │SwiftData │ │HealthKit │ │ EventKit  │  │
│  └──────────┘ └──────────┘ └───────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │ App Group│ │ Keychain │ │UserNotif  │  │
│  └──────────┘ └──────────┘ └───────────┘  │
└─────────────────────────────────────────────┘
```

---

## 目录结构（实际）

```
Fasting/
├── App/
│   └── FastingApp.swift              # 入口、TabView、auth gate、lifecycle
│
├── Features/
│   ├── Auth/
│   │   └── AuthView.swift            # Apple Sign In 登录页
│   │
│   ├── Timer/                        # 主页 — 断食计时器
│   │   ├── TimerView.swift           # 主页面（timer card + mood + body phase）
│   │   ├── BodyJourneyView.swift     # 断食生理阶段旅程（idle + active）
│   │   ├── BodyVisualization.swift   # 身体可视化效果
│   │   ├── PresetSelectionSheet.swift # 方案选择 sheet
│   │   ├── EditStartTimeSheet.swift  # 修改断食开始时间
│   │   ├── EditGoalSheet.swift       # 修改断食目标
│   │   ├── QuickThemePickerSheet.swift # 快速主题切换
│   │   └── SettingsView.swift        # 设置页
│   │
│   ├── Companion/                    # 陪伴系统
│   │   ├── MoodCheckInView.swift     # 身心签到（布辛格量表）
│   │   └── RefeedGuideView.swift     # 复食指南
│   │
│   ├── Plan/                         # 计划系统
│   │   ├── PlanView.swift            # 计划主页（overview + nutrition + calendar + fitness）
│   │   ├── OnboardingFlow.swift      # 计划引导流程
│   │   └── WeekScheduleView.swift    # 周计划视图
│   │
│   └── History/
│       └── HistoryView.swift         # 历史日历视图
│
├── Core/
│   ├── Models/
│   │   ├── FastingRecord.swift       # 断食记录 (@Model)
│   │   ├── FastingPlan.swift         # 个性化断食计划 (@Model)
│   │   ├── FastingPhase.swift        # 断食生理阶段定义
│   │   ├── MoodRecord.swift          # 身心福祉记录 (@Model)
│   │   ├── UserProfile.swift         # 用户身体参数 (@Model)
│   │   ├── UserSettings.swift        # 用户设置
│   │   └── PlateTheme.swift          # 主题定义 + ThemeManager
│   │
│   ├── Services/
│   │   ├── FastingService.swift      # 断食状态管理（核心）
│   │   ├── AuthService.swift         # Apple Sign In + Keychain
│   │   ├── PlanCalculator.swift      # 科学计算引擎（TDEE/BMR/DGA）
│   │   ├── CompanionEngine.swift     # 陪伴引擎（身心响应 + 安全守护）
│   │   ├── CalendarService.swift     # EventKit 日历集成
│   │   ├── HealthKitService.swift    # HealthKit 运动/活动数据
│   │   ├── NotificationService.swift # 本地通知
│   │   ├── HapticService.swift       # 触觉反馈
│   │   └── SharedFastingData.swift   # App ↔ Widget 数据共享
│   │
│   ├── Data/
│   │   ├── FitnessRecommendations.swift # 健身建议数据
│   │   ├── HolidayService.swift      # 节假日数据
│   │   └── RefeedGuide.swift         # 复食指南数据
│   │
│   └── Localization/
│       └── Strings.swift             # 内联翻译字典（en + zh-Hans）
│
├── UI/
│   ├── Components/
│   │   ├── SimpleDialView.swift      # 简约进度环
│   │   ├── WatchDialView.swift       # 手表风格 dial
│   │   ├── PlateDialView.swift       # 餐盘扇形 dial
│   │   ├── SolarDialView.swift       # 日晷风格 dial（暗色专属）
│   │   ├── TimerDialStyle.swift      # Dial 样式枚举 + TimerDial 分发
│   │   ├── PrimaryButton.swift       # 主操作按钮
│   │   ├── CalendarHelpers.swift     # 日历辅助视图
│   │   └── FlowLayout.swift         # 流式布局
│   │
│   └── Theme/
│       └── Theme.swift               # 设计系统（颜色、字体、间距、GlassCard、OpaqueCard）
│
└── Resources/
    └── Assets.xcassets               # 图片资源（含 Themes/ 命名空间）

FastingWidget/                        # Widget 扩展
├── FastingWidget.swift               # Widget 实现
├── FastingWidgetBundle.swift         # Widget bundle
└── SharedFastingData.swift           # 共享数据
```

---

## 技术选型

| 领域 | 技术 | 最低版本 |
|------|------|---------|
| UI | SwiftUI | iOS 17.0 |
| 持久化 | SwiftData | iOS 17.0 |
| 状态管理 | `@Observable` (Observation) | iOS 17.0 |
| 图表 | Swift Charts | iOS 17.0 |
| 认证 | AuthenticationServices (Apple Sign In) | iOS 17.0 |
| 日历 | EventKit | — |
| 健康 | HealthKit | — |
| 通知 | UserNotifications | — |
| Widget | WidgetKit + App Groups | — |
| 异步 | Swift Concurrency (async/await) | — |

**零第三方依赖** — 全部 Apple 原生框架。

---

## 数据模型

### SwiftData Models

| Model | 用途 |
|-------|------|
| `FastingRecord` | 断食记录（开始/结束时间、方案、状态） |
| `FastingPlan` | 个性化断食计划（阶段、里程碑、营养目标） |
| `UserProfile` | 用户身体参数（身高/体重/性别/活动量） |
| `MoodRecord` | 身心签到（布辛格量表：情绪/能量/饥饿/体感） |

### 非持久化 Models

| Type | 用途 |
|------|------|
| `PlateTheme` | 主题定义（背景、餐盘、颜色） |
| `FastingPhase` | 断食生理阶段（0-72h 代谢变化） |
| `FastingPreset` | 预设方案（16:8/18:6/20:4/OMAD/自定义） |

---

## 核心 Services

### FastingService（核心状态机）
```
Idle → [startFasting] → InProgress → [endFasting] → Completed → Idle
                                    → [cancelFasting] → Cancelled → Idle
```
- `@Observable` singleton
- 持有 `currentFast: FastingRecord?`
- 通过 `SharedFastingData` 同步状态到 Widget
- `configure(with: ModelContext)` 在 `onAppear` 时注入

### PlanCalculator（科学计算引擎）
- BMR/TDEE 计算（Mifflin-St Jeor）
- DGA 2025-2030 营养份量计算
- 减重速率和阶段规划
- 生成个性化 `FastingPlan`

### CompanionEngine（陪伴引擎）
- 断食阶段感知的消息生成
- 身心福祉分析（基于 MoodRecord）
- 安全守护（异常状态预警）

### AuthService
- Apple Sign In + Keychain credential 存储
- `isSignedIn` 状态控制 app gate

---

## 数据流

### App 启动
```
FastingApp.body
  → AuthService.isSignedIn?
    → No: AuthView (Apple Sign In)
    → Yes: TabView
      → Tab 0: TimerView
        → onAppear: FastingService.configure(modelContext)
        → 恢复进行中的断食（如有）
      → Tab 1: PlanView
```

### Widget 数据同步
```
FastingService.syncToWidget()
  → SharedFastingData (App Groups UserDefaults)
    → FastingWidget reads via SharedFastingData
```

### 主题切换
```
ThemeManager.shared.currentTheme = newTheme
  → UserDefaults["selectedThemeId"] 持久化
  → @Observable 触发 TimerView 重绘
  → TableclothBackground 更新背景
  → Dial views 读取新 progressColor
  → Timer card themeColor 更新
```

---

## 未来扩展

### 已实现
- ✅ Widget（Small）
- ✅ 主题系统（5 built-in themes）
- ✅ 身心签到（布辛格量表）
- ✅ 复食指南
- ✅ 日历集成（EventKit）
- ✅ HealthKit（运动/活动）
- ✅ Apple Sign In

### 计划中
- ⏳ TestFlight 上架
- ⏳ Developer 账号激活 → Sign in with Apple 配置
- ⏳ Apple Watch 应用
- ⏳ Live Activities / Dynamic Island
- ⏳ Siri Shortcuts (App Intents)
- ⏳ 自定义主题（用户上传桌布图片）
