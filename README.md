# iOS Agent

> 🤖 运行在 iPhone/iPad 上的 AI Agent，支持执行 Python 代码、文件管理、网络请求  
> 使用 **BeeWare** 构建原生 iOS App，通过 **GitHub Actions** 在 Windows 上完成 CI/CD

⏳ **注意**：推送代码前，请先在 GitHub.com 创建仓库（步骤见下方），然后将 `your-username/ios-agent` 替换为你的实际 GitHub 用户名/仓库名。

---

## 项目结构

```
ios-agent/
├── src/iosagent/
│   ├── __init__.py         # 包入口
│   ├── app.py              # Toga UI 主界面
│   ├── agent_core.py       # LLM 对话 + 工具调用循环
│   ├── code_runner.py      # Python 沙箱执行器
│   ├── file_manager.py     # iOS 沙箱文件管理
│   └── resources/          # 图标等静态资源
├── ios/
│   └── ExportOptions.plist # IPA 导出配置
├── .github/workflows/
│   └── ios-build.yml       # GitHub Actions 构建流水线
├── pyproject.toml          # Briefcase 项目配置
└── requirements.txt
```

---

## 快速开始

### 1. 克隆项目并安装依赖

```bash
# Windows
git clone https://github.com/your-username/ios-agent
cd ios-agent
pip install -r requirements.txt
```

### 2. 配置 LLM API Key

在 GitHub 仓库 → **Settings → Secrets and variables → Actions** 中添加：

| Secret 名称 | 说明 |
|-------------|------|
| `LLM_API_KEY` | LLM 服务 API Key（DeepSeek/OpenAI 等） |

本地测试时，在终端设置环境变量：
```powershell
$env:LLM_API_KEY = "sk-xxxxxxxxxxxxxxxx"
$env:LLM_BASE_URL = "https://api.deepseek.com/v1"   # 或 OpenAI 地址
$env:LLM_MODEL = "deepseek-chat"
```

### 3. 推送代码触发自动构建

```bash
git add .
git commit -m "feat: iOS Agent v0.1.0"
git push origin main
```

GitHub Actions 会自动在 **macOS runner** 上构建 iOS 模拟器包。

---

## GitHub Actions 流水线说明

```
push to main
    │
    ├─► [lint]              代码检查（ubuntu，快）
    │
    └─► [build-simulator]   iOS 模拟器构建（macos-latest）
            │
            └── 产物上传到 Artifacts（保留 7 天）

push tag v*.*.*
    │
    ├─► [lint]
    ├─► [build-device]      真机构建 + 签名 + TestFlight 上传
    └─► [release]           自动创建 GitHub Release
```

### 触发方式

| 场景 | 操作 |
|------|------|
| 日常开发构建 | 推送到 main 分支 |
| 手动构建 | Actions 页面 → Run workflow |
| 发布版本 | `git tag v0.1.0 && git push --tags` |

---

## 真机发布配置（可选）

要构建真机包并上传 TestFlight，需在 GitHub Secrets 中额外配置：

| Secret | 获取方式 |
|--------|----------|
| `BUILD_CERTIFICATE_BASE64` | Xcode → Keychain → 导出 .p12 → `base64 -i cert.p12` |
| `P12_PASSWORD` | 导出时设置的密码 |
| `BUILD_PROVISION_PROFILE_BASE64` | Apple Developer 网站下载 → `base64 -i xxx.mobileprovision` |
| `KEYCHAIN_PASSWORD` | 随机字符串即可 |
| `APP_STORE_CONNECT_API_KEY` | App Store Connect → API Keys → 导出 JSON |

**APP_STORE_CONNECT_API_KEY JSON 格式：**
```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
}
```

---

## 本地开发（需要 macOS）

```bash
# 安装 Briefcase
pip install briefcase

# 创建 Xcode 项目
briefcase create iOS

# 在模拟器中运行
briefcase run iOS

# 构建 .app
briefcase build iOS
```

---

## Agent 支持的操作

| 指令示例 | 功能 |
|----------|------|
| `print(2 ** 10)` | 执行 Python 代码 |
| `帮我写一个排序算法` | LLM 生成代码并执行 |
| `读取文件 notes.txt` | 读取沙箱文件 |
| `写入文件 hello.py "print('hi')"` | 写入文件 |
| `获取网页 https://...` | HTTP 请求 |
| `查看系统信息` | Python/设备信息 |

---

## 开源协议

MIT License
