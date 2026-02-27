# Fasting App — 全面代码审查与 UAT 报告

**日期**: 2026-02-27 (Rev.3)
**审查范围**: 全部 45+ 个 Swift 源文件 + Widget Extension + 测试文件
**审查视角**: 顶级程序员（代码质量） + 顶级设计师（用户验收测试）
**自 Rev.2 以来**: +34 commits，新增 Buchinger 身心福祉量表、CalendarService 智能调度、7 步引导流、MoodRecord 扩展、Settings 重构、StatisticsView 删除

---

## 综合评分

```
                      Rev.1    Rev.2    Rev.3    变化
程序员视角:            72       74       76       +2  ▲
设计师视角:            78       81       82       +1  ▲
```

| 维度 | R1 | R2 | R3 | 变化 | 说明 |
|------|----|----|-----|------|------|
| 架构设计 | 7 | 7.5 | 8 | ▲ | CalendarService 智能调度、7 步引导、死代码清理 |
| 代码质量 | 6 | 6.5 | 7 | ▲ | 大量 bug fix，CompanionEngine 增强，但引入新风险 |
| 性能 | 5 | 5 | 5 | — | DateFormatter/O(n²) 未变，新增 EventKit 主线程 I/O |
| 健壮性 | 5 | 5.5 | 6 | ▲ | Timer 3 个 bug 修复，但 Onboarding 安全检查可被绕过 |
| 可测试性 | 3 | 3 | 3 | — | 依然零测试覆盖 |
| 本地化 | 6 | 5.5 | 6.5 | ▲ | 新增 65+ 本地化字符串，但 Widget 仍全英文 |
| 可维护性 | 7 | 7 | 7 | — | 删除了 StatisticsView 死代码，但 MoodCheckInView 膨胀到 625 行 |
| Apple 生态 | 9 | 9 | 9.5 | ▲ | 新增 EventKit 智能调度 |
| 视觉一致性 | 8 | 9 | 9 | — | 3 色主题 + SF Symbols 纯文字，无 emoji |
| 信息层级 | 8 | 8.5 | 8.5 | — | 不变 |
| 交互设计 | 7 | 7.5 | 8 | ▲ | Buchinger 身心量表 + 周日程可视化 |
| 无障碍 | 4 | 4 | 4 | — | 核心滑块仍不可访问 |

---

## 本次变更概览

### ✅ 已修复
| 原问题 | 修复情况 |
|--------|---------|
| StatisticsView 死代码 | **✅ 已删除** — `4973437` 彻底移除了文件 |
| Timer 结束后不重置 | **✅ 已修复** — `30679b9` 修复 timer reset on end |
| Widget 数据陈旧 | **✅ 已修复** — `30679b9` 修复 widget stale data |
| Body Journey 不实时更新 | **✅ 已修复** — `30679b9` Body Journey live update |
| Tab tint 污染全局 | **✅ 已修复** — `d184535` 绿色 tint 只作用于 TabBar |
| Settings 风格不统一 | **✅ 已修复** — `ac73b51` 回归系统原生风格 |
| Widget Timeline 空白期 | **✅ 不存在** — 60 entries + 30min reload，无 gap |
| Body Journey emoji | **✅ 已移除** — 改为纯 SF Symbols + 文字层级 |

### 🆕 新增功能
| 功能 | 文件 | 说明 |
|------|------|------|
| Buchinger 身心福祉量表 | MoodCheckInView.swift (重写) | PWB/EWB 0-10 双轴、酮体追踪、Companion 即时指导 |
| CalendarService 智能调度 | CalendarService.swift (新) | EventKit 集成、社交事件检测、自动降级/升级方案 |
| 7 步引导流 | OnboardingFlow.swift (扩展) | 新增健康、情绪、日历步骤 |
| 周日程可视化 | WeekScheduleView.swift (新) | 基于日历数据的每周断食安排展示 |
| UserProfile 健康扩展 | UserProfile.swift | 健康状况、压力、睡眠字段 |
| PlanCalculator 安全增强 | PlanCalculator.swift | 安全检查 + 压力/睡眠自适应 |
| 65+ 新本地化字符串 | Strings.swift | 覆盖新功能的中英文翻译 |
| Light/Dark 模式切换 | SettingsView.swift | 用户可手动选择外观 |

