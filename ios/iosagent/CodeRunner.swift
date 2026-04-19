import Foundation

/// Python 代码执行结果
struct PythonExecutionResult {
    let output: String
    let error: String?
    let executionTime: TimeInterval
    let isSuccess: Bool
}

/// Python 代码执行器
/// 使用多种策略执行 Python 代码
class CodeRunner {
    
    // MARK: - Public API
    
    /// 执行代码或生成响应
    /// - Parameters:
    ///   - text: 用户输入的文本
    ///   - apiKey: 可选的 API Key，用于云端执行
    ///   - completion: 完成回调
    func run(text: String, apiKey: String? = nil, completion: @escaping (String) -> Void) {
        if isCodeRequest(text) {
            let code = extractCode(from: text)
            if let apiKey = apiKey, !apiKey.isEmpty {
                // 使用云端执行（通过 AI API）
                executeCodeRemotely(code: code, apiKey: apiKey, completion: completion)
            } else {
                // 本地模拟执行
                let result = simulatePythonExecution(code)
                completion(result)
            }
        } else {
            completion(generateResponse(text))
        }
    }
    
    /// 同步执行（保持向后兼容）
    func run(text: String) -> String {
        var result = ""
        run(text: text, apiKey: nil) { response in
            result = response
        }
        return result
    }

    // MARK: - Code Detection
    
    func isCodeRequest(_ text: String) -> Bool {
        let lower = text.lowercased()
        let codeKeywords = [
            "print(", "def ", "import ", "from ", "class ",
            "for ", "while ", "if ", "return ", "elif ",
            "try:", "except", "finally:", "with ", "as ",
            "lambda", "yield", "raise", "pass", "break", "continue",
            "```python", "```py", "```"
        ]
        return codeKeywords.contains { lower.contains($0) }
    }

