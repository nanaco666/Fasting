# 设计规范文档

## 设计理念

### 核心原则
1. **原生优先**: 尽可能使用系统组件和设计语言
2. **内容至上**: UI 服务于内容，不喧宾夺主
3. **一致性**: 与 Apple Health/Fitness 视觉风格保持一致
4. **可访问性**: 支持 Dynamic Type、VoiceOver 等无障碍功能

### 设计灵感
- Apple Health 的卡片式布局
- Apple Fitness 的活动环设计
- iOS 26 Liquid Glass 材质效果

---

## 色彩系统

### 语义化颜色
使用系统语义化颜色，自动适配深色模式：

```swift
// 主要颜色
Color.primary          // 主要文本
Color.secondary        // 次要文本
Color.accentColor      // 强调色（默认蓝色）

// 背景颜色
Color(.systemBackground)           // 主背景
Color(.secondarySystemBackground)  // 次级背景（卡片）
Color(.tertiarySystemBackground)   // 三级背景

// 分组背景
Color(.systemGroupedBackground)
Color(.secondarySystemGroupedBackground)
```

### 功能性颜色
```swift
extension Color {
    // 断食状态颜色
    static let fastingActive = Color.green      // 断食进行中
    static let fastingIdle = Color.gray         // 空闲状态
    static let fastingCompleted = Color.blue    // 完成
    
    // 统计颜色
    static let streakFire = Color.orange        // 连续天数
    static let chartBar = Color.blue.opacity(0.8)
}
```

### 渐变色
用于进度环和特殊强调：
```swift
let fastingGradient = LinearGradient(
    colors: [.green, .blue],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## 字体系统

### 使用 SF Pro (系统默认)
```swift
// 标题
.font(.largeTitle)      // 34pt - 主要数字显示
.font(.title)           // 28pt - 页面标题
.font(.title2)          // 22pt - 节标题
.font(.title3)          // 20pt - 卡片标题

// 正文
.font(.headline)        // 17pt 加粗 - 强调内容
.font(.body)            // 17pt - 正文
.font(.callout)         // 16pt - 次要正文
.font(.subheadline)     // 15pt - 副标题
.font(.footnote)        // 13pt - 脚注
.font(.caption)         // 12pt - 说明文字
.font(.caption2)        // 11pt - 最小文字
```

### 数字显示专用
```swift
// 计时器大数字
Text("12:34:56")
    .font(.system(size: 56, weight: .light, design: .rounded))
    .monospacedDigit()  // 等宽数字，防止跳动

// 统计数字
Text("7")
    .font(.system(size: 48, weight: .bold, design: .rounded))
```

---

## 图标系统

### 使用 SF Symbols
```swift
// 导航图标
Image(systemName: "timer")              // 计时器
Image(systemName: "calendar")           // 历史
Image(systemName: "chart.bar.fill")     // 统计
Image(systemName: "gearshape.fill")     // 设置

// 状态图标
Image(systemName: "play.fill")          // 开始
Image(systemName: "stop.fill")          // 结束
Image(systemName: "checkmark.circle.fill")  // 完成

// 功能图标
Image(systemName: "flame.fill")         // 连续天数
Image(systemName: "clock.fill")         // 时长
Image(systemName: "bell.fill")          // 通知
```

### 图标变体
```swift
// 根据状态切换
Image(systemName: isFasting ? "stop.fill" : "play.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(isFasting ? .red : .green)
```

---

## 组件设计

### 1. 进度环 (Progress Ring)
Apple Fitness 风格的圆形进度指示器：

```swift
struct ProgressRing: View {
    let progress: Double  // 0.0 - 1.0
    let lineWidth: CGFloat = 20
    
    var body: some View {
        ZStack {
            // 背景环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // 进度环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.green, .blue, .green],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}
```

### 2. 统计卡片 (Stat Card)
Health 风格的信息卡片：

```swift
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

### 3. 主操作按钮 (Primary Button)
大号、突出的操作按钮：

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isDestructive ? Color.red : Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
```

---

## 布局规范

### 间距系统
```swift
// 使用系统标准间距
let spacing4: CGFloat = 4    // 最小间距
let spacing8: CGFloat = 8    // 小间距
let spacing12: CGFloat = 12  // 常规间距
let spacing16: CGFloat = 16  // 标准间距
let spacing20: CGFloat = 20  // 大间距
let spacing24: CGFloat = 24  // 更大间距
```

### 圆角规范
```swift
let cornerRadiusSmall: CGFloat = 8    // 小组件
let cornerRadiusMedium: CGFloat = 12  // 卡片
let cornerRadiusLarge: CGFloat = 16   // 大卡片
let cornerRadiusFull: CGFloat = 9999  // 胶囊形状
```

### 安全区域
```swift
// 始终尊重安全区域
.safeAreaInset(edge: .bottom) {
    // 底部操作按钮
}

// 使用 safeAreaPadding 而不是硬编码
.safeAreaPadding()
```

---

## 动画规范

### 标准动画
```swift
// 按钮反馈
.animation(.easeInOut(duration: 0.2), value: isPressed)

// 数值变化
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)

// 页面切换
.animation(.easeInOut(duration: 0.3), value: selectedTab)
```

### 微交互
```swift
// 按钮按下效果
.scaleEffect(isPressed ? 0.95 : 1.0)

// 完成震动反馈
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```

---

## 深色模式适配

### 自动适配
- 使用语义化颜色，自动适配深浅色
- 避免硬编码颜色值

### 测试清单
- [ ] 所有文本在两种模式下清晰可读
- [ ] 图标和图表颜色适配
- [ ] 分隔线和边框适配
- [ ] 渐变色适配

---

## 无障碍功能

### VoiceOver
```swift
Text("16:34:22")
    .accessibilityLabel("断食进行中，已断食16小时34分22秒")
```

### Dynamic Type
```swift
// 使用相对字体大小
.font(.body)

// 限制最大字体（如果需要）
.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
```

### 颜色对比
- 确保文字与背景对比度至少 4.5:1
- 不仅用颜色传达信息，配合图标或文字

---

## Liquid Glass (iOS 26+)

### 材质应用
```swift
// 导航栏和工具栏自动应用 Liquid Glass
// 自定义视图中谨慎使用

.background(.ultraThinMaterial)  // 轻度毛玻璃
.background(.thinMaterial)       // 标准毛玻璃
.background(.regularMaterial)    // 常规毛玻璃
```

### 最佳实践
- 不要过度使用半透明效果
- 确保内容在材质上仍可读
- 避免多层叠加材质
