# iOS 应用免签名打包攻略（SideStore 免费安装）

> 基于 GitHub Actions 云端构建，无需 Mac 和 Apple Developer 账号

## 📋 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      开发流程                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Windows/Mac/Linux  →  GitHub Actions  →  SideStore 安装   │
│       写代码           macOS Runner         iPhone 真机      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ 技术栈

| 组件 | 工具 | 说明 |
|------|------|------|
| 项目生成 | **XcodeGen** | YAML 配置生成 .xcodeproj |
| CI/CD | **GitHub Actions** | macOS runner 云端构建 |
| 构建命令 | **xcodebuild** | 命令行构建，绕过 Xcode GUI |
| 安装方式 | **SideStore** | 免 Apple Developer 账号安装 |

## 📁 标准项目结构

```
your-project/
├── project.yml              # XcodeGen 配置（核心）
├── ExportOptions.plist      # IPA 导出配置
├── AppName/
│   ├── Info.plist
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Assets.xcassets/     # 必须包含 AppIcon
│   │   ├── AppIcon.appiconset/
│   │   │   ├── Contents.json
│   │   │   └── AppIcon.png  # ⚠️ 必须 1024x1024
│   │   └── LaunchBackground.colorset/
│   │       └── Contents.json
│   └── *.swift
└── .github/workflows/
    └── build.yml            # GitHub Actions workflow
```

## 🔧 核心配置

### 1. project.yml (XcodeGen)

```yaml
name: YourApp
options:
  bundleIdPrefix: com.yourname
  deploymentTarget:
    iOS: "15.0"
  xcodeVersion: "16.4"

targets:
  YourApp:
    type: application
    platform: iOS
    sources:
      - path: YourApp
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yourname.yourapp
      MARKETING_VERSION: "1.0.0"
      CURRENT_PROJECT_VERSION: "1"
      INFOPLIST_FILE: YourApp/Info.plist
      CODE_SIGN_STYLE: Manual
      CODE_SIGNING_REQUIRED: NO
      CODE_SIGNING_ALLOWED: NO
      CODE_SIGN_IDENTITY: ""
      DEVELOPMENT_TEAM: ""
      ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
      GENERATE_INFOPLIST_FILE: NO
      SWIFT_VERSION: "5.0"
      TARGETED_DEVICE_FAMILY: "1"
      IPHONEOS_DEPLOYMENT_TARGET: "15.0"
      ARCHS: "arm64"
      VALID_ARCHS: "arm64"
      ENABLE_BITCODE: NO
```

### 2. ExportOptions.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>none</string>
    <key>thinning</key>
    <string><none></string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

### 3. GitHub Actions Workflow

```yaml
name: iOS Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: macos-14
    
    steps:
      - uses: actions/checkout@v4
      
      # 安装 XcodeGen
      - name: Install XcodeGen
        run: |
          brew install xcodegen
      
      # 生成项目
      - name: Generate Xcode Project
        run: xcodegen generate
      
      # 构建
      - name: Build
        run: |
          xcodebuild -project *.xcodeproj \
            -scheme YourApp \
            -configuration Release \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY="" \
            DEVELOPMENT_TEAM="" \
            IPHONEOS_DEPLOYMENT_TARGET="15.0" \
            ARCHS="arm64" \
            VALID_ARCHS="arm64" \
            2>&1 | tee build.log

      # 打包 IPA
      - name: Package IPA
        run: |
          mkdir -p Payload
          cp -r build/Build/Products/Release-iphoneos/YourApp.app Payload/
          zip -r YourApp.ipa Payload
          rm -rf Payload
      
      # 上传
      - uses: actions/upload-artifact@v4
        with:
          name: YourApp-IPA
          path: YourApp.ipa
```

## ⚠️ 常见错误与解决方案

### 错误 1: Asset Catalog 编译失败

```
error: The stickers icon set or app icon set named "AppIcon" 
did not have any applicable content.
```

**原因**: AppIcon.png 尺寸不对

**解决**:
```bash
# 确保图片是 1024x1024
python -c "from PIL import Image; \
  img = Image.open('AppIcon.png'); \
  img.resize((1024, 1024)).save('AppIcon.png')"
```

### 错误 2: private 方法被外部访问

```
error: 'isCodeRequest' is inaccessible due to 'private' protection level
```

**解决**: 将 `private func` 改为 `func`

### 错误 3: UIEdgeInsets 参数错误

```swift
// ❌ 错误：两个 top
UIEdgeInsets(top: 8, left: 16, top: 8, bottom: 16)

// ✅ 正确：top/left/bottom/right
UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
```

### 错误 4: 资源文件缺失

```
error: cannot find color set named "LaunchBackground"
```

**解决**: 在 Assets.xcassets 中创建资源

```bash
mkdir -p Assets.xcassets/LaunchBackground.colorset
echo '{
  "colors" : [{ "color" : { "color-space" : "srgb",
  "components" : { "alpha" : "1.000", "blue" : "1.000",
  "green" : "1.000", "red" : "1.000" } }, "idiom" : "universal" }],
  "info" : { "author" : "xcode", "version" : 1 }
}' > Assets.xcassets/LaunchBackground.colorset/Contents.json
```

## 📱 SideStore 安装步骤

### 电脑上准备

1. 下载 **AltServer**：https://altstore.io/
2. 安装 AltServer 到 Applications
3. iPhone 用数据线连接电脑，信任此电脑

### iPhone 上安装

1. 在 iPhone 浏览器打开：https://altstore.io/
2. 下载 SideStore（免费）
3. 打开 SideStore → Add Source → 填入 GitHub 仓库地址

### 安装 IPA

1. GitHub Actions 构建成功
2. 下载 Artifact (IPA 文件)
3. SideStore → Library → Import → 选择 IPA
4. 输入你的免费 Apple ID
5. 安装完成！

## 🎯 最佳实践

### 1. 图标制作规范

| 尺寸 | 用途 |
|------|------|
| 1024x1024 | App Store / AppIcon 唯一尺寸 |
| 180x180 | iPhone @3x |
| 120x120 | iPhone @2x |
| 167x167 | iPad Pro |

> iOS 会自动生成其他尺寸，不要手动缩放！

### 2. 按钮交互

```swift
// ✅ 推荐：明确指定大小和边距
button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
button.frame.size = CGSize(width: 60, height: 48)
```

### 3. CI 构建优化

- 使用 `tee build.log` 保存完整日志
- 失败时上传日志 Artifact 便于调试
- 设置合理的超时时间

## 🔗 关键资源

| 资源 | 链接 |
|------|------|
| XcodeGen | https://xcodegen.org/ |
| SideStore | https://altstore.io/ |
| AltServer | https://altstore.io/ |
| GitHub Actions | https://github.com/features/actions |

## 📝 总结

| 优势 | 说明 |
|------|------|
| ✅ 零成本 | 不需要 Mac，不需要 $99 Apple Developer |
| ✅ 全自动 | push 代码自动构建 |
| ✅ 真机测试 | SideStore 安装到 iPhone |
| ✅ 快速迭代 | 5 分钟内完成构建+安装 |

> **提示**: 如果你有 $99 Apple Developer 账号，可以在 ExportOptions.plist 中配置签名信息，实现更便捷的安装方式。
