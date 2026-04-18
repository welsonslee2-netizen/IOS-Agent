import UIKit

class TaskListViewController: UIViewController {
    // MARK: - Properties
    private let taskManager = TaskManager.shared
    
    // MARK: - UI Components
    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["进行中", "已完成"])
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.selectedSegmentIndex = 0
        sc.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return sc
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(TaskCell.self, forCellReuseIdentifier: "TaskCell")
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()
    
    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "暂无任务"
        l.textColor = .tertiaryLabel
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()
    
    private lazy var clearButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "清空", style: .plain, target: self, action: #selector(clearTapped))
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadTasks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTasks()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "任务列表"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        navigationItem.rightBarButtonItem = clearButton
        
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    private func loadTasks() {
        tableView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        let tasks = segmentedControl.selectedSegmentIndex == 0
            ? taskManager.getActiveTasks()
            : taskManager.getCompletedTasks()
        
        emptyLabel.isHidden = !tasks.isEmpty
        tableView.isHidden = tasks.isEmpty
        clearButton.isEnabled = segmentedControl.selectedSegmentIndex == 1 && !tasks.isEmpty
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func segmentChanged() {
        loadTasks()
    }
    
    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "清空已完成任务",
            message: "确定要清空所有已完成的任务吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            self?.taskManager.clearCompletedTasks()
            self?.loadTasks()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return segmentedControl.selectedSegmentIndex == 0
            ? taskManager.getActiveTasks().count
            : taskManager.getCompletedTasks().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let tasks = segmentedControl.selectedSegmentIndex == 0
            ? taskManager.getActiveTasks()
            : taskManager.getCompletedTasks()
        
        if indexPath.row < tasks.count {
            cell.configure(with: tasks[indexPath.row])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tasks = segmentedControl.selectedSegmentIndex == 0
            ? taskManager.getActiveTasks()
            : taskManager.getCompletedTasks()
        
        guard indexPath.row < tasks.count else { return }
        let task = tasks[indexPath.row]
        
        // Show task details
        var message = task.description
        if let result = task.result {
            message += "\n\n结果:\n\(result.prefix(200))..."
        }
        if let error = task.error {
            message += "\n\n错误:\n\(error)"
        }
        
        let alert = UIAlertController(title: task.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        if task.status == .running {
            alert.addAction(UIAlertAction(title: "取消任务", style: .destructive) { [weak self] _ in
                self?.taskManager.cancelTask(id: task.id)
                self?.loadTasks()
            })
        }
        
        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let tasks = segmentedControl.selectedSegmentIndex == 0
            ? taskManager.getActiveTasks()
            : taskManager.getCompletedTasks()
        
        guard indexPath.row < tasks.count else { return nil }
        let task = tasks[indexPath.row]
        
        var actions: [UIContextualAction] = []
        
        if task.status == .running {
            let cancelAction = UIContextualAction(style: .destructive, title: "取消") { [weak self] _, _, completion in
                self?.taskManager.cancelTask(id: task.id)
                self?.loadTasks()
                completion(true)
            }
            cancelAction.backgroundColor = .systemRed
            actions.append(cancelAction)
        }
        
        return UISwipeActionsConfiguration(actions: actions)
    }
}

// MARK: - Task Cell
class TaskCell: UITableViewCell {
    private lazy var iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()
    
    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13)
        return l
    }()
    
    private lazy var progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private lazy var timeLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
        return l
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
        ])
    }
    
    func configure(with task: AgentTask) {
        titleLabel.text = task.title
        statusLabel.text = task.status.rawValue
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: task.createdAt)
        
        switch task.status {
        case .pending:
            iconView.image = UIImage(systemName: "clock")
            iconView.tintColor = .systemGray
            statusLabel.textColor = .secondaryLabel
            progressView.isHidden = true
            
        case .running:
            iconView.image = UIImage(systemName: "arrow.triangle.2.circlepath")
            iconView.tintColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
            statusLabel.textColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
            progressView.isHidden = false
            progressView.progress = Float(task.progress)
            
        case .completed:
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .systemGreen
            statusLabel.textColor = .systemGreen
            progressView.isHidden = true
            
        case .failed:
            iconView.image = UIImage(systemName: "xmark.circle.fill")
            iconView.tintColor = .systemRed
            statusLabel.textColor = .systemRed
            progressView.isHidden = true
            
        case .cancelled:
            iconView.image = UIImage(systemName: "minus.circle.fill")
            iconView.tintColor = .systemGray
            statusLabel.textColor = .secondaryLabel
            progressView.isHidden = true
        }
    }
}
