import UIKit

struct Message: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date
    var isLoading: Bool = false
    
    enum Role {
        case user
        case assistant
        case system
    }
}

class ChatViewController: UIViewController {
    // MARK: - Properties
    private var messages: [Message] = []
    private let codeRunner = CodeRunner()
    private let aiService = AIService.shared
    private let taskManager = TaskManager.shared
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor.systemGroupedBackground
        tv.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tv.dataSource = self
        tv.delegate = self
        tv.keyboardDismissMode = .interactive
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        return tv
    }()
    
    private lazy var toolbarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOffset = CGSize(width: 0, height: -1)
        v.layer.shadowOpacity = 0.05
        v.layer.shadowRadius = 3
        return v
    }()
    
    private lazy var quickActionsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var inputContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .systemFont(ofSize: 16)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 20
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 40)
        tv.isScrollEnabled = false
        tv.delegate = self
        return tv
    }()
    
    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "输入消息..."
        l.font = .systemFont(ofSize: 16)
        l.textColor = .placeholderText
        return l
    }()
    
    private lazy var skillsButton: UIButton = {
        let btn = createToolbarButton(icon: "puzzlepiece.extension", title: "Skills")
        btn.addTarget(self, action: #selector(skillsTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var tasksButton: UIButton = {
        let btn = createToolbarButton(icon: "checklist", title: "任务")
        btn.addTarget(self, action: #selector(tasksTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var settingsButton: UIButton = {
        let btn = createToolbarButton(icon: "gearshape", title: "设置")
        btn.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        return btn
    }()
    
    private var inputContainerBottom: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
        addWelcomeMessage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "iOS Agent"
        view.backgroundColor = .systemGroupedBackground
        
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        // Quick actions
        quickActionsStack.addArrangedSubview(skillsButton)
        quickActionsStack.addArrangedSubview(tasksButton)
        quickActionsStack.addArrangedSubview(settingsButton)
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(toolbarView)
        toolbarView.addSubview(quickActionsStack)
        toolbarView.addSubview(inputContainer)
        inputContainer.addSubview(textView)
        inputContainer.addSubview(sendButton)
        inputContainer.addSubview(placeholderLabel)
        
        inputContainerBottom = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerBottom!,
            
            quickActionsStack.topAnchor.constraint(equalTo: toolbarView.topAnchor, constant: 8),
            quickActionsStack.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            quickActionsStack.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            quickActionsStack.heightAnchor.constraint(equalToConstant: 48),
            
            inputContainer.topAnchor.constraint(equalTo: quickActionsStack.bottomAnchor, constant: 8),
            inputContainer.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
            
            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 4),
            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            textView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            
            sendButton.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -6),
            sendButton.widthAnchor.constraint(equalToConstant: 32),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
            
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 20),
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor),
        ])
    }
    
    private func createToolbarButton(icon: String, title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        // 使用 SF Symbols 图标
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        btn.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        
        // 水平和垂直布局
        btn.configuration = nil  // 清除 configuration，使用传统方式
        btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        
        return btn
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func addWelcomeMessage() {
        let welcome = Message(
            role: .assistant,
            content: """
            👋 你好！我是 iOS Agent，你的智能编程助手。
            
            我可以帮你：
            • 🤖 **AI 对话** - 配置 API 后可以智能问答
            • 💻 **代码执行** - 输入代码我会分析并执行
            • 🧩 **Skills** - 下载各种技能扩展能力
            • 📋 **多任务** - 同时处理多个任务
            • 🔧 **代码更新** - 让我帮你写/改代码
            
            💡 **提示**: 点击左下角 ⚙️ 配置 API Key 解锁 AI 对话功能！
            """,
            timestamp: Date()
        )
        messages.append(welcome)
    }
    
    // MARK: - Actions
    @objc private func sendTapped() {
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = Message(role: .user, content: text, timestamp: Date())
        messages.append(userMessage)
        textView.text = ""
        placeholderLabel.isHidden = false
        textViewDidChange(textView)
        
        tableView.reloadData()
        scrollToBottom()
        
        processMessage(text)
    }
    
    @objc private func skillsTapped() {
        let skillsVC = SkillStoreViewController()
        let navController = UINavigationController(rootViewController: skillsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc private func tasksTapped() {
        let tasksVC = TaskListViewController()
        let navController = UINavigationController(rootViewController: tasksVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        inputContainerBottom?.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
        scrollToBottom()
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        inputContainerBottom?.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func processMessage(_ text: String) {
        let lower = text.lowercased()
        
        // Check for code execution request
        if codeRunner.isCodeRequest(text) {
            addLoadingMessage()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let response = self?.codeRunner.run(text: text) ?? "⚠️ 运行器初始化失败"
                
                DispatchQueue.main.async {
                    self?.removeLoadingMessage()
                    self?.addAssistantMessage(response)
                }
            }
            return
        }
        
        // Check for task creation request
        if lower.contains("帮我") && (lower.contains("做") || lower.contains("处理") || lower.contains("完成")) {
            addLoadingMessage()
            aiService.decomposeTask(text) { [weak self] result in
                self?.removeLoadingMessage()
                
                switch result {
                case .success(let tasks):
                    var response = "📋 我已将任务分解为 \(tasks.count) 个子任务：\n\n"
                    for (index, task) in tasks.enumerated() {
                        response += "\(index + 1). **\(task.title)**\n   \(task.description)\n\n"
                    }
                    response += "✨ 点击左下角「任务」查看和管理任务进度"
                    self?.addAssistantMessage(response)
                    
                case .failure(let error):
                    self?.addAssistantMessage("❌ 任务分解失败: \(error.localizedDescription)")
                }
            }
            return
        }
        
        // Check for code generation request
        if lower.contains("写代码") || lower.contains("生成代码") || lower.contains("帮我写") || lower.contains("代码生成") {
            addLoadingMessage()
            aiService.generateCodeUpdate(prompt: text, currentCode: nil, language: "swift") { [weak self] result in
                self?.removeLoadingMessage()
                
                switch result {
                case .success(let code):
                    self?.addAssistantMessage("💻 **生成的代码：**\n\n```swift\n\(code)\n```")
                case .failure(let error):
                    self?.addAssistantMessage("❌ 代码生成失败: \(error.localizedDescription)")
                }
            }
            return
        }
        
        // Default: AI chat (if configured) or simple response
        if aiService.isConfigured {
            addLoadingMessage()
            aiService.sendMessage(text) { [weak self] result in
                self?.removeLoadingMessage()
                
                switch result {
                case .success(let response):
                    self?.addAssistantMessage(response)
                case .failure(let error):
                    self?.addAssistantMessage("❌ AI 响应失败: \(error.localizedDescription)")
                }
            }
        } else {
            // Simple response without AI
            let response = codeRunner.run(text: text)
            addAssistantMessage(response)
        }
    }
    
    private func addLoadingMessage() {
        let loading = Message(role: .assistant, content: "正在思考...", timestamp: Date(), isLoading: true)
        messages.append(loading)
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func removeLoadingMessage() {
        if let index = messages.lastIndex(where: { $0.isLoading }) {
            messages.remove(at: index)
            tableView.reloadData()
        }
    }
    
    private func addAssistantMessage(_ content: String) {
        let message = Message(role: .assistant, content: content, timestamp: Date())
        messages.append(message)
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        cell.configure(with: messages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity))
        let newHeight = min(max(size.height, 44), 120)
        
        for constraint in textView.superview?.constraints ?? [] {
            if constraint.firstAttribute == .height {
                constraint.constant = newHeight
                break
            }
        }
        
        UIView.animate(withDuration: 0.1) {
            self.view.layoutIfNeeded()
        }
    }
}
