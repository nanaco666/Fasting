# Fasting App — 全面代码审查与 UAT 报告

**日期**: 2026-02-26
**审查范围**: 全部 39 个 Swift 源文件 + Widget Extension + 测试文件
**审查视角**: 顶级程序员（代码质量） + 顶级设计师（用户验收测试）

---

## 综合评分

```
程序员视角:  ████████████████░░░░  72 / 100
设计师视角:  ███████████████░░░░░  78 / 100
```

| 维度 | 评分 | 说明 |
|------|------|------|
| 架构设计 | 7/10 | MVVM 清晰，但 Singleton + @Observable 搭配有架构缺陷 |
| 代码质量 | 6/10 | 命名规范，多处崩溃风险和数据安全隐患 |
| 性能 | 5/10 | 热路径存在严重性能问题（Canvas、DateFormatter、O(n²)） |
| 健壮性 | 5/10 | `try?` 静默失败、除零风险、force unwrap |
| 可测试性 | 3/10 | 测试覆盖率为零 |
| 本地化 | 6/10 | 有框架但执行不彻底，多处硬编码英文残留 |
| 可维护性 | 7/10 | 文件拆分合理，800 行内联字典是隐患 |
| Apple 生态 | 9/10 | SwiftData + CloudKit + HealthKit + Widget 全面 |
| 视觉一致性 | 8/10 | 3 色主题 + 玻璃卡片统一，个别样式不一致 |
| 信息层级 | 8/10 | Timer 页层次分明，信息密度偏高 |
| 交互设计 | 7/10 | 核心流程流畅，缺少关键确认和反馈 |
| 无障碍 | 4/10 | 多处 VoiceOver 阻断性缺陷 |

---

# Part 1: 程序员视角 — 代码审查

---

## 🔴 P0 — 必须立即修复

### 1. 除零崩溃（3 处）

`FastingRecord.progress`、`FastingPlan.progress`、`UserProfile.bmi` 存在除零风险。

**FastingRecord.swift**
```swift
// 🔴 当前: targetDuration = 0 时产生 nan，传入 SwiftUI 导致布局崩溃
var progress: Double {
    min(currentDuration / targetDuration, 1.0)
}

// ✅ 修复:
var progress: Double {
    guard targetDuration > 0 else { return 0 }
    return min(currentDuration / targetDuration, 1.0)
}
```

**FastingPlan.swift**
```swift
// 🔴 durationWeeks = 0 时除零
var progress: Double {
    min(Double(weeksElapsed) / Double(durationWeeks), 1.0)
}
```

**UserProfile.swift**
```swift
// 🔴 heightCm = 0 时除零
var bmi: Double {
    let heightM = heightCm / 100
    return weightKg / (heightM * heightM)
}
```

**触发条件**: 用户选择 Custom preset 但未设置时长 / Plan 的 durationWeeks 为默认值 0 / 新建 Profile 未填身高。

---

### 2. App 入口 fatalError

**FastingApp.swift:32**
```swift
// 🔴 磁盘满或 CloudKit 配置错误时直接闪退，无法恢复
fatalError("Could not create ModelContainer: \(error)")
```

**修复方向**: 降级为 `ModelConfiguration(isStoredInMemoryOnly: true)` + 错误提示 Banner，让用户仍可使用基本功能。

---

### 3. 数据持久化静默失败

**FastingService.swift**（多处）
```swift
// 🔴 所有持久化操作用 try? 吞掉错误
modelContext?.insert(record)
try? modelContext?.save()
```

用户以为断食已开始/结束，但数据可能根本没存进去。至少应在 DEBUG 模式下用 `os.Logger` 记录错误。

---

### 4. 自动取消前一个断食无用户确认

**FastingService.swift:75-78**
```swift
// 🔴 用户误触"开始"，20 小时的断食被静默取消
if let current = currentFast, current.status == .inProgress {
    current.cancel()
}
```

**修复方向**: `startFasting()` 前检查是否有进行中的断食，若有则抛出错误或返回 `false`，由调用方（TimerView）弹出确认对话框。

---

### 5. FastingPlan 字符串分割越界崩溃

