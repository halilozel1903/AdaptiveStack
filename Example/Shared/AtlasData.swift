import SwiftUI

/// Atlas, a made-up project tracker: projects, their tasks and the people working on them.
/// Fixed data, so every launch and every screenshot looks the same.
struct Person: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let role: String
    let color: Color

    var initials: String {
        name.split(separator: " ").compactMap(\.first).prefix(2).map { String($0) }.joined()
    }
}

struct Project: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    let summary: String
}

enum TaskStatus: String, CaseIterable, Identifiable, Sendable {
    case inProgress
    case inReview
    case todo
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inProgress: "In Progress"
        case .inReview: "In Review"
        case .todo: "To Do"
        case .done: "Done"
        }
    }

    var symbol: String {
        switch self {
        case .inProgress: "circle.lefthalf.filled"
        case .inReview: "eye.circle"
        case .todo: "circle"
        case .done: "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .inProgress: .orange
        case .inReview: .purple
        case .todo: .secondary
        case .done: .green
        }
    }
}

enum TaskPriority: String, CaseIterable, Sendable {
    case urgent
    case high
    case medium
    case low

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .urgent: "exclamationmark.triangle.fill"
        case .high: "chevron.up.2"
        case .medium: "equal"
        case .low: "chevron.down"
        }
    }

    var color: Color {
        switch self {
        case .urgent: .red
        case .high: .orange
        case .medium: .blue
        case .low: .gray
        }
    }
}

struct ChecklistItem: Hashable, Sendable {
    let title: String
    let isDone: Bool
}

struct ActivityItem: Hashable, Sendable {
    let personID: String
    let text: String
    let time: String
}

struct AtlasTask: Identifiable, Hashable, Sendable {
    let id: String
    let projectID: String
    let title: String
    let status: TaskStatus
    let priority: TaskPriority
    let assigneeID: String
    let due: String
    let estimate: String
    let sprint: String
    let labels: [String]
    let summary: String
    let checklist: [ChecklistItem]
    let activity: [ActivityItem]

    init(
        _ id: String,
        project: String,
        _ title: String,
        status: TaskStatus,
        priority: TaskPriority,
        assignee: String,
        due: String,
        estimate: String,
        sprint: String = "Sprint 41",
        labels: [String] = [],
        summary: String = "",
        checklist: [ChecklistItem] = [],
        activity: [ActivityItem] = []
    ) {
        self.id = id
        self.projectID = project
        self.title = title
        self.status = status
        self.priority = priority
        self.assigneeID = assignee
        self.due = due
        self.estimate = estimate
        self.sprint = sprint
        self.labels = labels
        self.summary = summary
        self.checklist = checklist
        self.activity = activity
    }

    var checklistProgress: String {
        "\(checklist.filter(\.isDone).count) of \(checklist.count)"
    }
}

enum AtlasData {
    static let screenshotProjectID = "ipad"
    static let screenshotTaskID = "ATL-142"

    static let people: [Person] = [
        Person(id: "maya", name: "Maya Chen", role: "iOS Engineer", color: .pink),
        Person(id: "omar", name: "Omar Haddad", role: "Designer", color: .indigo),
        Person(id: "lena", name: "Lena Vogel", role: "Mac Engineer", color: .teal),
        Person(id: "sam", name: "Sam Okafor", role: "Product Lead", color: .orange),
        Person(id: "ines", name: "Inês Costa", role: "Backend Engineer", color: .green),
    ]

    static let projects: [Project] = [
        Project(id: "ipad", name: "Atlas for iPad", symbol: "ipad.landscape", color: .blue,
                summary: "Multi-column layout, Stage Manager and keyboard support."),
        Project(id: "mac", name: "Atlas for Mac", symbol: "macbook", color: .indigo,
                summary: "A native Mac app with menus, windows and an inspector."),
        Project(id: "sync", name: "Sync Engine", symbol: "arrow.triangle.2.circlepath", color: .green,
                summary: "Offline edits that merge cleanly on every device."),
        Project(id: "design", name: "Design System", symbol: "paintpalette", color: .pink,
                summary: "Colors, type and components shared by every app."),
        Project(id: "launch", name: "Fall Launch", symbol: "megaphone", color: .orange,
                summary: "Website, press kit and the App Store page."),
    ]

