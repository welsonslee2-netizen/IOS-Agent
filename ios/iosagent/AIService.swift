import Foundation

// MARK: - AI Message
struct AIMessage: Codable {
    let role: String
    let content: String
}

// MARK: - AI Service
class AIService {
    static let shared = AIService()
    
    private let userDefaults = UserDefaults.standard
    private var messages: [AIMessage] = []
    
    private init() {
        loadMessages()
    }
    
    // MARK: - Configuration
    var apiProvider: Int {
        return userDefaults.integer(forKey: "api_provider")
    }
    
    var apiKey: String? {
        return userDefaults.string(forKey: "api_key")
    }
    
    var baseURL: String? {
        return userDefaults.string(forKey: "api_base_url")
    }
    
    var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // MARK: - API Call
    func sendMessage(_ content: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard isConfigured else {
            completion(.failure(AIServiceError.notConfigured))
            return
        }
        
        // Add user message
        messages.append(AIMessage(role: "user", content: content))
        
        // Determine endpoint and model
        let (urlString, model) = getAPIConfig()
        
        guard let url = URL(string: urlString + "/chat/completions") else {
            completion(.failure(AIServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        // Build messages with system prompt
        var requestMessages: [[String: String]] = [
            ["role": "system", "content": getSystemPrompt()]
        ]
        
        // Add conversation history (last 10 messages)
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            requestMessages.append(["role": msg.role, "content": msg.content])
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": requestMessages,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(AIServiceError.noData))
                }
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let error = json["error"] as? [String: Any] {
                        let message = error["message"] as? String ?? "Unknown error"
                        DispatchQueue.main.async {
                            completion(.failure(AIServiceError.apiError(message)))
                        }
                        return
                    }
                    
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        // Add assistant response to history
                        self?.messages.append(AIMessage(role: "assistant", content: content))
                        self?.saveMessages()
                        
                        DispatchQueue.main.async {
                            completion(.success(content))
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(AIServiceError.parseError))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    private func getAPIConfig() -> (url: String, model: String) {
        switch apiProvider {
        case 0: // DeepSeek
            return ("https://api.deepseek.com", "deepseek-chat")
        case 1: // OpenAI
            return ("https://api.openai.com", "gpt-3.5-turbo")
        case 2: // Custom
            return (baseURL ?? "https://api.example.com", "gpt-3.5-turbo")
        default:
            return ("https://api.deepseek.com", "deepseek-chat")
        }
    }
    
    private func getSystemPrompt() -> String {
        return """
        你是一个专业的 iOS 开发助手，可以帮助用户：
        1. 编写和更新 Python/Swift/JavaScript 代码
        2. 分析代码问题并提供解决方案
        3. 生成完整的代码文件和项目结构
        4. 解释技术概念和最佳实践
        
        当用户要求编写或更新代码时，请：
        - 给出清晰、完整的代码
        - 添加必要的注释
        - 解释关键部分的功能
        - 如果需要多文件项目，说明文件结构
        
        支持的编程语言：Python, Swift, JavaScript, HTML, CSS, JSON, YAML
        
        用户可以直接通过对话让你修改、创建或优化代码。
        """
    }
    
    // MARK: - Code Update
    func generateCodeUpdate(prompt: String, currentCode: String?, language: String, completion: @escaping (Result<String, Error>) -> Void) {
        var fullPrompt = prompt
        
        if let code = currentCode, !code.isEmpty {
            fullPrompt = """
            用户请求: \(prompt)
            
            当前代码:
            ```\(language)
            \(code)
            ```
            
            请根据用户请求更新代码。
            """
        }
        
        sendMessage(fullPrompt, completion: completion)
    }
    
    // MARK: - Task Decomposition
    func decomposeTask(_ task: String, completion: @escaping (Result<[(title: String, description: String)], Error>) -> Void) {
        let prompt = """
        将以下任务分解为 3-5 个可执行的子任务：
        任务: \(task)
        
        请以 JSON 格式返回，格式如下：
        [
            {"title": "子任务1标题", "description": "子任务1描述"},
            {"title": "子任务2标题", "description": "子任务2描述"}
        ]
        """
        
        sendMessage(prompt) { result in
            switch result {
            case .success(let response):
                // Parse JSON from response
                if let jsonStart = response.firstIndex(of: "["),
                   let jsonEnd = response.lastIndex(of: "]") {
                    let jsonString = String(response[jsonStart...jsonEnd])
                    if let data = jsonString.data(using: .utf8),
                       let items = try? JSONDecoder().decode([[String: String]].self, from: data) {
                        let tasks = items.compactMap { item -> (title: String, description: String)? in
                            guard let title = item["title"], let description = item["description"] else {
                                return nil
                            }
                            return (title, description)
                        }
                        DispatchQueue.main.async {
                            completion(.success(tasks))
                        }
                        return
                    }
                }
                
                // Fallback: simple parsing
                let lines = response.components(separatedBy: "\n").filter { $0.hasPrefix("-") || $0.hasPrefix("•") || $0.hasPrefix("1.") || $0.hasPrefix("2.") || $0.hasPrefix("3.") }
                let tasks: [(title: String, description: String)] = lines.prefix(5).enumerated().map { index, line in
                    let cleanLine = line.replacingOccurrences(of: "^[\\d\\.\\-\\•\\s]+", with: "", options: .regularExpression)
                    return ("子任务 \(index + 1)", cleanLine)
                }
                
                if !tasks.isEmpty {
                    DispatchQueue.main.async {
                        completion(.success(Array(tasks)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(AIServiceError.parseError))
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Message Management
    func clearMessages() {
        messages.removeAll()
        saveMessages()
    }
    
    private func saveMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            userDefaults.set(data, forKey: "ai_messages")
        }
    }
    
    private func loadMessages() {
        if let data = userDefaults.data(forKey: "ai_messages"),
           let saved = try? JSONDecoder().decode([AIMessage].self, from: data) {
            messages = saved
        }
    }
}

// MARK: - Errors
enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidURL
    case noData
    case parseError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "请先在设置中配置 API Key"
        case .invalidURL:
            return "无效的 API 地址"
        case .noData:
            return "服务器未返回数据"
        case .parseError:
            return "解析响应失败"
        case .apiError(let message):
            return "API 错误: \(message)"
        }
    }
}
