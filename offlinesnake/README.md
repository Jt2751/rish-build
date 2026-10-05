# 贪吃蛇（离线 iOS 小游戏）

一个使用 **SwiftUI** 编写的轻量单机贪吃蛇游戏。无网络请求、无第三方依赖；分数和个人最高分只保存在本机。

## 游戏内容

- 中文深色界面、单机计分与本机最高分
- 棋盘滑动或屏幕方向键控制；不能直接反向转弯
- 撞到边界或蛇身后结束，可立即重新开始
- 使用 iOS 原生 SwiftUI 绘制，不需要联网或下载游戏素材

## 用 Xcode 运行

1. 在装有 Xcode 14 或更新版本的 Mac 上解压项目。
2. 双击 `OfflineSnake.xcodeproj`。
3. 在 Xcode 顶部选择 `OfflineSnake` Scheme 和 iPhone 模拟器，按 **Run**。
4. 真机运行时，在 Target 的 **Signing & Capabilities** 中选择自己的 Apple 开发团队；如有需要，将 Bundle Identifier `com.cue.offlinesnake` 改成唯一值，然后连接 iPhone 并按 **Run**。

部署目标为 iOS 16.0。运行游戏本身不需要网络。

## IPA 与签名说明

本项目交付环境是 Linux，未安装 `xcodebuild`、Apple iOS SDK 或 Apple 代码签名工具，因此这里**没有构建或签名 IPA**，也没有可直接安装的 `.ipa` 文件。不能把未构建的工程称作 IPA。

要制作可安装包，请在 macOS 的 Xcode 中打开工程，配置自己的签名团队和有效的 provisioning profile，再选择 **Product → Archive → Distribute App**，按目标选择 Development、Ad Hoc 或 App Store Connect 导出。免费个人开发团队可用于在自己的设备上进行开发调试；Ad Hoc 分发或 App Store 发布则需要对应的 Apple 签名配置与资格。**无需向本项目提供 Apple 凭据。**

Bundle Identifier 当前为 `com.cue.offlinesnake`；若该标识不可用，请在 Xcode 中换成你自己的唯一标识。
