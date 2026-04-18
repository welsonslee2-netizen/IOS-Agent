import Foundation

class CodeRunner {
    // MARK: - Public API
    func run(text: String) -> String {
        if isCodeRequest(text) {
            return explainCode(text)
        }
        return generateResponse(text)
    }

    // MARK: - Code Detection
    private func isCodeRequest(_ text: String) -> Bool {
        let lower = text.lowercased()
        let codeKeywords = [
            "print(", "def ", "import ", "from ", "class ",
            "for ", "while ", "if ", "return ",
            "```python", "```py", "```"
        ]
        return codeKeywords.contains { lower.contains($0) }
    }

    private func extractCode(from text: String) -> String {
        if let start = text.range(of: "```python"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.range(of: "```py"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.range(of: "```"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Code Analysis (without Python runtime)
    private func explainCode(_ text: String) -> String {
        let code = extractCode(from: text)

        // 简单的代码分析
        var analysis = "📟 **代码分析**\n\n"

        if code.contains("print(") {
            let printMatches = code.components(separatedBy: "print(").dropFirst()
            var outputs: [String] = []
            for match in printMatches {
                if let end = match.range(of: ")") {
                    let arg = String(match[..<end.lowerBound])
                    let cleaned = arg.trimmingCharacters(in: CharacterSet(charactersIn: "\"', "))
                    outputs.append(cleaned)
                }
            }
            if !outputs.isEmpty {
                analysis += "🔍 `print()` 语句输出:\n```\n"
                analysis += outputs.joined(separator: "\n")
                analysis += "\n```\n\n"
            }
        }

        analysis += "```python\n\(code)\n```\n\n"

        if code.contains("def ") {
            if let range = code.range(of: "def ") {
                let after = code[range.upperBound...]
                if let endRange = after.firstIndex(of: ":") {
                    let funcName = String(after[..<endRange]).trimmingCharacters(in: CharacterSet.letters.inverted)
                    analysis += "🔧 检测到函数: `\(funcName)`\n"
                }
            }
        }

        analysis += """

        ⚠️ **注意**: 当前为 iOS 原生版本，完整 Python 执行功能需要集成 PythonKit。
        请在 macOS 上用 Xcode 打开项目，运行后可在真机上体验完整 Python 支持。
        """

        return analysis
    }

    // MARK: - Natural Language Response
    private func generateResponse(_ text: String) -> String {
        let lower = text.lowercased()

        if lower.contains("你好") || lower.contains("hi") || lower.contains("hello") {
            return "👋 你好！有什么我可以帮你的吗？\n\n你可以：\n• 输入 Python 代码，我会分析它\n• 问编程相关问题\n• 描述你想要的功能"
        }

        if lower.contains("你能做什么") || lower.contains("help") || lower.contains("帮助") {
            return """
            🤖 **iOS Agent 功能一览**

            **代码分析**（当前版本）
            输入 Python 代码，我会分析语法并展示可能的输出。

            **后续更新**
            集成 PythonKit 后，将支持：
            - 实时执行 Python 代码
            - 打印输出结果
            - 完整的 Python 3 标准库

            **示例**:
            ```
            print("Hello, iOS!")
            for i in range(3):
                print(i)
            ```
            """
        }

        if lower.contains("关于") || lower.contains("about") {
            return "📱 **iOS Agent v1.0**\n\n一个运行在 iOS 设备上的 AI 编程助手。\n基于 Swift 原生开发。\n\n如需 AI 对话功能，请配置 OpenAI 或 DeepSeek API Key。"
        }

        if lower.contains("版本") || lower.contains("version") {
            return "📱 **版本信息**\n\n• App 版本: 1.0.0\n• 平台: iOS 15.0+\n• 框架: Swift 5 + SwiftUI\n• 状态: 原生版本（支持代码分析）"
        }

        return """
        💬 收到: `\(text.prefix(100))...`

        我目前可以帮你分析 Python 代码。

        示例:
        ```
        print("Hello!")
        for i in range(5):
            print(i)
        ```
        """
    }
}
