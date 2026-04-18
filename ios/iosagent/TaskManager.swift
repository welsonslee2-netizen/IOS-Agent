import Foundation

// MARK: - Task Model
struct AgentTask: Identifiable {
    let id: UUID
    let title: String
    let description: String
    var status: TaskStatus
    var progress: Double
    let createdAt: Date
    var completedAt: Date?
    var result: String?
    var error: String?
    
    enum TaskStatus: String {
        case pending = "等待中"
        case running = "执行中"
        case completed = "已完成"
        case failed = "失败"
        case cancelled = "已取消"
    }
    
    init(title: String, description: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.status = .pending
        self.progress = 0
        self.createdAt = Date()
        self.completedAt = nil
        self.result = nil
        self.error = nil
    }
}

// MARK: - Task Manager
class TaskManager: ObservableObject {
    static let shared = TaskManager()
    
    @Published var tasks: [AgentTask] = []
    private var executingTasks: [UUID: Task<Void, Never>] = [:]
    private let maxConcurrentTasks = 3
    
    private init() {}
    
    // MARK: - Public Methods
    
    func createTask(title: String, description: String, action: @escaping () async throws -> String) -> AgentTask {
        var task = AgentTask(title: title, description: description)
        tasks.insert(task, at: 0)
        executeTask(&task, action: action)
        return task
    }
    
    func createMultiTask(subtasks: [(title: String, description: String)], action: @escaping (Int) async throws -> String) -> [AgentTask] {
        var createdTasks: [AgentTask] = []
        
        for (index, subtask) in subtasks.enumerated() {
            var task = AgentTask(title: subtask.title, description: subtask.description)
            tasks.insert(task, at: 0)
            createdTasks.append(task)
            executeTask(&task) {
                try await action(index)
            }
        }
        
        return createdTasks
    }
    
    func cancelTask(id: UUID) {
        executingTasks[id]?.cancel()
        executingTasks.removeValue(forKey: id)
        
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = .cancelled
        }
    }
    
    func clearCompletedTasks() {
        tasks.removeAll { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }
    }
    
    func getActiveTasks() -> [AgentTask] {
        return tasks.filter { $0.status == .running || $0.status == .pending }
    }
    
    func getCompletedTasks() -> [AgentTask] {
        return tasks.filter { $0.status == .completed || $0.status == .failed }
    }
    
    // MARK: - Private Methods
    
    private func executeTask(_ task: inout AgentTask, action: @escaping () async throws -> String) {
        let taskId = task.id
        
        // Update status to running
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                self.tasks[index].status = .running
            }
        }
        
        // Start async execution
        let swiftTask = Task {
            do {
                let result = try await action()
                
                await MainActor.run {
                    if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[index].status = .completed
                        self.tasks[index].progress = 1.0
                        self.tasks[index].result = result
                        self.tasks[index].completedAt = Date()
                    }
                }
            } catch {
                await MainActor.run {
                    if let index = self.tasks.firstIndex(where: { $0.id == taskId }) {
                        self.tasks[index].status = .failed
                        self.tasks[index].error = error.localizedDescription
                        self.tasks[index].completedAt = Date()
                    }
                }
            }
            
            self.executingTasks.removeValue(forKey: taskId)
        }
        
        executingTasks[taskId] = swiftTask
    }
    
    func updateProgress(id: UUID, progress: Double) {
        DispatchQueue.main.async {
            if let index = self.tasks.firstIndex(where: { $0.id == id }) {
                self.tasks[index].progress = progress
            }
        }
    }
}

// MARK: - Task Decomposer
class TaskDecomposer {
    static func decompose(task: String) -> [(title: String, description: String)] {
        // 简单的任务分解逻辑
        var subtasks: [(title: String, description: String)] = []
        
        // 根据关键词分解
        let keywords = ["分析", "搜索", "下载", "处理", "生成", "整理", "检查", "创建"]
        
        for keyword in keywords {
            if task.contains(keyword) {
                subtasks.append((
                    title: "\(keyword)相关任务",
                    description: "执行与\(keyword)相关的子任务"
                ))
            }
        }
        
        // 如果没有匹配，返回原任务
        if subtasks.isEmpty {
            subtasks.append((
                title: "主要任务",
                description: task
            ))
        }
        
        return subtasks
    }
}