**FastingPlan.swift:23-27**
```swift
// 🔴 如果 description = "key|"，split 只有 1 个元素，parts[1] 越界
if description.contains("|") {
    let parts = description.split(separator: "|", maxSplits: 1)
    let key = String(parts[0])
    let arg = String(parts[1])  // 💥 Index out of range
}
```

---

### 6. 枚举回退掩盖数据损坏

**FastingRecord.swift:110-118**
```swift
// 🔴 无效的 statusRaw 默认回退到 .inProgress
// 一条损坏的记录会被当作"正在进行中的断食"
var status: FastingStatus {
    get { FastingStatus(rawValue: statusRaw) ?? .inProgress }
}
```

**修复方向**: 回退到 `.cancelled` 或 `.unknown` 更安全。

---

## 🟡 P1 — 高优先级

### 7. NoiseTexture Canvas 性能灾难

**Theme.swift:104-114**
```swift
// 🟡 iPhone 15 Pro: 393×852×0.02 ≈ 6,700 个随机椭圆
// 且每次 View 重绘都重新生成（Double.random 不确定性）
Canvas { context, size in
    for _ in 0..<Int(size.width * size.height * 0.02) {
        let x = Double.random(in: 0..<size.width)
        let y = Double.random(in: 0..<size.height)
        context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
            with: .color(.white.opacity(Double.random(in: 0.02...0.06)))
        )
    }
}
```

**修复方向**: 使用 `ImageRenderer` 预渲染为 `UIImage`，作为 `static let` 缓存。

---

### 8. DateFormatter 在 body 路径中创建

**TimerView.swift** — 3 处热路径每次调用都 `DateFormatter()`

```swift
// 🟡 TimerView.swift:169-173 — weekStrip 每秒调用 7 次
private func weekdayLabel(_ date: Date) -> String {
    let f = DateFormatter()   // 💰 创建成本极高
    f.dateFormat = "EEE"
    return f.string(from: date).uppercased()
}

// 🟡 同样的问题:
// - formatTimeShort (第 286 行)
// - formatTime (第 587 行)
// - StatisticsView.periodData (第 353、369 行)
```

**修复方向**:
```swift
private static let weekdayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE"
    return f
}()
```

---

### 9. O(n²) 统计算法

**StatisticsView.swift:331-342**
```swift
// 🟡 100 条记录 = 10,000 次比较
private var bestWeekCount: Int {
    for record in completedRecords {
        let count = completedRecords.filter { $0.startTime >= start && $0.startTime < end }.count
        best = max(best, count)
    }
    return best
}
```

**同样昂贵的 computed properties**:
- `dayCompleted()` — TimerView 中 7 天 × 全量扫描 × 每秒
- `dayProgress()` — HistoryView 中 31 天 × 全量过滤
- `currentStreak` — while 循环 × 每天全量查找（在 HistoryView 和 StatisticsView 中重复实现）
- `completedRecords` — 被多个属性反复调用，每次都重新 `.filter`

**修复方向**: 预处理为 `[Date: [FastingRecord]]` 字典，streak 计算结果缓存为 `@State`。

---

### 10. BodyVisualization 30fps Canvas 持续运行

**BodyVisualization.swift:51**
```swift
// 🟡 即使用户不在看也以 30fps 持续重绘
TimelineView(.animation(minimumInterval: 1/30)) { context in
    Canvas { ctx, size in
        // 每帧重建粒子数组（最多 60 个 Particle）
        particles = particles.compactMap { ... }
    }
}
```

**同样的问题**: MoodCheckInView 的 mood orb 也以 30fps 持续运行。

**修复方向**: 监听 `ScenePhase`，后台时暂停；或检查视图可见性。

---

### 11. @Observable Singleton 架构缺陷

**FastingService.swift**
```swift
@Observable
final class FastingService {
    static let shared = FastingService()
}
```

`@Observable` 搭配 singleton，无法通过 `@Environment` 正确传播。各 View 引用方式不一致：
- `TimerView`: `@State private var fastingService = FastingService.shared` ✅
- `PlanView`: `private var healthService: HealthKitService { HealthKitService.shared }` ❌

**修复方向**: 使用 `.environment()` 注入，或统一所有引用为 `@State`。

---

### 12. 本地化系统架构性问题

**Strings.swift** — 800+ 行内联字典

