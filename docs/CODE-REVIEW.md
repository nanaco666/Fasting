# Fasting App — 全面代码审查与 UAT 报告

**日期**: 2026-02-26 (Rev.2)
**审查范围**: 全部 43 个 Swift 源文件 + Widget Extension + 测试文件
**审查视角**: 顶级程序员（代码质量） + 顶级设计师（用户验收测试）
**自上次审查以来**: +11 commits，新增 4 个表盘组件，统一断食阶段模型，Tab 精简为 3 个，布局重构

---

## 综合评分

```
                      Rev.1    Rev.2    变化
程序员视角:            72       74       +2  ▲
设计师视角:            78       81       +3  ▲
```

| 维度 | Rev.1 | Rev.2 | 变化 | 说明 |
|------|-------|-------|------|------|
| 架构设计 | 7 | 7.5 | ▲ | Tab 精简、阶段模型统一、表盘策略模式 |
| 代码质量 | 6 | 6.5 | ▲ | CompanionEngine 大幅简化，但新增 force unwrap |
| 性能 | 5 | 5 | — | DateFormatter / O(n²) 未变，SolarDial Canvas 新增负担 |
| 健壮性 | 5 | 5.5 | ▲ | TimerView.progress 加了 guard，其余未变 |
| 可测试性 | 3 | 3 | — | 依然零测试覆盖 |
| 本地化 | 6 | 5.5 | ▼ | 硬编码英文从 2 个 View 扩散到 4 个表盘 |
| 可维护性 | 7 | 7 | — | 表盘拆分为独立文件好，但 4 份重复代码 |
| Apple 生态 | 9 | 9 | — | 不变 |
| 视觉一致性 | 8 | 9 | ▲ | 4 种表盘风格 + 统一卡片 + 按钮内嵌 |
| 信息层级 | 8 | 8.5 | ▲ | Action button 内嵌卡片，Mood 卡片交互更清晰 |
| 交互设计 | 7 | 7.5 | ▲ | 长按切换表盘，Mood 卡片可点击 |
| 无障碍 | 4 | 4 | — | 核心问题未修复 |

---

## 本次变更概览

### ✅ 已改善
| 原问题 | 改善情况 |
|--------|---------|
| P0 #1 除零崩溃 | **部分修复** — `TimerView.progress` 加了 `guard target > 0`，但 `FastingRecord.progress`、`FastingPlan.progress`、`UserProfile.bmi` 未改 |
| CompanionEngine force unwrap | **已修复** — `phaseMessage` 改为委托 FastingPhaseManager，消除了原来的嵌套逻辑 |
| 4th Tab 架构混乱 | **已修复** — 精简为 3 Tab（Timer/History/Plan），Statistics 合并到 History |
| Phase 模型碎片化 | **已修复** — 统一为 11 阶段模型，科学描述 + 陪伴语合并 |
| TimerView 代码膨胀 | **已改善** — 表盘拆分为 4 个独立文件，Mood 卡片重构更简洁 |
| ActionButton 游离在外 | **已修复** — 内嵌到 timerCard 中，视觉分组更合理 |
| 死代码 `moodCheckInContent` | **已修复** — 替换为更简洁的 `moodCard` 实现 |

### 🆕 新增问题
| 问题 | 严重度 | 位置 |
|------|--------|------|
| "COMPLETED"/"LAST FAST" 硬编码扩散到 4 个表盘 | P1 | Simple/Watch/Plate/SolarDialView |
| PlateDialView 刻度用 `.white` — 浅色模式不可见 | P1 | PlateDialView.swift |
| SolarDialView 全部暗色硬编码 — 浅色模式下完全失效 | P1 | SolarDialView.swift |
| `TimerDialStyle.next` force unwrap | P2 | TimerDialStyle.swift:37 |
| 长按切换表盘零可发现性 | P1-设计 | TimerView.swift:201 |
| `.id(style)` 强制销毁重建整个视图树 | P2 | TimerDialStyle.swift:92 |
| `PlanWeekTimeline` force unwrap + DateFormatter | P2 | TimerView.swift:663,740 |
| `planProgressSection` 死代码 | P3 | TimerView.swift:574-586 |
| `.repeatForever` 动画叠加扩散到 3 个表盘 | P2 | Plate/Solar/WatchDialView |

---

# Part 1: 程序员视角 — 代码审查

---

## 🔴 P0 — 必须立即修复

### 1. 除零崩溃（3 处残留） ⚠️ 部分修复