### 🆕 新引入问题
| 问题 | 严重度 | 位置 |
|------|--------|------|
| Onboarding TabView 手势可绕过安全检查 | **P0** | OnboardingFlow.swift:62 |
| CalendarService `.writeOnly` 误判为可读 | **P0** | CalendarService.swift:102 |
| MoodCheckInView 自定义 Slider 不可访问 | P1 | MoodCheckInView.swift:247 |
| EventKit 同步 I/O 在主线程 | P1 | CalendarService.swift:138, OnboardingFlow.swift:659 |
| MoodRecord 无 Schema 版本控制 | P2 | MoodRecord.swift:241 |
| Model 层导入 SwiftUI | P2 | MoodRecord.swift:8 |
| 启动即弹通知权限 | P2 | FastingApp.swift:39 |
| PlanCalculator 最低热量不分性别 | P2 | PlanCalculator.swift:66 |
| WeekScheduleView @StateObject + Singleton | P2 | WeekScheduleView.swift:12 |

---

# Part 1: 程序员视角 — 代码审查

---

## 🔴 P0 — 必须立即修复

### 1. 🆕 Onboarding TabView 手势绕过安全检查

**OnboardingFlow.swift:62-72** — 安全攸关的严重 Bug

```swift
TabView(selection: $step) {
    bodyInfoStep.tag(0)
    healthStep.tag(1)      // ← 健康状况筛查（饮食障碍、怀孕等）
    activityStep.tag(2)
    moodStep.tag(3)
    goalStep.tag(4)
    calendarStep.tag(5)
    summaryStep.tag(6)
}
.tabViewStyle(.page(indexDisplayMode: .never))
```

`.page` 样式的 TabView 允许用户左右滑动到任意步骤。`advanceStep()` 中的安全检查（`safetyCheck`，拦截饮食障碍/怀孕/严重健康问题用户）**完全可被滑动绕过**。一个有禁忌症的用户可以直接滑到 summary 创建断食计划。

**修复**: 添加 `.scrollDisabled(true)` 或改用自定义 page 容器。

---

### 2. 🆕 CalendarService `.writeOnly` 误判为已授权

**CalendarService.swift:101-103**

```swift
var isAuthorized: Bool {
    authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
}
```

`.writeOnly` 只能写入日历、**不能读取事件**。用此状态调用 `store.events(matching:)` 会返回空结果或异常。智能调度依赖事件读取，授权判断错误会导致整个调度引擎失效。

**修复**: 只检查 `.fullAccess`。对 iOS 16 还需兼容 `.authorized`。

---

### 3. 除零崩溃（Model 层 3 处） ❌ 未修复

`FastingRecord.progress`、`FastingPlan.progress`、`UserProfile.bmi` — 仍无 guard。

---

### 4. App 入口 fatalError ❌ 未修复

**FastingApp.swift:32** — 特别危险：MoodRecord schema 变更后，如果轻量级迁移失败，直接崩溃。

---

### 5. 数据持久化静默失败 ❌ 未修复

### 6. 自动取消前一个断食无用户确认 ❌ 未修复

### 7. FastingPlan 字符串分割越界崩溃 ❌ 未修复

---

## 🟡 P1 — 高优先级

### 8. 🆕 EventKit 同步 I/O 在主线程

**CalendarService.swift:137-138 + OnboardingFlow.swift:648-663**

```swift
// @MainActor class 中同步执行 I/O
let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)
let ekEvents = store.events(matching: predicate)  // 同步阻塞
```

日历事件多的用户（工作日历同步）会明显卡顿。`generateWeekSchedule` 对 7 天逐日查询 = 7 次同步 I/O。

**修复**: 移到 `Task.detached` 或 background actor。

---