```swift
// 🟡 无法使用 Xcode 本地化工具链，添加第三种语言时每条都要改
enum LocalizedStrings {
    static let all: [String: [String: String]] = [
        "timer_title": ["en": "Timer", "zh": "计时器"],
        // ... 800+ 行
    ]
}
```

**额外问题**:
- `.localized` 无缓存，Timer 每秒数十次调用 × 字典查找 × Bundle 加载
- 混用 `L10n.X.y` 和 `"key".localized` 两种方式
- `LanguageManager` 切换语言后，内部页面的 computed property 不会重新计算

**修复方向**: 迁移到标准 `.strings` / `.xcstrings` 文件。

---

### 13. Widget 进度环不实时更新

**FastingWidget.swift**
```swift
// 🟡 文字用 Text(date, style: .timer) 自动更新
// 但进度环用 entry.progress，创建时就固定了
// 结果: 文字在跳，环不动
Circle()
    .trim(from: 0, to: entry.progress)
```

**另外**: Timeline 生成 60 个 entry，但 reload policy 设为 30 分钟，60-90 分钟间可能出现数据停滞。

---

### 14. SharedFastingData 代码重复

**两份独立维护的 `SharedFastingState`**:
- `Fasting/Core/Services/SharedFastingData.swift`（含读写 + 计算属性）
- `FastingWidget/SharedFastingData.swift`（只读）

如果任一方添加新字段而另一方没同步，`JSONDecoder` 会静默失败，Widget 显示 "Not Fasting" 的错误状态。

**修复方向**: 创建 Shared Swift Package，两个 target 共用同一份代码。

---

## 🟢 P2 — 中优先级

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| 15 | `FlowLayout` 未使用 cache | FlowLayout.swift | `arrange()` 在 `sizeThatFits` 和 `placeSubviews` 中各调用一次 |
| 16 | `milestones` JSON 每次访问都解码 | FastingPlan.swift | UI 频繁读取时性能问题 |
| 17 | HealthKit `isAuthorized` 不反映真实状态 | HealthKitService.swift | `requestAuthorization` 成功仅表示弹窗已展示 |
| 18 | 通知 `timeInterval` 竞态条件 | NotificationService.swift | `halfwayDate > Date()` 检查到 trigger 创建间有时间差 |
| 19 | `ChartData.id = UUID()` | StatisticsView.swift | 每次重算获得新 UUID，Charts 无法增量更新 |
| 20 | 6 个 Bool `@State` 控制 sheet | TimerView.swift | 互斥状态应用 `enum SheetDestination` |
| 21 | 版本号硬编码 `"1.2.0"` | SettingsView.swift | 应从 Bundle.main.infoDictionary 读取 |
| 22 | iCloud 同步状态硬编码 ✓ | SettingsView.swift | 不管实际状态，给用户虚假信息 |
| 23 | `HapticService.swift` 文件名 vs `Haptic` 类型名 | HapticService.swift | 每次调用都创建新 Generator，未 prepare() |
| 24 | 农历缓存仅覆盖 2025-2027 | HolidayService.swift | 2028 年起节假日功能静默失效 |
| 25 | `RefeedGuide` 用 `var`（computed）而非 `let` | RefeedGuide.swift | 每次调用重新构建整个 RefeedPlan |
| 26 | 测试覆盖率为零 | FastingTests.swift | 全部为 Xcode 生成的模板代码 |
| 27 | `print` 用于日志 | PlanView.swift, HealthKitService.swift | 生产环境应使用 `os.Logger` |
| 28 | `.repeatForever` 动画叠加 | BodyVisualization, WatchDialView | 视图回收再重建时 `onAppear` 叠加多次动画 |
| 29 | `configure()` 前调用的方法全部静默无效 | FastingService.swift | `modelContext` 初始为 nil |
| 30 | `MoodRecord` 缺少显式 `id` | MoodRecord.swift | 跨设备同步时可能出问题 |

---

## ✅ 代码亮点

- **零第三方依赖** — 全部使用系统框架，减少维护负担
- **文件组织清晰** — `Core/Models`、`Core/Services`、`Features/`、`UI/` 分层合理
- **WatchDialView** — Canvas 分段渐变弧线实现优雅，24h 表盘设计精巧
- **CompanionEngine** — 阶段性鼓励文案是很好的 UX 工程
- **HolidayService** — 节假日断食建议是独特的差异化功能
- **SwiftData + CloudKit** — 自动同步方案选型正确
- **Widget 全覆盖** — Small/Medium/Lockscreen 三种规格

