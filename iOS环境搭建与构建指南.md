# iOS 开发环境搭建与构建指南

本文档详细说明了如何搭建 Flutter iOS 开发环境，以及如何构建和发布 iOS 应用。鉴于您当前在 Windows 环境下开发，本指南重点说明如何迁移到 macOS 环境进行构建。

## 1. 核心前提 (必读)

> [!IMPORTANT]
> **必须使用 macOS 系统**
> iOS 应用的编译和打包必须依赖 **Xcode**，而 Xcode 仅运行于 macOS。
>
> * **推荐**: 使用 MacBook, Mac mini 或 iMac。
> * **替代**: 使用云构建服务 (Codemagic, GitHub Actions) 或 虚拟机 (VMware 黑苹果，性能较差)。

## 2. macOS 环境准备

如果你已经有一台 Mac 电脑（或配置好的虚拟机），请按以下步骤配置环境。

### 2.1 安装 Xcode

1. 打开 Mac 上的 **App Store**。
2. 搜索并下载 **Xcode** (通常需要 10GB+ 空间)。
3. 安装完成后，打开终端 (Terminal)，运行以下命令同意许可协议：

    ```bash
    sudo xcodebuild -license
    ```

    (按提示输入密码，然后输入 `agree`)
4. 配置命令行工具：

    ```bash
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    sudo xcodebuild -runFirstLaunch
    ```

### 2.2 安装 CocoaPods

CocoaPods 是 iOS 的依赖管理工具（类似 Flutter 的 pub）。
在终端运行：

```bash
sudo gem install cocoapods
```

### 2.3 安装 Flutter SDK (Mac 版)

1. 下载 [Flutter SDK for macOS](https://docs.flutter.dev/get-started/install/macos)。
2. 解压到某个目录 (例如 `~/development/flutter`)。
3. 配置环境变量 (添加到 `~/.zshrc` 或 `~/.bash_profile`)：

    ```bash
    export PATH="$PATH:$HOME/development/flutter/bin"
    ```

4. 运行 `source ~/.zshrc` 使配置生效。
5. 运行 `flutter doctor` 检查环境，确保 iOS 工具链 (Xcode) 打钩。

## 3. 项目迁移与构建 (从 Windows 到 Mac)

### 3.1 传输项目

将你在 Windows 上的工程文件夹完整复制到 Mac 上。

### 3.2 初始化依赖

在 Mac 的终端中进入项目根目录，执行：

```bash
# 1. 获取 Flutter 依赖
flutter pub get

# 2. 进入 iOS 目录安装原生依赖 (关键步骤)
cd ios
pod install
cd ..
```

> [!TIP]
> 如果 `pod install` 失败，通常是因为网络问题。可以尝试使用清华源或科学上网。

### 3.3 运行与调试

* **模拟器运行**:

    ```bash
    open -a Simulator
    flutter run
    ```

* **真机运行**:
    1. 用 USB 连接 iPhone 到 Mac。
    2. 在 Xcode 中打开 `ios/Runner.xcworkspace`。
    3. 配置签名 (Signing & Capabilities) -> 选择你的 Apple ID (Personal Team)。
    4. 在手机上信任开发者证书 (设置 -> 通用 -> VPN与设备管理)。
    5. 运行 `flutter run -d <device_id>`。

## 4. 打包发布 (IPA)

要生成用于上架 App Store 或测试的 `.ipa` 文件，你需要一个 **Apple Developer Program** 账号 ($99/年)。

1. **配置签名**: 在 Xcode 中配置好 Distribution 证书和 Provisioning Profile。
2. **执行构建**:

    ```bash
    flutter build ipa
    ```

3. 构建产物位于: `build/ios/archive/Runner.xcarchive` (随后可导出为 ipa)。

## 5. 常见问题 (FAQ)

### Q: 为什么 Windows 上没有 `pod` 命令？

**A**: `pod` 是 Ruby 编写的工具，主要用于管理 Xcode 项目依赖，深度依赖 macOS 系统组件，无法在 Windows 上运行。

### Q: 虚拟机 (VMware) 能用吗？

**A**: 能用，但有以下缺点：

* **卡顿**: 图形界面极其卡顿，模拟器几乎无法使用。
* **编译慢**: 首次编译可能需要半小时以上。
* **折腾**: 安装过程复杂 (Unlocker, 找镜像, 驱动问题)。
* **建议**: 仅用于最终打包，不建议用于日常开发调试。

### Q: 云构建 (Codemagic) 是什么？

**A**: 如果你不想买 Mac 也不想装虚拟机，可以使用 Codemagic。

1. 把代码传到 GitHub。
2. 在 Codemagic 网站关联项目。
3. 它会提供一台远程 Mac 帮你打包并生成 `.ipa` 下载链接。

## 6. 项目依赖与 SDK 说明

为了确保构建成功，请注意以下版本要求（已在 `pubspec.yaml` 中定义）：

### 6.1 核心环境

* **Dart SDK**: `^3.9.2` (请确保 Flutter SDK 包含此版本的 Dart)
* **Flutter SDK**: 建议使用最新稳定版 (Stable Channel)

### 6.2 关键第三方库 (已包含)

无需手动下载，运行 `flutter pub get` 会自动安装：

* `file_picker`: 文件选择 (需要相册权限)
* `sqflite`: 数据库支持
* `provider`: 状态管理
* `flutter_markdown`: Markdown 渲染
* `shared_preferences`: 本地存储

### 6.3 iOS 部署目标

虽然 `Podfile` 会在 Mac 上自动生成，但建议 iOS Deployment Target 设置为 **12.0** 或更高，以兼容大多数现代插件。