### 9. 🆕 CalendarService 跨午夜事件计算错误

**CalendarService.swift:186-189**

```swift
let earliest = mealEvents.map(\.startHour).min() ?? 12
let latestEnd = mealEvents.map(\.endHour).max() ?? 20
```

只用 `.hour` 分量。晚餐 22:00-01:00 的 `endHour` = 1，小于 `earliest`，eating window 计算错误。

---

### 10. SolarDialView / PlateDialView 浅色模式失效 ❌ 未修复

### 11. 硬编码英文扩散到 4 个表盘 ❌ 未修复

### 12. 长按切换表盘零可发现性 ❌ 未修复

### 13. NoiseTexture Canvas 性能 ❌ 未修复

### 14. DateFormatter 在 body 路径中创建 ❌ 未修复

现在总计 **8 处**：TimerView 3 处 + HistoryView 5 处 + PlanWeekTimeline 1 处。

### 15. O(n²) / O(n×days) 统计算法 ❌ 未修复

`dayProgress()` O(days × records)、`currentStreak` O(streak × records) 在 HistoryView 中仍然存在。

### 16. @Observable Singleton 架构缺陷 ❌ 未修复

### 17. 本地化系统架构性问题 ❌ 未修复

Strings.swift 现已 1043 行，450+ key。Widget target 完全无法访问。

### 18. Widget 硬编码英文 ❌ 未修复

"Remaining"、"Done ✅"、"Not Fasting"、"Tap to start"、"Fasting Timer" 等全部未本地化。

### 19. SharedFastingData 代码重复 ❌ 未修复

Widget 版注释明确写着 "duplicated, keep in sync"。

---

## 🟢 P2 — 中优先级

| # | 问题 | 位置 | 状态 |
|---|------|------|------|
| 20 | 🆕 MoodRecord 无 `VersionedSchema`/`SchemaMigrationPlan` | MoodRecord.swift | 🆕 |
| 21 | 🆕 MoodRecord Model 层导入 SwiftUI（`KetoneLevel.color`） | MoodRecord.swift:8 | 🆕 |
| 22 | 🆕 启动即弹通知权限（用户还不了解 App） | FastingApp.swift:39 | 🆕 |
| 23 | 🆕 PlanCalculator 最低 1200kcal 不分性别（男性偏低） | PlanCalculator.swift:66 | 🆕 |
| 24 | 🆕 老年人蛋白质下限 `max(base, 1.2)` 无效 | PlanCalculator.swift:154 | 🆕 |
| 25 | 🆕 Milestone 标题硬编码英文（description 用了 key） | PlanCalculator.swift:204 | 🆕 |
| 26 | 🆕 WeekScheduleView `@StateObject` + `.shared` 语义冲突 | WeekScheduleView.swift:12 | 🆕 |
| 27 | 🆕 WeekScheduleView 空数据 = 永旋 ProgressView | WeekScheduleView.swift:30 | 🆕 |
| 28 | 🆕 DaySchedule `id = UUID()` 每次重建 | CalendarService.swift | 🆕 |
| 29 | 🆕 PWB/EWB slider 内部 0.5 精度但 UI 只显示整数 | MoodCheckInView.swift:270 | 🆕 |
| 30 | 🆕 `UITabBar.appearance()` 全局副作用 | FastingApp.swift:83 | 🆕 |
| 31 | 🆕 Preview modelContainer 缺 MoodRecord | FastingApp.swift:103 | 🆕 |
| 32 | 🆕 `.onChange(of: isGoalAchieved)` 在 TimelineView 内部 | TimerView.swift:262 | 🆕 |
| 33 | `FlowLayout` 未使用 cache | FlowLayout.swift | ❌ |
| 34 | HealthKit `isAuthorized` 不反映真实状态 | HealthKitService.swift | ❌ |
| 35 | 6 个 Bool `@State` 控制 sheet | TimerView.swift | ❌ |
| 36 | 版本号硬编码 `"1.2.0"` | SettingsView.swift | ❌ |
| 37 | `CompanionEngine.symptomAdvice` 仍有 `symptoms.first!` | CompanionEngine.swift:152 | ❌ |
| 38 | 农历缓存仅覆盖 2025-2027 | HolidayService.swift | ❌ |
| 39 | 测试覆盖率为零 | FastingTests.swift | ❌ |
| 40 | `.repeatForever` 动画叠加（3 个表盘） | Plate/Solar/WatchDialView | ❌ |
| 41 | `resetPlan()` 无二次确认 | PlanView.swift:490 | ❌ |
| 42 | `print` 调试日志 | PlanView.swift:343 | ❌ |

