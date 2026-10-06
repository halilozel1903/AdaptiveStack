import AdaptiveStack
import SwiftUI

/// The whole app: projects, tasks, the open task and its inspector in one `AdaptiveStack`.
struct AtlasRootView: View {
    @Binding var selection: AdaptiveSelection<Project.ID, AtlasTask.ID>
    @Binding var columns: AdaptiveColumnState

    var body: some View {
        AdaptiveStack(selection: $selection, columns: $columns) {
            ProjectSidebar(selection: $selection.sidebar)
        } content: {
            TaskList(project: AtlasData.project(selection.sidebar), selection: $selection.item)
        } detail: {
            TaskDetail(task: AtlasData.task(selection.item))
        } inspector: {
            TaskInspector(task: AtlasData.task(selection.item))
        }
    }
}

/// A regular launch: the selection and the columns are restored per window.
struct AtlasSceneView: View {
    @SceneStorage("atlas.selection") private var selection = AdaptiveSelection<Project.ID, AtlasTask.ID>(
        sidebar: AtlasData.screenshotProjectID,
        item: AtlasData.screenshotTaskID
    )
    @SceneStorage("atlas.columns") private var columns = AdaptiveColumnState(isInspectorPresented: true)

    var body: some View {
        AtlasRootView(selection: $selection, columns: $columns)
    }
}

// MARK: - Sidebar

struct ProjectSidebar: View {
    @Binding var selection: Project.ID?

    var body: some View {
        List(selection: $selection) {
            Section("Projects") {
                ForEach(AtlasData.projects) { project in
                    Label {
                        Text(project.name)
                    } icon: {
                        Image(systemName: project.symbol)
                            .foregroundStyle(project.color)
                    }
                    .badge(AtlasData.openTaskCount(in: project.id))
                    .tag(project.id)
                }
            }

            Section("Team") {
                ForEach(AtlasData.people) { person in
                    Label {
                        Text(person.name)
                    } icon: {
                        Avatar(person: person, size: 20)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Atlas")
    }
}

// MARK: - Task list

struct TaskList: View {
    let project: Project?
    @Binding var selection: AtlasTask.ID?

    var body: some View {
        if let project {
            List(selection: $selection) {
                ForEach(TaskStatus.allCases) { status in
                    let tasks = AtlasData.tasks(in: project.id, status: status)
                    if !tasks.isEmpty {
                        Section(status.title) {
                            ForEach(tasks) { task in
                                TaskRow(task: task)
                                    .tag(task.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Task", systemImage: "plus") {}
                }
            }
        } else {
            ContentUnavailableView(
                "No Project Selected",
                systemImage: "folder",
                description: Text("Choose a project in the sidebar.")
            )
        }
    }
}

struct TaskRow: View {
    let task: AtlasTask

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.status.symbol)
                .foregroundStyle(task.status.color)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(task.id)
                        .monospacedDigit()
                    Text("·")
                    Text(task.due)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: task.priority.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(task.priority.color)

            if let person = AtlasData.person(task.assigneeID) {
                Avatar(person: person, size: 22)
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Detail

struct TaskDetail: View {
    let task: AtlasTask?

    var body: some View {
        if let task {
            TaskDetailContent(task: task)
        } else {
            ContentUnavailableView(
                "No Task Selected",
                systemImage: "checklist",
                description: Text("Choose a task to see its details.")
            )
        }
    }
}

private struct TaskDetailContent: View {
    let task: AtlasTask

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if !task.summary.isEmpty {
                    Text(task.summary)
                        .font(.body)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !task.checklist.isEmpty {
                    DetailCard(title: "Checklist", trailing: task.checklistProgress) {
                        ForEach(task.checklist, id: \.title) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isDone ? Color.green : Color.secondary)
                                Text(item.title)
                                    .strikethrough(item.isDone, color: .secondary)
                                    .foregroundStyle(item.isDone ? Color.secondary : Color.primary)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                if !task.activity.isEmpty {
                    DetailCard(title: "Activity", trailing: nil) {
                        ForEach(task.activity, id: \.self) { activity in
                            if let person = AtlasData.person(activity.personID) {
                                HStack(alignment: .top, spacing: 10) {
                                    Avatar(person: person, size: 24)
                                    Text("\(Text(person.name).bold()) \(activity.text)")
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 8)
                                    Text(activity.time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                LayoutBadge()
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(task.id)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let project = AtlasData.project(task.projectID) {
                Label(project.name, systemImage: project.symbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(project.color)
            }
            Text(task.title)
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Chip(title: task.status.title, symbol: task.status.symbol, color: task.status.color)
                Chip(title: task.priority.title, symbol: task.priority.symbol, color: task.priority.color)
                Chip(title: task.due, symbol: "calendar", color: .blue)
            }
        }
    }
}

private struct DetailCard<Content: View>: View {
    let title: String
    let trailing: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content
        }
        .padding(16)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Reads the layout `AdaptiveStack` puts in the environment.
private struct LayoutBadge: View {
    @Environment(\.adaptiveLayout) private var layout

    var body: some View {
        if let layout {
            Label(Self.describe(layout), systemImage: "rectangle.split.3x1")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    static func describe(_ layout: AdaptiveLayout) -> String {
        let count = layout.visibleColumns.count
        var text = "\(layout.mode.rawValue.capitalized) layout · \(count) \(count == 1 ? "column" : "columns")"
        if layout.showsInspectorSheet {
            text += " · inspector as a sheet"
        }
        return text
    }
}

// MARK: - Inspector

struct TaskInspector: View {
    let task: AtlasTask?

    var body: some View {
        Group {
            if let task {
                form(for: task)
            } else {
                ContentUnavailableView("No Selection", systemImage: "info.circle")
            }
        }
        .navigationTitle("Details")
    }

    private func form(for task: AtlasTask) -> some View {
        Form {
            Section("Status") {
                LabeledContent("Status") {
                    Label(task.status.title, systemImage: task.status.symbol)
                        .foregroundStyle(task.status.color)
                }
                LabeledContent("Priority") {
                    Label(task.priority.title, systemImage: task.priority.symbol)
                        .foregroundStyle(task.priority.color)
                }
                if !task.checklist.isEmpty {
                    LabeledContent("Checklist", value: task.checklistProgress)
                }
            }

            Section("Details") {
                if let person = AtlasData.person(task.assigneeID) {
                    LabeledContent("Assignee") {
                        HStack(spacing: 6) {
                            Avatar(person: person, size: 20)
                            Text(person.name)
                        }
                    }
                }
                LabeledContent("Due", value: task.due)
                LabeledContent("Estimate", value: task.estimate)
                LabeledContent("Sprint", value: task.sprint)
            }

            if !task.labels.isEmpty {
                Section("Labels") {
                    ForEach(task.labels, id: \.self) { label in
                        Label(label, systemImage: "tag")
                    }
                }
            }

            if let project = AtlasData.project(task.projectID) {
                Section("Project") {
                    Label {
                        Text(project.name)
                    } icon: {
                        Image(systemName: project.symbol)
                            .foregroundStyle(project.color)
                    }
                    Text(project.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Components

struct Avatar: View {
    let person: Person
    var size: CGFloat = 24

    var body: some View {
        Text(person.initials)
            .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(person.color.gradient, in: Circle())
            .accessibilityLabel(person.name)
    }
}

struct Chip: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.13), in: Capsule())
    }
}
