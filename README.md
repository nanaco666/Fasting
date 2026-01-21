# Fasting - iOS 原生间歇性断食应用

一个简洁优雅的间歇性断食追踪应用，采用 Apple 原生设计语言，与 Health/Fitness 应用视觉风格一致。

## 项目愿景

打造一个**极简、专注、原生**的断食追踪工具：
- 🎯 **专注核心**：只做断食计时和记录，不做功能堆砌
- 🍎 **原生设计**：完全遵循 Apple Human Interface Guidelines，使用 Liquid Glass 设计语言
- ⚡ **轻量快速**：启动即用，零学习成本
- 🔒 **隐私优先**：所有数据本地存储 + iCloud 同步，不收集用户数据

## 对标分析：Zero vs Fasting

| 特性 | Zero | Fasting (我们) |
|------|------|----------------|
| 核心功能 | 断食计时 + 大量附加功能 | 专注断食计时记录 |
| 设计风格 | 自定义暖色调 UI | Apple 原生 Liquid Glass |
| 订阅模式 | 大量功能锁在付费墙后 | 核心功能完全免费 |
| 数据同步 | 云端账号系统 | 纯 iCloud 同步，无需注册 |
| 应用体积 | ~100MB | 目标 < 20MB |
| 启动速度 | 中等 | 瞬间启动 |

## 我们的突破点

### 1. 真正的 Apple 原生体验
- 使用 iOS 26 Liquid Glass 设计语言
- 与 Health/Fitness 应用视觉完全一致
- 支持 Dynamic Island、Live Activities
- 深度 Apple Watch 集成

### 2. 极致简约
- 一键开始/结束断食
- 无需注册，打开即用
- 没有推销、没有广告、没有干扰

### 3. 智能但不打扰
- 基于使用习惯的智能提醒
- Widget 一眼看进度
- Siri 语音控制

### 4. 数据可视化
- 使用 Swift Charts 的精美图表
- 与 Apple Health 深度集成
- 直观的日历视图

## 技术栈

- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI (iOS 17+)
- **数据持久化**: SwiftData + CloudKit
- **图表**: Swift Charts
- **架构**: MVVM + Clean Architecture
- **最低支持**: iOS 17.0

## 快速开始

```bash
# 克隆项目
git clone <repo-url>
cd Fasting

# 用 Xcode 打开项目
open Fasting.xcodeproj
```

## 项目结构

```
Fasting/
├── App/                    # 应用入口
├── Features/               # 功能模块
│   ├── Timer/             # 断食计时器
│   ├── History/           # 历史记录
│   ├── Statistics/        # 统计数据
│   └── Settings/          # 设置
├── Core/                   # 核心模块
│   ├── Models/            # 数据模型
│   ├── Services/          # 服务层
│   └── Extensions/        # 扩展
├── UI/                     # UI 组件
│   ├── Components/        # 可复用组件
│   └── Theme/             # 主题配置
├── Resources/              # 资源文件
└── Tests/                  # 测试
```

## 开发路线图

### MVP (v1.0) - 核心功能
- [ ] 断食计时器（开始/暂停/结束）
- [ ] 预设断食方案（16:8, 18:6, 20:4, OMAD）
- [ ] 自定义断食时长
- [ ] 断食历史记录
- [ ] 基础统计（连续天数、总时长）
- [ ] 本地数据持久化

### v1.1 - 增强体验
- [ ] Widget 支持
- [ ] Apple Watch 应用
- [ ] iCloud 同步
- [ ] Apple Health 集成

### v1.2 - 智能功能
- [ ] 智能提醒
- [ ] Live Activities
- [ ] Siri Shortcuts
- [ ] 高级统计图表

## 设计规范

遵循 Apple Human Interface Guidelines，使用系统颜色和组件：

- **主色调**: 系统蓝色 (`.blue`)
- **强调色**: 系统绿色 (`.green`) 用于断食进行中
- **字体**: SF Pro (系统默认)
- **图标**: SF Symbols
- **材质**: Liquid Glass (iOS 26+)

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