`TimerView.progress` 已加 guard ✅，但 Model 层 3 处未改：

**FastingRecord.swift**
```swift
// 🔴 仍未修复 — targetDuration = 0 时产生 nan
var progress: Double {
    min(currentDuration / targetDuration, 1.0)
}
```

**FastingPlan.swift**
```swift
// 🔴 仍未修复 — durationWeeks = 0 时除零
var progress: Double {
    min(Double(weeksElapsed) / Double(durationWeeks), 1.0)
}
```

**UserProfile.swift**
```swift
// 🔴 仍未修复 — heightCm = 0 时除零
var bmi: Double {
    let heightM = heightCm / 100
    return weightKg / (heightM * heightM)
}
```

---

### 2. App 入口 fatalError ❌ 未修复

**FastingApp.swift:32** — 仍然 `fatalError`。

---

### 3. 数据持久化静默失败 ❌ 未修复

**FastingService.swift** — 仍然 `try? modelContext?.save()`。

---

### 4. 自动取消前一个断食无用户确认 ❌ 未修复

---

### 5. FastingPlan 字符串分割越界崩溃 ❌ 未修复

---

### 6. 枚举回退掩盖数据损坏 ❌ 未修复

---

## 🟡 P1 — 高优先级

### 7. 🆕 SolarDialView 浅色模式完全失效

**SolarDialView.swift** — 全部使用硬编码暗色：

```swift
// 整个表盘基于暗色背景设计
Circle().fill(Color(white: 0.08))          // outerBezel — 近乎黑色
Circle().stroke(Color(white: 0.25), ...)   // 金属边框
.foregroundStyle(.white.opacity(...))      // 所有文字和刻度都是白色

// Inner circle 也是暗色
RadialGradient(colors: [Color(white: 0.12), Color(white: 0.06)], ...)
```

在浅色模式下：黑色圆盘 + 白色文字 → 突兀且与系统风格冲突。
在暗色模式下：效果很好。

**修复方向**: 使用 `@Environment(\.colorScheme)` 做双模适配，或限制 Solar 仅在暗色模式下可选。

---

### 8. 🆕 PlateDialView 浅色模式刻度不可见

**PlateDialView.swift:137**
```swift
// 刻度和标签全部使用 .white
.fill(Color.white.opacity(isPast && isFasting ? 0.8 : (isMajor ? 0.4 : 0.2)))
```

在浅色模式下：白色刻度 + 浅色背景 = 完全不可见。

**修复方向**: 改用 `Color.primary`，自动适配深浅色。

---

### 9. 🆕 硬编码英文扩散到 4 个表盘

之前只有 WatchDialView 一处 "COMPLETED"/"LAST FAST"，现在 4 个表盘都有：

| 文件 | 硬编码文本 |
|------|-----------|
| SimpleDialView.swift:49,63 | "COMPLETED", "LAST FAST" |
| WatchDialView.swift:262,278 | "COMPLETED", "LAST FAST" |
| PlateDialView.swift:209,225 | "COMPLETED", "LAST FAST" |
| SolarDialView.swift:339,351 | "COMPLETED", "LAST FAST" |
| TimerView.swift:212,219,223,231 | "STARTED", "GOAL", "START" |

**修复方向**: 提取到 `L10n.Timer` 命名空间，一处维护。

---

### 10. 🆕 长按切换表盘零可发现性

**TimerView.swift:201**
```swift
.onLongPressGesture(perform: switchDialStyle)
```

没有任何 UI 提示告诉用户可以长按切换表盘样式。这是一个"隐藏功能"——大多数用户永远不会发现。

**修复方向**: 
- Settings 中添加表盘选择器（主入口）
- 首次使用时显示 tooltip/coach mark
- 表盘上添加微妙的样式图标

---

### 11. NoiseTexture Canvas 性能灾难 ❌ 未修复

### 12. DateFormatter 在 body 路径中创建 ❌ 未修复

现在更多了一处：

**TimerView.swift:740-743** — `PlanWeekTimeline.dayLabel`
```swift
private func dayLabel(_ date: Date) -> String {
    let formatter = DateFormatter()    // 🟡 ForEach 循环内，7 天每天调用
    formatter.locale = Locale.current
    formatter.dateFormat = "EEE"
    return String(formatter.string(from: date).prefix(2))
}
```

**总计**: weekdayLabel、formatTimeShort、formatTime、dayLabel、StatisticsView 中 2 处 = **6 处**。

---

### 13. O(n²) 统计算法 ❌ 未修复

