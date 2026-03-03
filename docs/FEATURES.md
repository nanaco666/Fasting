# 功能规格文档

> 对齐实际代码状态。虚线框 = 计划中未实现。

---

## Tab 结构

```
Tab 0: Timer (断食计时器)
Tab 1: Plan (计划 + 营养 + 日历 + 健身)
```

---

## 1. 认证 (Auth)

**入口**：App 启动 gate — 未登录时显示 AuthView

**功能**：
- Apple Sign In（ASAuthorizationController）
- Keychain credential 持久化
- `AuthService.isSignedIn` 控制 app 可见性

**状态**：✅ UI 和逻辑已完成，Developer 账号未激活，Sign in with Apple capability 待配置

---

## 2. 断食计时器 (Timer) — Tab 0

### 2.1 计时器卡片

主页面 hero 元素。包含：

- **餐盘 + Dial**：主题餐盘图片叠加可切换的 dial 样式
- **时间信息 pills**：STARTED / GOAL，可点击编辑
- **动作按钮**：Start（绿色渐变）/ Stop（灰色低调）

**Dial 样式**（长按切换，`@AppStorage("timerDialStyle")` 持久化）：

| 样式 | 描述 |
|------|------|
| Simple | 简约进度环 + 大字居中 |
| Clock | 手表风格，带 hour ticks 和渐变弧 |
| Plate | 餐盘扇形填充，hour marks |
| Solar | 日晷风格，光楔效果（暗色专属） |

所有 dial 颜色跟随 `ThemeManager.shared.currentTheme.progressColor`。

### 2.2 身心签到卡片 (Mood Card)

断食中显示。点击打开 `MoodCheckInView`。

**基于布辛格断食监测量表**：
- 情绪 (Mood)：emoji 选择
- 能量 (Energy)：0-10 NRS
- 饥饿 (Hunger)：0-10 NRS
- 体感 (Physical)：症状标签多选

数据存储为 `MoodRecord` (@Model)。

### 2.3 身体旅程卡片 (Body Phase Card)

断食中显示，可展开/折叠。

- **折叠**：当前阶段名 + 陪伴消息 + 下一阶段倒计时
- **展开**：完整阶段时间线，自动滚动到当前阶段

阶段数据定义在 `FastingPhase.swift`（0-72h 代谢变化周期）。

### 2.4 空闲状态卡片 (Body Journey Idle)

非断食时显示，替代 mood + body phase 卡片。

### 2.5 复食指南 (Refeed Guide)

断食结束后自动弹出 sheet：
- 根据断食时长推荐复食方案
- 渐进式恢复建议（流质 → 轻食 → 正常）

### 2.6 快速主题切换

Toolbar 🎨 按钮 → compact sheet 横向滚动选择主题，选中即切换 + dismiss。

---

## 3. 计划系统 (Plan) — Tab 1

### 3.1 Onboarding 引导

首次使用 Plan 时弹出 `OnboardingFlow`：
- 收集用户参数（身高/体重/年龄/性别/活动量/目标）
- 存储为 `UserProfile` (@Model)
- `PlanCalculator` 生成个性化 `FastingPlan`

### 3.2 计划概览卡片

- 计划名称 + 每周目标减重
- 阶段进度条 + 里程碑节点（progressive disclosure）
- 周计划视图 (`WeekScheduleView`)

### 3.3 营养卡片

基于 DGA 2025-2030 + TDEE 动态计算：
- 每日热量目标
- 蛋白质目标
- 碳水:纤维比

**PlanCalculator 引擎**：
- BMR: Mifflin-St Jeor 公式
- TDEE: BMR × 活动系数
- DGA 食物份量按 TDEE 动态缩放

### 3.4 日历卡片

- EventKit 集成，读取用户日历事件
- 14 天事件预览
- 智能调度建议（有社交/餐饮事件时调整断食窗口）
- 节假日识别 (`HolidayService`)

### 3.5 活动卡片

- HealthKit 集成
- Active Calories / Steps / Workouts
- 当日运动数据汇总

### 3.6 健身建议卡片

- 根据断食状态生成运动建议
- 数据来源: `FitnessRecommendations.swift`
- 基于断食生理机制匹配运动类型

---

## 4. 历史记录 (History)

嵌入在 Plan tab 内（通过 NavigationLink 或 tab 内导航）。

- 日历视图展示断食完成情况
- 点击日期查看详情
- 月度统计汇总

---

## 5. 设置 (Settings)

从 Timer 页 toolbar ⚙️ 进入。

| 设置项 | 说明 |
|--------|------|
| 默认断食方案 | 选择空闲时的默认 preset |
| 表盘样式 | Simple / Clock / Plate / Solar |
| 主题 | 5 个内置主题 |
| 通知 | 断食完成/半程提醒 |
| 外观 | 跟随系统 / 浅色 / 深色 |
| 语言 | 英文 / 简体中文 |
| HealthKit | 连接/断开 |
| 日历 | 连接/断开 |

---

## 6. 主题系统

5 个内置主题，每个包含：桌布背景 + 餐盘图 + 食物插图 + 配色。

| 主题 | 进度色 | Premium |
|------|--------|---------|
| 极简 (Minimal) | Green | No |
| 格纹陶瓷 (Ceramic Plaid) | Green | No |
| 红陶木纹 (Terracotta Wood) | Orange | No |
| 大理石 (Ceramic Marble) | Teal | Yes |
| 木盘亚麻 (Wood Linen) | Green | Yes |

切换方式：
1. Toolbar 🎨 快速切换（`QuickThemePickerSheet`）
2. Settings → 主题设置

---

## 7. Widget

- **尺寸**：Small
- **内容**：当前断食状态、进度环、剩余时间
- **数据同步**：`SharedFastingData` via App Groups UserDefaults
- **主题**：跟随 app 主题 (`themeId`)

---

## 8. 陪伴系统 (Companion)

`CompanionEngine` 提供：
- 断食阶段感知的鼓励消息
- 身心福祉趋势分析
- 安全守护（长时间断食/异常体感预警）

---

## 9. 本地化

- 双语：English + 简体中文
- 内联字典方式 (`Strings.swift`)
- 130+ 翻译条目
- 运行时切换，无需重启 app

---

## 与 Zero 的差异化

### 我们做了
✅ 断食计时器（4 种 dial 样式）
✅ 个性化科学计划（DGA 2025-2030）
✅ 身心签到（布辛格量表）
✅ 复食指南
✅ 日历智能调度
✅ HealthKit 运动数据
✅ 主题系统（5 主题 + 快速切换）
✅ Widget
✅ 双语

### 我们不做
❌ 社区/挑战
❌ 付费订阅墙（核心功能免费）
❌ 水分追踪
❌ 教育文章/内容营销
❌ AI chatbot

### 差异化优势
⭐ 100% Apple 原生（零依赖）
⭐ 科学引擎驱动（DGA + 布辛格 + 代谢研究）
⭐ 主题化视觉体验（ADA 级设计）
⭐ 极致轻量 (< 20MB)
⭐ 零注册即用（Apple Sign In 可选）
