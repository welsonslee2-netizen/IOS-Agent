import Foundation

// MARK: - Skill Model
struct Skill: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let author: String
    let version: String
    let icon: String
    let category: SkillCategory
    let installScript: String
    let isInstalled: Bool
    
    enum SkillCategory: String, Codable, CaseIterable {
        case development = "开发"
        case data = "数据"
        case automation = "自动化"
        case ai = "AI"
        case utility = "工具"
    }
}

// MARK: - Skill Manager
class SkillManager {
    static let shared = SkillManager()
    private let userDefaults = UserDefaults.standard
    private var installedSkills: [String: Skill] = [:]
    
    // 预置的 Skills 商店
    lazy var availableSkills: [Skill] = [
        Skill(
            id: "code-runner",
            name: "代码执行器",
            description: "在 iOS 上执行 Python/JavaScript/Shell 代码",
            author: "iOS Agent",
            version: "1.0.0",
            icon: "play.circle.fill",
            category: .development,
            installScript: "",
            isInstalled: true
        ),
        Skill(
            id: "file-manager",
            name: "文件管理器",
            description: "读取、写入、浏览 iOS 文件系统",
            author: "iOS Agent",
            version: "1.0.0",
            icon: "folder.fill",
            category: .utility,
            installScript: "",
            isInstalled: true
        ),
        Skill(
            id: "web-search",
            name: "网络搜索",
            description: "搜索网页、新闻、图片等内容",
            author: "iOS Agent",
            version: "1.0.0",
            icon: "magnifyingglass",
            category: .utility,
            installScript: "",
            isInstalled: true
        ),
        Skill(
            id: "code-generator",
            name: "代码生成器",
            description: "AI 辅助生成 Python/Swift/JS 代码",
            author: "iOS Agent",
            version: "1.0.0",
            icon: "wand.and.stars",
            category: .ai,
            installScript: "",
            isInstalled: true
        ),
        Skill(
            id: "task-planner",
            name: "任务规划师",
            description: "分解复杂任务为可执行步骤，支持多任务并行",
            author: "iOS Agent",
            version: "1.0.0",
            icon: "checklist",
            category: .automation,
            installScript: "",
            isInstalled: true
        ),
        Skill(
            id: "data-analysis",
            name: "数据分析",
            description: "处理 CSV/JSON 数据，生成图表和报告",
            author: "Community",
            version: "1.2.0",
            icon: "chart.bar.fill",
            category: .data,
            installScript: "pip install pandas matplotlib",
            isInstalled: false
        ),
        Skill(
            id: "image-processor",
            name: "图片处理",
            description: "图片压缩、格式转换、裁剪、滤镜",
            author: "Community",
            version: "2.0.0",
            icon: "photo.fill",
            category: .utility,
            installScript: "pip install pillow",
            isInstalled: false
        ),
        Skill(
            id: "api-tester",
            name: "API 测试器",
            description: "测试 REST API，查看响应和状态码",
            author: "Community",
            version: "1.5.0",
            icon: "network",
            category: .development,
            installScript: "",
            isInstalled: false
        ),
        Skill(
            id: "git-assistant",
            name: "Git 助手",
            description: "Git 命令执行，版本控制辅助",
            author: "Community",
            version: "1.1.0",
            icon: "arrow.triangle.branch",
            category: .development,
            installScript: "",
            isInstalled: false
        ),
        Skill(
            id: "regex-tester",
            name: "正则表达式",
            description: "实时测试和调试正则表达式",
            author: "Community",
            version: "1.0.0",
            icon: "textformat.abc",
            category: .development,
            installScript: "",
            isInstalled: false
        )
    ]
    
    private init() {
        loadInstalledSkills()
    }
    
    private func loadInstalledSkills() {
        if let data = userDefaults.data(forKey: "installed_skills"),
           let skills = try? JSONDecoder().decode([String: Skill].self, from: data) {
            installedSkills = skills
        }
    }
    
    private func saveInstalledSkills() {
        if let data = try? JSONEncoder().encode(installedSkills) {
            userDefaults.set(data, forKey: "installed_skills")
        }
    }
    
    func getInstalledSkills() -> [Skill] {
        return Array(installedSkills.values)
    }
    
    func isInstalled(skillId: String) -> Bool {
        return installedSkills[skillId] != nil
    }
    
    func installSkill(_ skill: Skill) -> Bool {
        installedSkills[skill.id] = skill
        saveInstalledSkills()
        return true
    }
    
    func uninstallSkill(skillId: String) {
        installedSkills.removeValue(forKey: skillId)
        saveInstalledSkills()
    }
    
    func searchSkills(query: String) -> [Skill] {
        let lowercased = query.lowercased()
        return availableSkills.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.description.lowercased().contains(lowercased) ||
            $0.category.rawValue.lowercased().contains(lowercased)
        }
    }
}