### 14. BodyVisualization 30fps Canvas 持续运行 ❌ 未修复

### 15. @Observable Singleton 架构缺陷 ❌ 未修复

### 16. 本地化系统架构性问题 ❌ 未修复

### 17. Widget 进度环不实时更新 ❌ 未修复

### 18. SharedFastingData 代码重复 ❌ 未修复

---

## 🟢 P2 — 中优先级

| # | 问题 | 位置 | 状态 |
|---|------|------|------|
| 19 | `FlowLayout` 未使用 cache | FlowLayout.swift | ❌ |
| 20 | `milestones` JSON 每次访问都解码 | FastingPlan.swift | ❌ |
| 21 | HealthKit `isAuthorized` 不反映真实状态 | HealthKitService.swift | ❌ |
| 22 | 通知 `timeInterval` 竞态条件 | NotificationService.swift | ❌ |
| 23 | `ChartData.id = UUID()` | StatisticsView.swift | ❌ |
| 24 | 6 个 Bool `@State` 控制 sheet | TimerView.swift | ❌ |
| 25 | 版本号硬编码 `"1.2.0"` | SettingsView.swift | ❌ |
| 26 | iCloud 同步状态硬编码 ✓ | SettingsView.swift | ❌ |
| 27 | `HapticService.swift` 命名与 `Haptic` 不一致 | HapticService.swift | ❌ |
| 28 | 农历缓存仅覆盖 2025-2027 | HolidayService.swift | ❌ |
| 29 | `RefeedGuide` 用 `var`（computed）而非 `let` | RefeedGuide.swift | ❌ |
| 30 | 测试覆盖率为零 | FastingTests.swift | ❌ |
| 31 | `print` 用于日志 | PlanView, HealthKitService | ❌ |
| 32 | `.repeatForever` 动画叠加 | Plate/Solar/WatchDialView | ❌ 范围扩大 |
| 33 | `configure()` 前方法静默无效 | FastingService.swift | ❌ |
| 34 | `MoodRecord` 缺少显式 `id` | MoodRecord.swift | ❌ |
| 35 | 🆕 `TimerDialStyle.next` force unwrap | TimerDialStyle.swift:37 | 🆕 |
| 36 | 🆕 `.id(style)` 强制销毁重建视图树 | TimerDialStyle.swift:92 | 🆕 |
| 37 | 🆕 `PlanWeekTimeline.weekDays` force unwrap | TimerView.swift:663 | 🆕 |
| 38 | 🆕 `planProgressSection` 死代码 | TimerView.swift:574-586 | 🆕 |
| 39 | 🆕 4 个表盘 `centerContent` 高度重复 | Simple/Watch/Plate/Solar | 🆕 |
| 40 | 🆕 Preview `modelContainer` 缺 `MoodRecord` | FastingApp.swift:100 | ❌ |
| 41 | 🆕 `CompanionEngine.symptomAdvice` 仍有 `symptoms.first!` | CompanionEngine.swift:68 | 🆕 |

---

## ✅ 代码亮点

- **零第三方依赖** — 全部使用系统框架，减少维护负担
- **文件组织清晰** — `Core/Models`、`Core/Services`、`Features/`、`UI/Components/` 分层合理
- **4 种表盘风格** — Simple/Clock/Plate/Solar，通过策略模式 `TimerDial` 统一分发 ✨ 新增
- **SolarDialView** — 多层 Canvas 渲染（bezel → ticks → labels → wedge → glow → center），视觉品质达到 ADA 水准 ✨ 新增
- **SectorShape 带动画支持** — `AnimatableData` 实现扇形渐变动画 ✨ 新增
- **统一 11 阶段模型** — 科学精准 + 人格化陪伴合并到 FastingPhase ✨ 新增
- **CompanionEngine 精简** — 从 156 行减到 120 行，职责更清晰 ✨ 改善
- **HolidayService** — 节假日断食建议是独特的差异化功能
- **SwiftData + CloudKit** — 自动同步方案选型正确
- **Widget 全覆盖** — Small/Medium/Lockscreen 三种规格

---

# Part 2: 设计师视角 — 用户验收测试 (UAT)

---

## 🔴 Critical — 阻断性问题

### C1: 心情滑块对 VoiceOver 完全不可用 ❌ 未修复

**MoodCheckInView.swift** — 自定义滑块使用 `DragGesture`：
- 没有 `accessibilityValue`、`accessibilityAdjustableAction`、`accessibilityLabel`
- VoiceOver 用户完全无法设置心情