    static let tasks: [AtlasTask] = [
        AtlasTask(
            "ATL-142", project: "ipad", "Restore column layout per window",
            status: .inProgress, priority: .high, assignee: "maya", due: "Oct 14", estimate: "5 pts",
            labels: ["Layout", "iPadOS 26"],
            summary: "Every window should come back with the sidebar, inspector and selection it had. Save the column state in SceneStorage and the selection next to it, so a second window keeps its own layout.",
            checklist: [
                ChecklistItem(title: "Save selection with SceneStorage", isDone: true),
                ChecklistItem(title: "Save sidebar and inspector visibility", isDone: true),
                ChecklistItem(title: "Restore after a relaunch", isDone: false),
                ChecklistItem(title: "Test two windows side by side", isDone: false),
            ],
            activity: [
                ActivityItem(personID: "omar", text: "attached the window restoration mockups", time: "2h"),
                ActivityItem(personID: "maya", text: "moved the task to In Progress", time: "Yesterday"),
                ActivityItem(personID: "sam", text: "set the priority to High", time: "Mon"),
            ]
        ),
        AtlasTask(
            "ATL-139", project: "ipad", "Inspector as a sheet in portrait",
            status: .inProgress, priority: .medium, assignee: "omar", due: "Oct 16", estimate: "3 pts",
            labels: ["Layout"],
            summary: "When the inspector does not fit next to the detail, present it as a sheet instead of squeezing the task.",
            checklist: [ChecklistItem(title: "Sheet with a Done button", isDone: true)]
        ),
        AtlasTask(
            "ATL-137", project: "ipad", "Keyboard shortcuts for every column",
            status: .inReview, priority: .medium, assignee: "lena", due: "Oct 12", estimate: "2 pts",
            labels: ["Keyboard"],
            summary: "Option-Command-S toggles the sidebar and Option-Command-I the inspector."
        ),
        AtlasTask(
            "ATL-145", project: "ipad", "Slide Over keeps the open task",
            status: .todo, priority: .urgent, assignee: "maya", due: "Oct 18", estimate: "3 pts",
            labels: ["Layout", "Bug"],
            summary: "Collapsing into a navigation stack must keep the project and task that were selected."
        ),
        AtlasTask(
            "ATL-148", project: "ipad", "Drag tasks between projects",
            status: .todo, priority: .low, assignee: "omar", due: "Oct 24", estimate: "8 pts",
            labels: ["Drag and Drop"]
        ),
        AtlasTask(
            "ATL-151", project: "ipad", "Pointer hover effects on rows",
            status: .todo, priority: .low, assignee: "lena", due: "Oct 28", estimate: "1 pt"
        ),
        AtlasTask(
            "ATL-128", project: "ipad", "Sidebar badges for open tasks",
            status: .done, priority: .medium, assignee: "maya", due: "Oct 3", estimate: "1 pt"
        ),
        AtlasTask(
            "ATL-121", project: "ipad", "Empty states for every column",
            status: .done, priority: .low, assignee: "omar", due: "Sep 30", estimate: "2 pts"
        ),

        AtlasTask("ATL-201", project: "mac", "Toolbar with inspector toggle", status: .inProgress, priority: .high,
                  assignee: "lena", due: "Oct 15", estimate: "3 pts", labels: ["macOS"]),
        AtlasTask("ATL-204", project: "mac", "Open tasks in new windows", status: .todo, priority: .medium,
                  assignee: "lena", due: "Oct 22", estimate: "5 pts", labels: ["macOS"]),
        AtlasTask("ATL-198", project: "mac", "Menu bar commands", status: .done, priority: .medium,
                  assignee: "sam", due: "Oct 2", estimate: "2 pts"),

        AtlasTask("ATL-310", project: "sync", "Conflict-free task ordering", status: .inProgress, priority: .urgent,
                  assignee: "ines", due: "Oct 13", estimate: "8 pts", labels: ["Sync"]),
        AtlasTask("ATL-312", project: "sync", "Background refresh budget", status: .inReview, priority: .high,
                  assignee: "ines", due: "Oct 17", estimate: "3 pts"),
        AtlasTask("ATL-305", project: "sync", "Retry with exponential backoff", status: .done, priority: .medium,
                  assignee: "ines", due: "Oct 1", estimate: "2 pts"),

        AtlasTask("ATL-402", project: "design", "Status colors for dark mode", status: .todo, priority: .medium,
                  assignee: "omar", due: "Oct 20", estimate: "2 pts", labels: ["Design"]),
        AtlasTask("ATL-399", project: "design", "Avatar component", status: .done, priority: .low,
                  assignee: "omar", due: "Sep 29", estimate: "1 pt"),

        AtlasTask("ATL-501", project: "launch", "App Store screenshots", status: .todo, priority: .high,
                  assignee: "sam", due: "Oct 25", estimate: "3 pts", labels: ["Marketing"]),
        AtlasTask("ATL-498", project: "launch", "Press kit", status: .inProgress, priority: .medium,
                  assignee: "sam", due: "Oct 19", estimate: "2 pts", labels: ["Marketing"]),
    ]

    static func project(_ id: Project.ID?) -> Project? {
        guard let id else { return nil }
        return projects.first { $0.id == id }
    }

    static func task(_ id: AtlasTask.ID?) -> AtlasTask? {
        guard let id else { return nil }
        return tasks.first { $0.id == id }
    }

    static func person(_ id: Person.ID) -> Person? {
        people.first { $0.id == id }
    }

    static func tasks(in projectID: Project.ID, status: TaskStatus) -> [AtlasTask] {
        tasks.filter { $0.projectID == projectID && $0.status == status }
    }

    static func openTaskCount(in projectID: Project.ID) -> Int {
        tasks.filter { $0.projectID == projectID && $0.status != .done }.count
    }
}
