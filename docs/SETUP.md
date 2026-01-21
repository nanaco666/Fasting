# 项目配置指南

## 环境要求

- **macOS**: 14.5 或更高版本
- **Xcode**: 16.x 或更高版本
- **iOS SDK**: 17.0 或更高版本
- **Swift**: 5.9+

## 快速开始

### 1. 在 Xcode 中创建项目

由于 Swift 代码文件已准备好，你需要在 Xcode 中创建一个新的 iOS App 项目：

1. 打开 Xcode
2. 选择 **File > New > Project**
3. 选择 **iOS > App**
4. 配置项目：
   - **Product Name**: `Fasting`
   - **Team**: 选择你的开发者账号
   - **Organization Identifier**: 如 `com.yourname`
   - **Interface**: `SwiftUI`
   - **Storage**: `SwiftData`
   - **Language**: `Swift`
5. 选择保存位置：`/Users/huangxiaowen/Documents/我的项目/Fasting/`
6. 点击 **Create**

### 2. 导入现有代码

Xcode 创建项目后，将生成的默认文件替换为我们准备好的代码：

1. 在 Xcode 项目导航器中，删除自动生成的以下文件：
   - `ContentView.swift`
   - `FastingApp.swift` (如果有)
   - `Item.swift` (如果有)

2. 右键点击项目导航器中的 `Fasting` 文件夹，选择 **Add Files to "Fasting"**

3. 添加以下目录及其内容：
   - `Fasting/App/`
   - `Fasting/Core/`
   - `Fasting/Features/`
   - `Fasting/UI/`

4. 确保勾选 **Copy items if needed** 和 **Create groups**

### 3. 配置项目设置

#### Info.plist 配置

如果需要 HealthKit，添加以下权限描述：

```xml
<key>NSHealthShareUsageDescription</key>
<string>我们需要访问您的健康数据来同步断食记录</string>
<key>NSHealthUpdateUsageDescription</key>
<string>我们需要写入健康数据来记录您的断食信息</string>
```

#### Capabilities

在项目设置中启用以下功能：

1. **iCloud**
   - 勾选 CloudKit
   - 添加 CloudKit Container (如 `iCloud.com.yourname.Fasting`)

2. **HealthKit** (可选)
   - 勾选 HealthKit

3. **Push Notifications** (用于通知)
   - 勾选 Push Notifications

4. **Background Modes** (可选)
   - 勾选 Background fetch
   - 勾选 Remote notifications

### 4. 运行项目

1. 选择目标设备 (模拟器或真机)
2. 按 `Cmd + R` 运行

---

## XcodeBuildMCP 配置

XcodeBuildMCP 是一个 MCP 服务器，可以让 AI 助手直接与 Xcode 交互。

### 安装方式

在终端中运行以下命令进行交互式安装：

```bash
npx -y @smithery/cli@latest install cameroncooke/xcodebuildmcp --client cursor
```

安装过程中会提示是否发送匿名数据，选择 `Y` 或 `N`。

### 手动配置 (如果自动安装失败)

1. 打开 Cursor 设置
2. 进入 **Features > MCP**
3. 添加新的 MCP 服务器配置：

```json
{
  "mcpServers": {
    "xcodebuild": {
      "command": "npx",
      "args": ["-y", "@anthropic/xcodebuildmcp@latest"]
    }
  }
}
```

或者使用本地 npm 安装：

```bash
npm install -g @anthropic/xcodebuildmcp
```

然后配置：

```json
{
  "mcpServers": {
    "xcodebuild": {
      "command": "xcodebuildmcp"
    }
  }
}
```

### 验证安装

安装完成后，重启 Cursor，你应该能够使用以下 MCP 工具：

- `xcode_build`: 构建 Xcode 项目
- `xcode_test`: 运行测试
- `xcode_clean`: 清理构建
- `xcode_simulator_list`: 列出模拟器
- `xcode_simulator_boot`: 启动模拟器
- 等等

---

## 可用的 iOS 模拟器

你的系统已安装以下模拟器：

### iOS 18.2
- iPhone 16 Pro
- iPhone 16 Pro Max
- iPhone 16
- iPhone 16 Plus
- iPhone SE (3rd generation)
- iPad Pro 11-inch (M4)
- iPad Pro 13-inch (M4)

### iOS 17.0
- iPhone 15 Pro
- iPhone 15 Pro Max
- iPhone 15
- iPhone 15 Plus
- iPhone SE (3rd generation)
- iPad Pro (11-inch) (4th generation)
- iPad Pro (12.9-inch) (6th generation)
- iPad (10th generation)
- iPad Air (5th generation)
- iPad mini (6th generation)

推荐使用 **iPhone 16 Pro** (iOS 18.2) 进行开发测试。

---

## 常见问题

### Q: SwiftData 模型报错？

确保 `FastingRecord` 和 `UserSettings` 类都标记了 `@Model`，且所有属性都是可持久化的类型。

### Q: CloudKit 同步不工作？

1. 确保已登录 iCloud 账号
2. 确保项目已正确配置 CloudKit Container
3. 检查 Xcode Console 中的 CloudKit 相关日志

### Q: 模拟器无法启动？

```bash
# 重置模拟器
xcrun simctl shutdown all
xcrun simctl erase all
```

### Q: 构建失败，找不到模块？

确保所有 Swift 文件都被正确添加到项目的 Target 中。在 Xcode 中：
1. 选择文件
2. 在右侧 File Inspector 中
3. 确保 Target Membership 中勾选了 `Fasting`

---

## 下一步

项目配置完成后，你可以：

1. 运行应用，测试基本功能
2. 根据需要调整 UI 设计
3. 实现剩余的功能（通知、HealthKit 等）
4. 添加 Widget 和 Apple Watch 支持