---

# Part 2: 设计师视角 — 用户验收测试 (UAT)

---

## 🔴 Critical — 阻断性问题

### C1: 心情滑块对 VoiceOver 完全不可用

**MoodCheckInView.swift:202-253**

自定义滑块使用 `DragGesture` 实现：
- 没有 `accessibilityValue`
- 没有 `accessibilityAdjustableAction`（VoiceOver 用户无法调整值）
- 没有 `accessibilityLabel`
- 完全依赖触摸手势，键盘/VoiceOver 不可操作

**影响**: VoiceOver 用户完全无法设置心情。ADA 合规审查中是不及格项。

**修复方向**:
```swift
.accessibilityElement()
.accessibilityLabel("Mood level")
.accessibilityValue("\(Int(moodLevel * 100))%")
.accessibilityAdjustableAction { direction in
    switch direction {
    case .increment: moodLevel = min(moodLevel + 0.1, 1.0)
    case .decrement: moodLevel = max(moodLevel - 0.1, 0.0)
    @unknown default: break
    }
}
```

---

### C2: 核心 UI 文案硬编码英文

中文用户在**每天都会看到**的界面上看到英文：

| 位置 | 硬编码文本 | 应该是 |
|------|-----------|--------|
| TimerView 计时器卡片 | "STARTED" | "开始时间" |
| TimerView 计时器卡片 | "GOAL" / "START" | "目标" / "开始" |
| WatchDialView 中心 | "COMPLETED" | "已完成" |
| WatchDialView 中心 | "LAST FAST" | "上次断食" |
| TimerView 日期文本 | "Today" / "Tomorrow" / "days away" | "今天" / "明天" / "天后" |
| Widget | "Remaining" / "Done ✅" / "Not Fasting" / "Tap to start" | 中文对应 |
| StatisticsView | "Day Streak" / "Longest" / "Best" / "Weekly" | 中文对应 |

---

### C3: weekStrip 点击有触觉反馈但无功能

**TimerView.swift:155-158**
```swift
.onTapGesture {
    Haptic.selection()
    // Future: Navigate to day details   ← 未实现
}
```

用户点击后有触觉反馈但没有任何视觉响应或功能。比没有点击更糟——制造了"坏了"的印象。

**修复方向**: 要么实现跳转，要么移除 `onTapGesture` 和触觉反馈。

---

## 🟡 Major — 高优先级

### M1: 空闲状态"开始"按钮直接启动，无方案选择

**TimerView.swift:315-318**
```swift
Button {
    let preset = FastingPreset(rawValue: idleDefaultPreset) ?? .sixteen8
    fastingService.startFasting(preset: preset, customDuration: nil)
}
```

新用户首次使用时，没有选择方案的机会就已经开始了 16:8 断食。

**修复方向**: 首次使用时，开始按钮跳转到方案选择 sheet。

---

