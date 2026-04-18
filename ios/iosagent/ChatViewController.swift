import UIKit

struct Message {
    enum Role {
        case user
        case assistant
        case system
    }

    let role: Role
    let content: String
    let timestamp: Date
}

class ChatViewController: UIViewController {
    // MARK: - Properties
    private var messages: [Message] = []
    private let codeRunner = CodeRunner()

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor.systemBackground
        tv.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tv.dataSource = self
        tv.delegate = self
        tv.keyboardDismissMode = .interactive
        return tv
    }()

    private lazy var inputContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemBackground
        return v
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        tv.backgroundColor = UIColor.systemBackground
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        tv.isScrollEnabled = false
        tv.delegate = self
        return tv
    }()

    private lazy var sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        btn.tintColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        btn.contentVerticalAlignment = .fill
        btn.contentHorizontalAlignment = .fill
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var toolbarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.secondarySystemBackground
        return v
    }()

    private lazy var clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("清空", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var settingsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "gearshape"), for: .normal)
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
        view.backgroundColor = .systemBackground

        // Navigation bar
        navigationController?.navigationBar.prefersLargeTitles = false

        // Toolbar
        toolbarView.addSubview(clearButton)
        toolbarView.addSubview(settingsButton)
        view.addSubview(toolbarView)

        // Main content
        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(textView)
        inputContainer.addSubview(sendButton)

        let bottom = inputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputContainerBottom = bottom

        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 44),

            clearButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),

            settingsButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            settingsButton.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            tableView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom,

            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            textView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func addWelcomeMessage() {
        let welcome = Message(
            role: .assistant,
            content: "👋 你好！我是 iOS Agent。\n\n我可以帮你：\n• 执行 Python 代码\n• 文件管理\n• 网络请求\n• AI 对话（需配置 API Key）\n\n直接在下方输入你的问题或代码吧！",
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
        textViewDidChange(textView)

        tableView.reloadData()
        scrollToBottom()

        processMessage(text)
    }

    @objc private func clearTapped() {
        messages.removeAll()
        addWelcomeMessage()
        tableView.reloadData()
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let response = self?.codeRunner.run(text: text) ?? "⚠️ 运行器初始化失败"

            DispatchQueue.main.async {
                let assistantMessage = Message(role: .assistant, content: response, timestamp: Date())
                self?.messages.append(assistantMessage)
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }
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
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .infinity))
        let newHeight = min(max(size.height, 36), 120)

        for constraint in textView.superview?.constraints ?? [] {
            if constraint.firstAttribute == .height {
                constraint.constant = newHeight
                break
            }
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            // Allow newlines in code
            return true
        }
        return true
    }
}