---

### C2: 核心 UI 文案硬编码英文 ❌ 未修复，范围扩大

新增 4 个表盘后，"COMPLETED" 和 "LAST FAST" 从 1 处扩散到 **4 处**。
TimerView 的 "STARTED"/"GOAL"/"START" 也仍未修复。

---

### C3: weekStrip 点击有触觉反馈但无功能 ❌ 未修复

---

### 🆕 C4: SolarDial 浅色模式完全失效

SolarDialView 是纯暗色设计，在系统浅色模式下显示为：
- **黑色圆盘**置于浅色背景上，极度突兀
- 与其他 3 种表盘（都适配浅色模式）风格割裂
- 用户切换到 Solar 后再切换系统外观 → 视觉崩溃

---

## 🟡 Major — 高优先级

### M1: 空闲状态"开始"按钮直接启动 ❌ 未修复

### M2: 结束断食 → 复食指南的时序问题 ❌ 未修复

### M3: Onboarding 可滑动跳过步骤 ❌ 未修复

### M4: Settings 页 iCloud 同步状态造假 ❌ 未修复

### M5: `resetPlan()` 一键删除无二次确认 ❌ 未修复

### M6: ~~统计页空状态缺少引导~~ → 已随 Tab 合并调整

---

### 🆕 M7: 表盘切换功能隐藏过深

长按表盘可切换样式（Simple → Clock → Plate → Solar 循环），但：
- **零可发现性** — 没有任何 UI 提示
- **无法指定目标样式** — 只能循环切下一个
- **Settings 中无表盘设置入口**
- 大多数用户永远不会发现这个功能

**修复方向**: 
1. Settings 中加 "Timer Style" 选择器（四宫格预览）
2. 首次安装显示 onboarding tip
3. 表盘区域加微妙的样式指示图标

---

### 🆕 M8: PlateDialView 浅色模式刻度和标签不可见

白色刻度 + 白色标签在浅色背景上消失。与 Simple（使用 semantic color）和 Clock（使用 `Color.primary`）风格不一致。

---

## 🟢 Minor — 可后续优化

| # | 问题 | 影响 | 状态 |
|---|------|------|------|
| m1 | Timer 页信息密度偏高 | 新用户信息过载 | ❌ |
| m2 | `PrimaryButton` 用 `.accentColor` | 与主题色脱节 | ❌ |
| m3 | `.repeatForever` 动画叠加 | 发光效果异常闪烁 | ❌ 范围扩大 |
| m4 | 月导航按钮无 VoiceOver 标签 | 无障碍缺陷 | ❌ |
| m5 | `CircularActionButton` 用 `DragGesture` | 应用 `ButtonStyle` | ❌ |
| m6 | Picker 使用空标签 `""` | VoiceOver 无法识别 | ❌ |
| m7 | 时间线连接线固定像素高度 | Dynamic Type 溢出 | ❌ |
| m8 | Widget 用 emoji "Done ✅" | 应用 SF Symbol | ❌ |
| m9 | 🆕 4 个表盘的 `centerContent` 大量重复 | 维护负担 | 🆕 |
| m10 | 🆕 SolarDial 适合做暗色专属的 "premium" 皮肤 | 产品定位 | 🆕 |

---

## ✅ 设计亮点

- **4 种表盘风格** — Simple（简洁）、Clock（24h 表盘）、Plate（餐盘）、Solar（日晷）— 每种都有独特性格 ✨ 新增
- **SolarDialView** — 多层渲染 + 光楔效果 + 日光渐弱，ADA 级视觉品质 ✨ 新增
- **SectorShape 扇形动画** — 自定义 `AnimatableData` 实现丝滑的进度填充 ✨ 新增
- **Action Button 内嵌** — 开始/结束按钮在 timerCard 内部，视觉归属感更强 ✨ 改善
- **Mood Card 重构** — 从复杂嵌套变为简洁的 Health 风格可点击卡片 ✨ 改善
- **Body Phase 统一** — 11 阶段科学 + 陪伴语，hero 阶段名 + 折叠详情 ✨ 改善
- **3 色主题**（Green/Teal/Orange）克制统一
- **玻璃卡片** — `glassCard` 视觉层次分明
- **节假日断食建议** — 出色的差异化设计
- **Week Strip** — Apple Fitness 风格活动环

---

# Part 3: 优先级行动计划

## 🔴 第一梯队 — 发布前必修复