---

## ✅ 代码亮点

**新增亮点 ✨:**
- **Buchinger 身心福祉量表** — PWB/EWB 双轴评估 + 酮体追踪 + 即时 Companion 指导，科学方法论支撑
- **CalendarService 智能调度** — 社交事件检测、连续社交天数降级、周末升级、健康限制联动，逻辑设计精妙
- **PlanCalculator 安全增强** — 饮食障碍/怀孕/医疗状况筛查 + 压力/睡眠自适应调节
- **CompanionEngine 分层反馈** — 核心 → 饥饿 → 酮体 → 症状 → 正面强化 → 安全兜底，6 层指导体系
- **Timer 3 bug 一次性修复** — 结束重置、Widget 刷新、Body Journey 实时更新
- **StatisticsView 死代码清理** — 正确的减法

**延续的亮点:**
- 零第三方依赖，全系统框架
- 4 种表盘风格 (Simple/Clock/Plate/Solar)
- 统一 11 阶段模型（科学 + 陪伴合并）
- HolidayService 节假日断食建议
- SwiftData + CloudKit 自动同步
- Widget 全覆盖 (Small/Medium/Lockscreen)

---

# Part 2: 设计师视角 — 用户验收测试 (UAT)

---

## 🔴 Critical — 阻断性问题

### C1: 自定义 Slider 不可访问 ❌ 未修复，范围扩大

现在有 **3 个**自定义 Slider（PWB、EWB、旧 mood slider），全部缺少 VoiceOver 支持。Buchinger 量表的核心输入完全不可访问。

---

### C2: 核心 UI 文案硬编码英文 ⚠️ 部分改善

新增 65+ 本地化字符串 ✅，但：
- 4 个表盘的 "COMPLETED"/"LAST FAST" 仍未修复
- TimerView "STARTED"/"GOAL"/"START" 仍未修复
- Widget 全部英文
- `UserProfile.bmiCategory` 硬编码
- PlanCalculator Milestone 标题硬编码

---

### C3: weekStrip 点击有触觉反馈但无功能 ❌ 未修复

---

### C4: SolarDial/PlateDial 浅色模式失效 ❌ 未修复

---

### 🆕 C5: Onboarding 安全检查可被滑动绕过

有禁忌症（饮食障碍、怀孕）的用户可以滑过 healthStep 直接到 summary，创建可能危害健康的断食计划。这是**用户安全问题**，比 UI bug 更严重。

---

## 🟡 Major — 高优先级

### M1: 空闲状态"开始"按钮直接启动 ❌ 未修复

### M2: 结束断食 → 复食指南时序问题 ❌ 未修复

### M3: Settings 页 iCloud 同步状态造假 ❌ 未修复

### M4: `resetPlan()` 一键删除无二次确认 ❌ 未修复

### 🆕 M5: Buchinger Check-in 无取消确认

用户在 3 个 slider 上仔细调整了 PWB/EWB/hunger 数值后，点 X dismiss → 所有输入直接丢失，无确认对话框。

### 🆕 M6: 通知权限在启动时立即请求

用户还没理解 App 是做什么的就被要求授权通知，大概率拒绝。应在用户首次开始断食时再请求。

---

## 🟢 Minor — 可后续优化

