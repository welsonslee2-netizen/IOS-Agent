import UIKit

class SettingsViewController: UIViewController {
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // API Section
    private lazy var apiSectionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "API 配置"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private lazy var apiContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        return v
    }()
    
    private lazy var providerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "服务商"
        l.font = .systemFont(ofSize: 16)
        return l
    }()
    
    private lazy var providerSegment: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["DeepSeek", "OpenAI", "自定义"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(providerChanged), for: .valueChanged)
        return sc
    }()
    
    private lazy var apiKeyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "API Key"
        l.font = .systemFont(ofSize: 16)
        return l
    }()
    
    private lazy var apiKeyTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "输入你的 API Key"
        tf.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.delegate = self
        return tf
    }()
    
    private lazy var baseURLLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "API 地址（自定义）"
        l.font = .systemFont(ofSize: 16)
        return l
    }()
    
    private lazy var baseURLTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "https://api.deepseek.com"
        tf.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .done
        tf.delegate = self
        tf.isHidden = true
        return tf
    }()
    
    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("保存配置", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var testButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle("测试连接", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.addTarget(self, action: #selector(testTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = ""
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()
    
    // Help Section
    private lazy var helpSectionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "帮助"
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }()
    
    private lazy var helpContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        return v
    }()
    
    private lazy var helpTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 14)
        tv.text = """
        📌 DeepSeek（推荐）
        1. 访问 https://platform.deepseek.com/
        2. 注册账号并充值（如需要）
        3. 创建 API Key 并复制到这里
        
        📌 OpenAI
        1. 访问 https://platform.openai.com/
        2. 创建 API Key
        
        💡 提示：API Key 以 sk- 开头，请妥善保管！
        """
        return tv
    }()
    
    // Version
    private lazy var versionLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "iOS Agent v1.0.0"
        l.font = .systemFont(ofSize: 12)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        return l
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "设置"
        view.backgroundColor = .systemBackground
        
        // Navigation
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(apiSectionLabel)
        contentView.addSubview(apiContainer)
        apiContainer.addSubview(providerLabel)
        apiContainer.addSubview(providerSegment)
        apiContainer.addSubview(apiKeyLabel)
        apiContainer.addSubview(apiKeyTextField)
        apiContainer.addSubview(baseURLLabel)
        apiContainer.addSubview(baseURLTextField)
        apiContainer.addSubview(testButton)
        apiContainer.addSubview(statusLabel)
        apiContainer.addSubview(saveButton)
        
        contentView.addSubview(helpSectionLabel)
        contentView.addSubview(helpContainer)
        helpContainer.addSubview(helpTextView)
        
        contentView.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            apiSectionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            apiSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            apiContainer.topAnchor.constraint(equalTo: apiSectionLabel.bottomAnchor, constant: 8),
            apiContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            apiContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            providerLabel.topAnchor.constraint(equalTo: apiContainer.topAnchor, constant: 16),
            providerLabel.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            
            providerSegment.topAnchor.constraint(equalTo: providerLabel.bottomAnchor, constant: 8),
            providerSegment.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            providerSegment.trailingAnchor.constraint(equalTo: apiContainer.trailingAnchor, constant: -16),
            
            apiKeyLabel.topAnchor.constraint(equalTo: providerSegment.bottomAnchor, constant: 16),
            apiKeyLabel.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            
            apiKeyTextField.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 8),
            apiKeyTextField.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            apiKeyTextField.trailingAnchor.constraint(equalTo: apiContainer.trailingAnchor, constant: -16),
            apiKeyTextField.heightAnchor.constraint(equalToConstant: 44),
            
            baseURLLabel.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 16),
            baseURLLabel.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            
            baseURLTextField.topAnchor.constraint(equalTo: baseURLLabel.bottomAnchor, constant: 8),
            baseURLTextField.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            baseURLTextField.trailingAnchor.constraint(equalTo: apiContainer.trailingAnchor, constant: -16),
            baseURLTextField.heightAnchor.constraint(equalToConstant: 44),
            
            testButton.topAnchor.constraint(equalTo: baseURLTextField.bottomAnchor, constant: 12),
            testButton.centerXAnchor.constraint(equalTo: apiContainer.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: apiContainer.trailingAnchor, constant: -16),
            
            saveButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: apiContainer.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: apiContainer.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: apiContainer.bottomAnchor, constant: -16),
            
            helpSectionLabel.topAnchor.constraint(equalTo: apiContainer.bottomAnchor, constant: 24),
            helpSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            helpContainer.topAnchor.constraint(equalTo: helpSectionLabel.bottomAnchor, constant: 8),
            helpContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            helpContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            helpTextView.topAnchor.constraint(equalTo: helpContainer.topAnchor, constant: 12),
            helpTextView.leadingAnchor.constraint(equalTo: helpContainer.leadingAnchor, constant: 12),
            helpTextView.trailingAnchor.constraint(equalTo: helpContainer.trailingAnchor, constant: -12),
            helpTextView.bottomAnchor.constraint(equalTo: helpContainer.bottomAnchor, constant: -12),
            
            versionLabel.topAnchor.constraint(equalTo: helpContainer.bottomAnchor, constant: 24),
            versionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }
    
    private func loadSettings() {
        let provider = userDefaults.integer(forKey: "api_provider")
        providerSegment.selectedSegmentIndex = provider
        
        if let apiKey = userDefaults.string(forKey: "api_key") {
            apiKeyTextField.text = apiKey
        }
        
        if let baseURL = userDefaults.string(forKey: "api_base_url") {
            baseURLTextField.text = baseURL
        }
        
        updateBaseURLVisibility()
    }
    
    private func updateBaseURLVisibility() {
        let isCustom = providerSegment.selectedSegmentIndex == 2
        baseURLLabel.isHidden = !isCustom
        baseURLTextField.isHidden = !isCustom
        
        if !isCustom {
            let defaultURLs = ["https://api.deepseek.com", "https://api.openai.com"]
            baseURLTextField.placeholder = defaultURLs[providerSegment.selectedSegmentIndex]
        }
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func providerChanged() {
        updateBaseURLVisibility()
    }
    
    @objc private func saveTapped() {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
            statusLabel.text = "❌ 请输入 API Key"
            statusLabel.textColor = .systemRed
            return
        }
        
        userDefaults.set(providerSegment.selectedSegmentIndex, forKey: "api_provider")
        userDefaults.set(apiKey, forKey: "api_key")
        
        if providerSegment.selectedSegmentIndex == 2 {
            guard let baseURL = baseURLTextField.text, !baseURL.isEmpty else {
                statusLabel.text = "❌ 请输入自定义 API 地址"
                statusLabel.textColor = .systemRed
                return
            }
            userDefaults.set(baseURL, forKey: "api_base_url")
        }
        
        statusLabel.text = "✅ 配置已保存"
        statusLabel.textColor = .systemGreen
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    @objc private func testTapped() {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else {
            statusLabel.text = "❌ 请先输入 API Key"
            statusLabel.textColor = .systemRed
            return
        }
        
        statusLabel.text = "⏳ 测试中..."
        statusLabel.textColor = .secondaryLabel
        
        let provider = providerSegment.selectedSegmentIndex
        var urlString = ""
        var model = ""
        
        switch provider {
        case 0: // DeepSeek
            urlString = "https://api.deepseek.com/chat/completions"
            model = "deepseek-chat"
        case 1: // OpenAI
            urlString = "https://api.openai.com/v1/chat/completions"
            model = "gpt-3.5-turbo"
        case 2: // Custom
            guard let baseURL = baseURLTextField.text, !baseURL.isEmpty else {
                statusLabel.text = "❌ 请输入自定义 API 地址"
                statusLabel.textColor = .systemRed
                return
            }
            urlString = baseURL + "/chat/completions"
            model = "gpt-3.5-turbo"
        default:
            break
        }
        
        testAPI(apiKey: apiKey, url: urlString, model: model)
    }
    
    private func testAPI(apiKey: String, url: String, model: String) {
        guard let url = URL(string: url) else {
            statusLabel.text = "❌ 无效的 URL"
            statusLabel.textColor = .systemRed
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusLabel.text = "❌ 连接失败: \(error.localizedDescription)"
                    self?.statusLabel.textColor = .systemRed
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        self?.statusLabel.text = "✅ 连接成功！"
                        self?.statusLabel.textColor = .systemGreen
                    } else if httpResponse.statusCode == 401 {
                        self?.statusLabel.text = "❌ API Key 无效"
                        self?.statusLabel.textColor = .systemRed
                    } else {
                        self?.statusLabel.text = "❌ 服务器错误: \(httpResponse.statusCode)"
                        self?.statusLabel.textColor = .systemRed
                    }
                }
            }
        }.resume()
    }
}

// MARK: - UITextFieldDelegate
extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