```
┌─────────────────────────────────────────────────────────┐
│  1. 修复 Model 层 3 处除零崩溃（Record/Plan/Profile）      │
│  2. 替换 fatalError 为优雅降级                             │
│  3. 心情滑块添加 VoiceOver 支持                            │
│  4. 本地化 4 个表盘的 "COMPLETED"/"LAST FAST"              │
│     + TimerView 的 "STARTED"/"GOAL"/"START"               │
│  5. 移除 weekStrip 无功能点击反馈                           │
│  6. startFasting 前确认是否取消现有断食                      │
│  7. SolarDial/PlateDial 浅色模式适配                       │
└─────────────────────────────────────────────────────────┘
```

## 🟡 第二梯队 — 下个迭代

```
┌─────────────────────────────────────────────────────────┐
│  8. 表盘切换添加可发现性（Settings 入口 + 首次 tip）        │
│  9. NoiseTexture Canvas 预渲染为 UIImage                  │
│ 10. DateFormatter 缓存为 static let（6 处）               │
│ 11. 统计算法从 O(n²) 优化到 O(n)                          │
│ 12. 数据持久化 try? 改为有日志的错误处理                    │
│ 13. Widget 进度环改为实时更新                               │
│ 14. SharedFastingData 抽取为 Shared Framework             │
│ 15. 首次使用时引导选择断食方案                              │
│ 16. Onboarding 禁用滑动跳步                               │
│ 17. 提取 4 个表盘共享的 centerContent 为公共组件            │
└─────────────────────────────────────────────────────────┘
```

## 🟢 第三梯队 — 长期改善

```
┌─────────────────────────────────────────────────────────┐
│ 18. 补充核心逻辑单元测试（目标覆盖率 60%+）                │
│ 19. 本地化系统迁移到标准 .strings 文件                     │
│ 20. @Observable singleton → Environment 注入              │
│ 21. 30fps Canvas 加视图可见性节流                          │
│ 22. resetPlan 添加二次确认                                │
│ 23. 农历缓存扩展或添加运行时 fallback                      │
│ 24. .repeatForever 动画改为 phaseAnimator                 │
│ 25. 清理死代码（planProgressSection 等）                   │
└─────────────────────────────────────────────────────────┘
```

---

## 修复进度追踪

| 原 P0 问题 | 状态 | 说明 |
|-----------|------|------|
| #1 除零崩溃 | ⚠️ 1/4 | TimerView ✅ / Record ❌ / Plan ❌ / Profile ❌ |
| #2 fatalError | ❌ | 未修复 |
| #3 持久化静默失败 | ❌ | 未修复 |
| #4 自动取消断食 | ❌ | 未修复 |
| #5 字符串越界 | ❌ | 未修复 |
| #6 枚举回退 | ❌ | 未修复 |

| 原 P1 问题 | 状态 | 说明 |
|-----------|------|------|
| #7 NoiseTexture | ❌ | 未修复 |
| #8 DateFormatter | ❌ | 未修复，新增 1 处 |
| #9 O(n²) 算法 | ❌ | 未修复 |
| #10 30fps Canvas | ❌ | 未修复 |
| #11 Singleton 架构 | ❌ | 未修复 |
| #12 本地化系统 | ❌ | 未修复 |
| #13 Widget 进度环 | ❌ | 未修复 |
| #14 SharedData 重复 | ❌ | 未修复 |

---

## 总结

**本轮改动的核心贡献**:
1. **4 种表盘风格** — 从单一进度环升级为 Simple/Clock/Plate/Solar 四选一，SolarDial 的光楔效果达到 ADA 视觉水准
2. **统一阶段模型** — 11 个科学阶段 + 陪伴语合并为一个清晰的数据源
3. **布局重构** — Action Button 内嵌、Mood 卡片简化、Tab 精简

**核心短板（与上次相同）**:
1. **健壮性** — 5 个 P0 崩溃/数据风险仍未修复
2. **本地化** — 硬编码英文随表盘增加反而扩散了
3. **性能** — 热路径的 DateFormatter/Canvas/O(n²) 依然存在
4. **无障碍** — VoiceOver 阻断性缺陷未动

**新引入的风险**:
- SolarDial 和 PlateDial 的浅色模式适配是发布前必须解决的视觉 bug
- 表盘切换的可发现性问题会导致这个精心设计的功能被浪费

**建议**: 在继续增加新功能（表盘、视觉效果）之前，优先处理 P0 健壮性问题和本地化。一个会崩溃的 App 再好看也没用。