| # | 问题 | 状态 |
|---|------|------|
| m1 | Timer 页信息密度偏高 | ❌ |
| m2 | `.repeatForever` 动画叠加 | ❌ |
| m3 | 月导航按钮无 VoiceOver 标签 | ❌ |
| m4 | Picker 空标签 | ❌ |
| m5 | Widget "Done ✅" 用 emoji | ❌ |
| m6 | 4 表盘 centerContent 重复代码 | ❌ |
| m7 | 🆕 BodyJourneyView "h" 时间单位硬编码 | 🆕 |
| m8 | 🆕 HistoryView 时间格式不尊重 12h 偏好 | 🆕 |
| m9 | 🆕 MoodCheckInView 625 行，信息密度很高（可考虑分步引导） | 🆕 |

---

## ✅ 设计亮点

- **Buchinger 量表** — 基于医学文献的科学评估方法，PWB+EWB 双轴 + 酮体追踪，远超同类 App 的 emoji 打卡 ✨ 新增
- **环境色随状态变化** — `ambientColor` 根据身心状态实时变化，提供直觉反馈 ✨ 新增
- **CompanionEngine 安全兜底** — PWB/EWB ≤2 → critical 提醒，危险症状组合 → stop 建议 ✨ 新增
- **周日程可视化** — 基于真实日历数据展示每日建议方案，实用性很强 ✨ 新增
- **Settings 回归原生** — 标准 List + Section 布局，Light/Dark 切换控件 ✨ 改善
- **纯 SF Symbols 无 emoji** — 卡片 header 统一为 icon + text 层级 ✨ 改善
- **4 种表盘风格** — Simple/Clock/Plate/Solar
- **SolarDialView** — 多层 Canvas 光楔效果
- **3 色主题** (Green/Teal/Orange)
- **节假日断食建议**

---

# Part 3: 优先级行动计划

## 🔴 第一梯队 — 发布前必修复

```
┌───────────────────────────────────────────────────────────┐
│  1. Onboarding 禁用滑动 (.scrollDisabled) — 安全攸关       │
│  2. CalendarService 只检查 .fullAccess — 授权逻辑错误       │
│  3. 修复 Model 层 3 处除零崩溃                              │
│  4. 替换 fatalError 为优雅降级（特别是 MoodRecord 迁移后）   │
│  5. 自定义 Slider 添加 VoiceOver（PWB/EWB/mood）            │
│  6. 本地化 4 个表盘 + TimerView 的硬编码英文                 │
│  7. SolarDial/PlateDial 浅色模式适配                        │
│  8. 移除 weekStrip 无功能点击反馈                            │
└───────────────────────────────────────────────────────────┘
```

## 🟡 第二梯队 — 下个迭代

```
┌───────────────────────────────────────────────────────────┐
│  9. EventKit I/O 移到后台线程                               │
│ 10. DateFormatter 缓存为 static let（8 处）                 │
│ 11. 统计算法优化（dayProgress/currentStreak 预处理字典）     │
│ 12. 通知权限延迟到首次断食时请求                             │
│ 13. Widget 字符串本地化（需跨 target 共享 Strings）          │
│ 14. SharedFastingData 抽取为 Shared Framework               │
│ 15. 表盘切换添加可发现性（Settings 入口 + 首次 tip）         │
│ 16. startFasting 前确认是否取消现有断食                      │
│ 17. MoodRecord 添加 VersionedSchema 迁移计划                │
│ 18. 提取 4 个表盘共享的 centerContent 为公共组件             │
└───────────────────────────────────────────────────────────┘
```

## 🟢 第三梯队 — 长期改善

```
┌───────────────────────────────────────────────────────────┐
│ 19. 补充核心逻辑单元测试（目标覆盖率 60%+）                 │
│ 20. 本地化系统迁移到标准 .strings 文件                      │
│ 21. @Observable singleton → Environment 注入               │
│ 22. 30fps Canvas 加视图可见性节流                           │
│ 23. CalendarService 修复跨午夜事件计算                      │
│ 24. PlanCalculator 最低热量按性别区分                       │
│ 25. Model 层颜色映射移到 View extension（去除 SwiftUI 导入）│
│ 26. .repeatForever 动画改为 phaseAnimator                  │
│ 27. resetPlan 添加二次确认                                 │
│ 28. 清理死代码（planProgressSection、Widget liveXxx 属性）  │
└───────────────────────────────────────────────────────────┘
```

