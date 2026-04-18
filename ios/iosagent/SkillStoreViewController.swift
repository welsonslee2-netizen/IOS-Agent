import UIKit

class SkillStoreViewController: UIViewController {
    // MARK: - Properties
    private let skillManager = SkillManager.shared
    private var skills: [Skill] = []
    private var filteredSkills: [Skill] = []
    private var selectedCategory: Skill.SkillCategory?
    
    // MARK: - UI Components
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.placeholder = "搜索 Skills..."
        sb.searchBarStyle = .minimal
        sb.delegate = self
        return sb
    }()
    
    private lazy var categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()
    
    private lazy var categoryStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        return stack
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(SkillCell.self, forCellReuseIdentifier: "SkillCell")
        tv.dataSource = self
        tv.delegate = self
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategories()
        loadSkills()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Skill 商店"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        view.addSubview(searchBar)
        view.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStack)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            categoryScrollView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            categoryScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            categoryStack.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 16),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -16),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor),
            categoryStack.heightAnchor.constraint(equalTo: categoryScrollView.heightAnchor),
            
            tableView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupCategories() {
        // 添加"全部"按钮
        let allButton = createCategoryButton(title: "全部", category: nil)
        categoryStack.addArrangedSubview(allButton)
        
        // 添加分类按钮
        for category in Skill.SkillCategory.allCases {
            let button = createCategoryButton(title: category.rawValue, category: category)
            categoryStack.addArrangedSubview(button)
        }
    }
    
    private func createCategoryButton(title: String, category: Skill.SkillCategory?) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.layer.cornerRadius = 16
        button.tag = category?.hashValue ?? -1
        button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        
        updateCategoryButtonStyle(button, isSelected: category == nil && selectedCategory == nil)
        
        return button
    }
    
    private func updateCategoryButtonStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .secondarySystemBackground
            button.setTitleColor(.label, for: .normal)
        }
    }
    
    private func loadSkills() {
        skills = skillManager.availableSkills
        filterSkills()
    }
    
    private func filterSkills() {
        if let category = selectedCategory {
            filteredSkills = skills.filter { $0.category == category }
        } else {
            filteredSkills = skills
        }
        
        if let query = searchBar.text, !query.isEmpty {
            filteredSkills = filteredSkills.filter {
                $0.name.lowercased().contains(query.lowercased()) ||
                $0.description.lowercased().contains(query.lowercased())
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func categoryTapped(_ sender: UIButton) {
        // Reset all buttons
        for case let button as UIButton in categoryStack.arrangedSubviews {
            let cat: Skill.SkillCategory? = button.tag == -1 ? nil : Skill.SkillCategory.allCases.first { $0.hashValue == button.tag }
            updateCategoryButtonStyle(button, isSelected: cat == nil && sender.tag == -1)
        }
        
        if sender.tag == -1 {
            selectedCategory = nil
        } else {
            selectedCategory = Skill.SkillCategory.allCases.first { $0.hashValue == sender.tag }
        }
        
        filterSkills()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SkillStoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSkills.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SkillCell", for: indexPath) as! SkillCell
        let skill = filteredSkills[indexPath.row]
        cell.configure(with: skill, isInstalled: skillManager.isInstalled(skillId: skill.id))
        cell.onInstallTapped = { [weak self] in
            self?.installSkill(at: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func installSkill(at indexPath: IndexPath) {
        let skill = filteredSkills[indexPath.row]
        
        let alert = UIAlertController(
            title: "安装 Skill",
            message: "确定要安装「\(skill.name)」吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "安装", style: .default) { [weak self] _ in
            _ = self?.skillManager.installSkill(skill)
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            
            // Show success
            let successAlert = UIAlertController(
                title: "✅ 安装成功",
                message: "「\(skill.name)」已安装",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "确定", style: .default))
            self?.present(successAlert, animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SkillStoreViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterSkills()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Skill Cell
class SkillCell: UITableViewCell {
    var onInstallTapped: (() -> Void)?
    
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        return iv
    }()
    
    private lazy var nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        return l
    }()
    
    private lazy var descLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()
    
    private lazy var categoryBadge: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 11)
        l.textColor = .white
        l.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
        l.layer.cornerRadius = 8
        l.clipsToBounds = true
        l.textAlignment = .center
        return l
    }()
    
    private lazy var installButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.addTarget(self, action: #selector(installTapped), for: .touchUpInside)
        return btn
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(categoryBadge)
        contentView.addSubview(installButton)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: installButton.leadingAnchor, constant: -8),
            
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            categoryBadge.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 4),
            categoryBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryBadge.heightAnchor.constraint(equalToConstant: 18),
            
            installButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            installButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            installButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    func configure(with skill: Skill, isInstalled: Bool) {
        iconImageView.image = UIImage(systemName: skill.icon)
        nameLabel.text = skill.name
        descLabel.text = skill.description
        categoryBadge.text = "  \(skill.category.rawValue)  "
        
        if isInstalled {
            installButton.setTitle("已安装", for: .normal)
            installButton.setTitleColor(.systemGreen, for: .normal)
            installButton.isEnabled = false
        } else {
            installButton.setTitle("安装", for: .normal)
            installButton.setTitleColor(UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0), for: .normal)
            installButton.isEnabled = true
        }
    }
    
    @objc private func installTapped() {
        onInstallTapped?()
    }
}