### M2: 结束断食 → 复食指南的时序问题

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    showRefeedGuide = true
}
```

如果用户在 0.5 秒内快速切换 tab，sheet 可能在错误的上下文中弹出。

---

### M3: Onboarding 可滑动跳过步骤

`.page` 风格的 TabView 允许用户左右滑动到任意步骤，绕过数据输入顺序。用户可以不填身体数据就跳到 Summary，生成错误的计划。

**修复方向**: 添加 `.scrollDisabled(true)` 或改用自定义容器。

---

### M4: Settings 页 iCloud 同步状态造假

**SettingsView.swift:56-60**
```swift
Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(Color.fastingGreen)
// ⬆️ 硬编码，不管用户是否真的开启了 iCloud
```

误导用户以为数据安全，实际可能没有备份。

---

### M5: `resetPlan()` 一键删除无二次确认

**PlanView.swift:486-494**

直接删除所有 plans **和** profiles，没有二次确认对话框。一个错误点击就会丢失所有数据。

---

### M6: 统计页空状态缺少引导

没有任何断食记录时，只显示 "No Current Streak" + 空图表。应有引导性空状态：
> "完成第一次断食，开始追踪你的数据 🎯"

---

## 🟢 Minor — 可后续优化

| # | 问题 | 影响 |
|---|------|------|
| m1 | Timer 页信息密度偏高（Week Strip + Dial + Info + Mood + Phase + Holiday 全在一屏） | 新用户信息过载 |
| m2 | `PrimaryButton` 用 `.accentColor` 而非 `Color.fastingGreen` | 与主题色脱节 |
| m3 | `.repeatForever` 动画在视图回收后重叠 | 发光效果异常闪烁 |
| m4 | 月导航按钮（History 页左右箭头）无 VoiceOver 标签 | 无障碍缺陷 |
| m5 | `CircularActionButton` 用 `DragGesture` 模拟按下效果 | 应使用自定义 `ButtonStyle` |
| m6 | Picker 使用空标签 `""` | VoiceOver 无法识别控件用途 |
| m7 | BodyJourneyView 时间线连接线使用固定像素高度 | Dynamic Type 大字体模式下溢出 |
| m8 | Widget 用 emoji "Done ✅" | 应用 SF Symbol 保持原生风格 |

---

## ✅ 设计亮点

- **WatchDialView** — 24 小时表盘 + 渐变弧线 + 呼吸光晕，精致的核心视觉
- **3 色主题**（Green/Teal/Orange）克制统一，符合 Apple Health 色彩语言
- **玻璃卡片** — `glassCard` 视觉层次分明，材质效果优雅
- **断食阶段卡片** — 展开/折叠交互自然，信息组织合理
- **节假日断食建议** — 出色的差异化设计，展现产品文化关怀
- **Mood Check-in** — emoji + 渐变 orb 设计感强
- **Week Strip** — Apple Fitness 风格的活动环周视图

---

# Part 3: 优先级行动计划

## 🔴 第一梯队 — 发布前必修复

```
┌─────────────────────────────────────────────────┐
│  1. 修复 3 处除零崩溃                              │
│  2. 替换 fatalError 为优雅降级                      │
│  3. 心情滑块添加 VoiceOver 支持                     │
│  4. 本地化所有硬编码英文核心 UI 文案                   │
│  5. 移除 weekStrip 无功能点击反馈                    │
│  6. startFasting 前确认是否取消现有断食               │
└─────────────────────────────────────────────────┘
```

## 🟡 第二梯队 — 下个迭代

```
┌─────────────────────────────────────────────────┐
│  7. NoiseTexture Canvas 预渲染为 UIImage           │
│  8. DateFormatter 缓存为 static let               │
│  9. 统计算法从 O(n²) 优化到 O(n)                    │
│ 10. 数据持久化 try? 改为有日志的错误处理              │
│ 11. Widget 进度环改为实时更新                        │
│ 12. SharedFastingData 抽取为 Shared Framework      │
│ 13. 首次使用时引导选择断食方案                        │
│ 14. Onboarding 禁用滑动跳步                        │
└─────────────────────────────────────────────────┘
```

## 🟢 第三梯队 — 长期改善

```
┌─────────────────────────────────────────────────┐
│ 15. 补充核心逻辑单元测试（目标覆盖率 60%+）          │
│ 16. 本地化系统迁移到标准 .strings 文件              │
│ 17. @Observable singleton → Environment 注入       │
│ 18. 30fps Canvas 加视图可见性节流                   │
│ 19. resetPlan 添加二次确认                         │
│ 20. 农历缓存扩展或添加运行时 fallback               │
└─────────────────────────────────────────────────┘
```

---

## 总结

这是一个**功能完整度很高、设计品味不错**的断食追踪 App。WatchDial 表盘、阶段卡片、节假日建议等设计令人印象深刻，零第三方依赖的技术选型也很干净。

核心短板在三个方面：
1. **健壮性** — 崩溃风险和数据安全隐患需要优先修复
2. **性能** — 热路径的 DateFormatter/Canvas/O(n²) 在数据量增长后会明显卡顿
3. **无障碍** — 如果目标是 ADA，VoiceOver 缺陷是最紧迫的短板

建议按上述优先级逐步修复：先确保**不崩溃、不丢数据**，再打磨**性能和体验**。
