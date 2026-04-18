# 长期记忆

## 用户信息
- GitHub 用户名：welsonslee2-netizen
- iOS 开发经验：无
- Mac：没有，只有 Windows PC
- 测试设备：iPhone（想免 $99/年测试）
- 仓库地址：https://github.com/welsonslee2-netizen/IOS-Agent

## 项目背景
打造一款 iOS AI Agent App：
- 能在 iPhone 上运行 Python 代码
- 能进行文件管理、网络请求等操作
- 通过 GitHub Actions 云端构建
- 通过 SideStore 免费安装到真机测试（无需付费 Apple Developer 账号）

## 技术栈（当前状态）

### ✅ 已废弃
- BeeWare / Briefcase：`briefcase create iOS` 在 CI 非交互环境下 exit code 100，原因是 briefcase 需要 Xcode GUI 会话

### ✅ 当前方案
- 原生 iOS 项目：Swift + UIKit
- 项目生成：XcodeGen（`xcodegen generate`）
- 构建：直接 `xcodebuild`（无需 briefcase）
- CI：GitHub Actions macOS runner
- 安装：SideStore（免费免签名）

### 项目文件结构
```
ios/
├── project.yml              # XcodeGen 配置
├── ExportOptions.plist      # IPA 导出配置
└── iosagent/
    ├── Info.plist           # 应用信息
    ├── AppDelegate.swift    # 应用代理
    ├── SceneDelegate.swift  # 场景代理
    ├── ChatViewController.swift  # 主聊天界面
    ├── MessageCell.swift    # 消息气泡
    └── CodeRunner.swift     # 代码分析/执行

src/iosagent/                # （旧版 BeeWare 源码，暂时保留）
.github/workflows/
└── free-ios-build.yml       # 主 CI workflow
```

### CI 构建流程
1. 代码检查（ruff）
2. 安装 XcodeGen
3. `xcodegen generate` 生成 .xcodeproj
4. `xcodebuild` 构建 .app
5. 打包 .ipa
6. 上传 Artifact

## SideStore 安装步骤
1. 电脑上安装 AltServer：https://altstore.io/
2. iPhone 数据线连接电脑，信任此电脑
3. AltServer 托盘 → Install SideStore → 输入免费 Apple ID
4. GitHub Actions 构建成功 → 下载 IPA → SideStore 安装

## 踩坑记录
- Briefcase CI 失败：exit code 100，因为需要 Xcode GUI 会话 → 改用 XcodeGen + xcodebuild
- Ruff 检查失败：未使用的 import → 删除即可
- 推送脚本路径含空格 → 使用 `cd /d "D:\IOS Agent"`