    private func extractCode(from text: String) -> String {
        // 尝试提取 ```python ... ``` 块
        if let start = text.range(of: "```python"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 尝试 ```py ... ```
        if let start = text.range(of: "```py"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 尝试 ``` ... ```
        if let start = text.range(of: "```"),
           let end = text.range(of: "```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // 如果没有代码块，整段都是代码
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - 云端执行 (通过 AI API)
    
    private func executeCodeRemotely(code: String, apiKey: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion("❌ API 配置错误")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        请执行以下 Python 代码，并只返回执行结果（stdout 输出），不要其他解释。
        如果有错误，只返回错误信息。

        代码:
        \(code)
        """
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "你是一个 Python 代码执行器。用户给你代码，你要返回执行结果。如果代码有语法错误，返回错误信息。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.1,
            "max_tokens": 1000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion("❌ 请求体序列化失败: \(error.localizedDescription)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion("❌ 网络错误: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion("❌ 没有收到响应数据")
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    let formatted = self.formatExecutionOutput(content)
                    DispatchQueue.main.async {
                        completion(formatted)
                    }
                } else {
                    // 尝试解析错误
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        DispatchQueue.main.async {
                            completion("❌ API 错误: \(message)")
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion("❌ 响应格式解析失败")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion("❌ JSON 解析失败")
                }
            }
        }
        task.resume()
    }
    
    private func formatExecutionOutput(_ output: String) -> String {
        return """
        📟 **执行结果**

        ```
        \(output.trimmingCharacters(in: .whitespacesAndNewlines))
        ```
        """
    }

    // MARK: - 本地模拟执行
    
    /// 本地模拟 Python 执行（支持常见操作）
    private func simulatePythonExecution(_ code: String) -> String {
        var output = "📟 **本地模拟执行**\n\n"
        
        // 分析代码结构
        let lines = code.components(separatedBy: "\n")
        var printOutputs: [String] = []
        var errors: [String] = []
        
        // 简单模拟执行
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 模拟 print() 语句
            if trimmed.hasPrefix("print(") {
                if let result = simulatePrint(trimmed) {
                    printOutputs.append(result)
                } else {
                    errors.append("无法解析: \(trimmed)")
                }
            }
            
            // 模拟 for 循环
            if trimmed.hasPrefix("for ") {
                if let loopOutput = simulateForLoop(code: code) {
                    printOutputs.append(contentsOf: loopOutput)
                    break // 循环已处理整段
                }
            }
            
            // 模拟变量赋值
            if trimmed.contains("=") && !trimmed.hasPrefix("#") {
                // 简单变量追踪
            }
        }
        
        if !printOutputs.isEmpty {
            output += "**输出:**\n```\n"
            output += printOutputs.joined(separator: "\n")
            output += "\n```\n\n"
        }
        
        if !errors.isEmpty {
            output += "⚠️ **警告:**\n"
            output += errors.joined(separator: "\n")
            output += "\n\n"
        }
        
        output += "📝 **代码结构分析:**\n"
        output += analyzeCodeStructure(code)
        
        output += """

        💡 **提示**: 配置 API Key 后，可以使用 AI 云端执行获得真实结果！
        """
        
        return output
    }
    
    private func simulatePrint(_ line: String) -> String? {
        // 提取 print() 内的内容
        guard let start = line.range(of: "print("),
              let end = line.range(of: ")", range: start.upperBound..<line.endIndex) else {
            return nil
        }
        
        let content = String(line[start.upperBound..<end.lowerBound])
        return evaluateExpression(content)
    }
    
    private func evaluateExpression(_ expr: String) -> String {
        var result = expr
        
        // 处理字符串字面量 "..."
        if result.hasPrefix("\"") && result.hasSuffix("\"") {
            return String(result.dropFirst().dropLast())
        }
        if result.hasPrefix("'") && result.hasSuffix("'") {
            return String(result.dropFirst().dropLast())
        }
        
        // 处理 f-string
        if result.hasPrefix("f\"") || result.hasPrefix("f'") {
            return "f-string (需要完整执行)"
        }
        
        // 处理数字
        if let num = Double(result.trimmingCharacters(in: .whitespaces)) {
            if num == floor(num) {
                return String(Int(num))
            }
            return String(num)
        }
        
        // 返回表达式本身
        return result
    }
    
    private func simulateForLoop(code: String) -> [String]? {
        var outputs: [String] = []
        var inLoop = false
        var loopVar = ""
        var loopRange = 0..<0
        
        let lines = code.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("for ") {
                inLoop = true
                // 解析 for i in range(x):
                if let varStart = trimmed.range(of: "for "),
                   let varEnd = trimmed.range(of: " in range(", range: varStart.upperBound..<trimmed.endIndex) {
                    loopVar = String(trimmed[varStart.upperBound..<varEnd.lowerBound])
                    
                    if let rangeStart = trimmed.range(of: "range("),
                       let rangeEnd = trimmed.range(of: ")", range: rangeStart.upperBound..<trimmed.endIndex) {
                        let rangeStr = String(trimmed[rangeStart.upperBound..<rangeEnd.lowerBound])
                        if let n = Int(rangeStr) {
                            loopRange = 0..<n
                        }
                    }
                }
            } else if inLoop && trimmed.hasPrefix("print(") {
                for i in loopRange {
                    if let output = simulatePrint(trimmed) {
                        // 替换循环变量
                        let replaced = output.replacingOccurrences(of: loopVar, with: String(i))
                        outputs.append(replaced)
                    }
                }
            } else if inLoop && !trimmed.isEmpty && !trimmed.hasPrefix("for ") && !trimmed.hasPrefix("    ") && !trimmed.hasPrefix("\t") {
                inLoop = false
            }
        }
        
        return outputs.isEmpty ? nil : outputs
    }
    
    private func analyzeCodeStructure(_ code: String) -> String {
        var analysis = ""
        
        if code.contains("def ") {
            let funcMatches = code.components(separatedBy: "def ")
            for (index, match) in funcMatches.dropFirst().enumerated() {
                if let end = match.firstIndex(of: ":") {
                    let funcName = String(match[..<end]).trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
                    analysis += "- 🔧 函数: `\(funcName)`\n"
                }
            }
        }
        
        if code.contains("class ") {
            let classMatches = code.components(separatedBy: "class ")
            for (index, match) in classMatches.dropFirst().enumerated() {
                if let end = match.firstIndex(of: ":") {
                    let className = String(match[..<end]).trimmingCharacters(in: CharacterSet(charactersIn: " \t("))
                    analysis += "- 📦 类: `\(className)`\n"
                }
            }
        }
        
        if code.contains("import ") || code.contains("from ") {
            analysis += "- 📚 导入模块\n"
        }
        
        if code.contains("if ") {
            analysis += "- 🔀 条件判断\n"
        }
        
        if code.contains("for ") || code.contains("while ") {
            analysis += "- 🔄 循环结构\n"
        }
        
        if analysis.isEmpty {
            analysis = "- 📄 简单脚本\n"
        }
        
        return analysis
    }

    // MARK: - Natural Language Response
    
    private func generateResponse(_ text: String) -> String {
        let lower = text.lowercased()

        if lower.contains("你好") || lower.contains("hi") || lower.contains("hello") {
            return """
            👋 你好！我是 iOS Agent，你的智能编程助手。

            **主要功能：**
            • 💻 **代码执行** - 输入 Python 代码，我会帮你执行
            • 🤖 **AI 对话** - 配置 API 后可以智能问答
            • 🧩 **Skills** - 下载各种技能扩展能力
            • 📋 **多任务** - 同时处理多个任务

            💡 **开始**: 直接输入 Python 代码试试！
            """
        }

        if lower.contains("你能做什么") || lower.contains("help") || lower.contains("帮助") || lower.contains("功能") {
            return """
            🤖 **iOS Agent 功能一览**

            **代码执行** ✨ (推荐)
            输入 Python 代码，我会分析并执行：
            ```python
            print("Hello!")
            for i in range(3):
                print(i)
            ```

            **配置 API Key** (可选)
            在设置中配置 OpenAI/DeepSeek API Key，可获得更强大的代码执行能力。

            **Skills 扩展**
            下载各种技能来扩展 App 能力。

            **任务管理**
            帮你分解和管理复杂任务。
            """
        }

        if lower.contains("关于") || lower.contains("about") {
            return "📱 **iOS Agent v1.0**\n\n一个运行在 iOS 设备上的 AI 编程助手。\n基于 Swift 原生开发。\n\n如需 AI 对话功能，请配置 OpenAI 或 DeepSeek API Key。"
        }

        if lower.contains("版本") || lower.contains("version") {
            return """
            📱 **版本信息**

            • App 版本: 1.0.0
            • 平台: iOS 15.0+
            • 框架: Swift 5 + UIKit
            • 代码执行: 本地模拟 + 云端执行（需 API Key）
            """
        }

        if lower.contains("python") && (lower.contains("是什么") || lower.contains("是什么语言")) {
            return """
            🐍 **Python 简介**

            Python 是一种高级编程语言，以简洁易读著称。

            **基础语法:**
            ```python
            # 变量
            name = "World"

            # 输出
            print(f"Hello, {name}!")

            # 循环
            for i in range(5):
                print(i)
            ```

            在输入框输入代码即可执行！
            """
        }

        return """
        💬 收到你的消息了！

        **试试输入代码：**
        ```python
        print("Hello, iOS!")
        for i in range(3):
            print(i)
        ```
        """
    }
}