---

## 修复进度追踪

### P0 问题

| # | 问题 | R1 | R2 | R3 |
|---|------|----|----|-----|
| 1 | 除零崩溃 (Model 层) | ❌ | ⚠️ 1/4 | ⚠️ 1/4 |
| 2 | fatalError | ❌ | ❌ | ❌ |
| 3 | 持久化静默失败 | ❌ | ❌ | ❌ |
| 4 | 自动取消断食 | ❌ | ❌ | ❌ |
| 5 | 字符串越界 | ❌ | ❌ | ❌ |
| 6 | 枚举回退 | ❌ | ❌ | ❌ |
| 7 | 🆕 Onboarding 安全绕过 | — | — | ❌ |
| 8 | 🆕 CalendarService 授权错误 | — | — | ❌ |

### P1 问题

| # | 问题 | R1 | R2 | R3 |
|---|------|----|----|-----|
| 9 | Solar/Plate 浅色模式 | — | ❌ | ❌ |
| 10 | 硬编码英文 (表盘+Timer) | ❌ | ❌ | ❌ |
| 11 | 表盘切换可发现性 | — | ❌ | ❌ |
| 12 | NoiseTexture Canvas | ❌ | ❌ | ❌ |
| 13 | DateFormatter 热路径 | ❌ | ❌ | ❌ (8处) |
| 14 | O(n²) 统计 | ❌ | ❌ | ❌ |
| 15 | Singleton 架构 | ❌ | ❌ | ❌ |
| 16 | 本地化架构 | ❌ | ❌ | ❌ (1043行) |
| 17 | Widget 英文 | ❌ | ❌ | ❌ |
| 18 | SharedData 重复 | ❌ | ❌ | ❌ |
| 19 | 🆕 EventKit 主线程 I/O | — | — | ❌ |
| 20 | 🆕 跨午夜事件计算错误 | — | — | ❌ |

### 已修复 ✅

| 问题 | 修复时间 |
|------|---------|
| StatisticsView 死代码 | R3 (`4973437`) |
| Timer 结束不重置 | R3 (`30679b9`) |
| Widget 数据陈旧 | R3 (`30679b9`) |
| Body Journey 不实时更新 | R3 (`30679b9`) |
| Tab tint 全局污染 | R3 (`d184535`) |
| Settings 风格不统一 | R3 (`ac73b51`) |
| TimerView.progress 除零 | R2 |
| CompanionEngine phaseMessage 简化 | R2 |
| 4th Tab 架构混乱 | R2 |
| Phase 模型碎片化 | R2 |
| ActionButton 游离 | R2 |

---

## 总结

**本轮核心贡献**:
1. **Buchinger 身心福祉量表** — 从简单 emoji 升级为医学量表级评估，App 的科学性上了一个台阶
2. **CalendarService 智能调度** — 基于真实日历数据自动调整断食方案，是同类 App 的差异化杀手锏
3. **PlanCalculator 安全增强** — 健康筛查 + 压力/睡眠自适应，体现了对用户安全的重视
4. **一批关键 bug 修复** — Timer/Widget/Body Journey 三连修，用户体验明显改善
5. **死代码清理** — StatisticsView 删除是正确的减法

**最紧迫的 2 个问题**:
1. **Onboarding 安全检查可被滑动绕过** — 这是用户健康安全问题，不是 UI 打磨，必须第一时间修
2. **CalendarService 授权逻辑错误** — `.writeOnly` ≠ 可读取，智能调度引擎在此授权下完全失效

**总体趋势**: 功能在快速生长，但基础设施（健壮性、性能、无障碍、本地化）的技术债在持续累积。建议暂停新功能开发 1-2 个迭代，集中偿还 P0/P1 技术债。一个会在 Onboarding 安全检查上留下漏洞的 App，再多的 Buchinger 量表也无法弥补。
