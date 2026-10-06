import SwiftUI

/// Sidebar, content, detail and inspector columns that reflow with the available width.
///
/// - **Wide** (iPad in landscape, a large Mac window): a `NavigationSplitView` with all three
///   columns and the inspector as a trailing column.
/// - **Medium** (iPad in portrait, a smaller window): the sidebar collapses when it does not fit and
///   the inspector becomes a sheet on iPad; on the Mac the sidebar makes room for it instead.
/// - **Compact** (Slide Over, narrow split screen, iPhone): a `NavigationStack` with the sidebar at
///   its root, driven by the same ``AdaptiveSelection``, so the user stays on the same task.
///
/// The detail column gets an inspector button (⌥⌘I) and the content column a sidebar button (⌥⌘S).
///
/// ```swift
/// @SceneStorage("selection") private var selection = AdaptiveSelection<Project.ID, Task.ID>()
/// @SceneStorage("columns") private var columns = AdaptiveColumnState()
///
/// AdaptiveStack(selection: $selection, columns: $columns) {
///     ProjectList(selection: $selection.sidebar)
/// } content: {
///     TaskList(project: selection.sidebar, selection: $selection.item)
/// } detail: {
///     TaskDetail(task: selection.item)
/// } inspector: {
///     TaskInspector(task: selection.item)
/// }
/// ```
public struct AdaptiveStack<SidebarID, ItemID, Sidebar: View, Content: View, Detail: View, Inspector: View>: View
where SidebarID: Hashable & Codable & Sendable, ItemID: Hashable & Codable & Sendable {
    @Binding private var selection: AdaptiveSelection<SidebarID, ItemID>
    private let externalColumns: Binding<AdaptiveColumnState>?
    @State private var localColumns = AdaptiveColumnState()
    private let policy: AdaptiveLayoutPolicy
    private let hasInspector: Bool
    private let sidebar: Sidebar
    private let content: Content
    private let detail: Detail
    private let inspector: Inspector

    /// Creates the stack.
    ///
    /// - Parameters:
    ///   - selection: The sidebar and content selection. The compact navigation stack is derived from it.
    ///   - columns: The sidebar visibility and inspector state, for example from `@SceneStorage`.
    ///     When `nil` the stack keeps it itself, starting with an automatic sidebar and no inspector.
    ///   - policy: Column widths and the inspector fallback.
    ///   - sidebar: The leading column, usually a `List(selection: $selection.sidebar)`.
    ///   - content: The middle column, usually a `List(selection: $selection.item)`.
    ///   - detail: The main column for the selected item.
    ///   - inspector: The trailing column with details about the selected item.
    public init(
        selection: Binding<AdaptiveSelection<SidebarID, ItemID>>,
        columns: Binding<AdaptiveColumnState>? = nil,
        policy: AdaptiveLayoutPolicy = AdaptiveLayoutPolicy(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail,
        @ViewBuilder inspector: () -> Inspector
    ) {
        _selection = selection
        externalColumns = columns
        self.policy = policy
        hasInspector = true
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.inspector = inspector()
    }

    public var body: some View {
        let columns = externalColumns ?? $localColumns
        AdaptiveLayoutReader(
            policy: policy,
            columns: columns.wrappedValue,
            compactColumn: selection.compactColumn
        ) { layout in
            if layout.isCollapsed {
                compactStack(layout: layout, columns: columns)
            } else {
                splitView(layout: layout, columns: columns)
            }
        }
    }

    // MARK: - Split view

    private func splitView(layout: AdaptiveLayout, columns: Binding<AdaptiveColumnState>) -> some View {
        let visibility = Binding<NavigationSplitViewVisibility>(
            get: { layout.columnVisibility.splitViewVisibility },
            set: { newValue in
                // The split view writes back what it shows; only a real change becomes a choice,
                // so an automatic sidebar stays automatic.
                let resolved = AdaptiveColumnVisibility(newValue)
                if resolved != layout.columnVisibility {
                    columns.wrappedValue.columnVisibility = resolved
                }
            }
        )

        return NavigationSplitView(columnVisibility: visibility) {
            sidebar
                .navigationSplitViewColumnWidth(
                    min: policy.sidebarWidth.minimum,
                    ideal: policy.sidebarWidth.ideal,
                    max: policy.sidebarWidth.maximum
                )
                .toolbar(removing: .sidebarToggle)
        } content: {
            content
                .navigationSplitViewColumnWidth(
                    min: policy.contentWidth.minimum,
                    ideal: policy.contentWidth.ideal,
                    max: policy.contentWidth.maximum
                )
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        SidebarToggleButton(isVisible: layout.isSidebarVisible) {
                            withAnimation {
                                columns.wrappedValue.toggleSidebar(in: layout)
                            }
                        }
                    }
                }
        } detail: {
            detail
                .toolbar {
                    if hasInspector {
                        ToolbarItem(placement: .primaryAction) {
                            inspectorToggle(columns: columns)
                        }
                    }
                }
                .adaptiveInspector(
                    isPresented: inspectorBinding(columns),
                    style: layout.inspectorStyle,
                    width: policy.inspectorWidth
                ) {
                    inspector
                }
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Compact stack

    private func compactStack(layout: AdaptiveLayout, columns: Binding<AdaptiveColumnState>) -> some View {
        let selection = $selection
        let path = Binding<[AdaptiveColumn]>(
            get: { selection.wrappedValue.compactPath },
            set: { newPath in
                var updated = selection.wrappedValue
                updated.applyCompactPath(newPath)
                if updated != selection.wrappedValue {
                    selection.wrappedValue = updated
                }
            }
        )

        return NavigationStack(path: path) {
            sidebar
                .navigationDestination(for: AdaptiveColumn.self) { column in
                    compactDestination(column, columns: columns)
                }
        }
        .adaptiveInspector(isPresented: inspectorBinding(columns), style: .sheet, width: policy.inspectorWidth) {
            inspector
        }
    }

    @ViewBuilder
    private func compactDestination(_ column: AdaptiveColumn, columns: Binding<AdaptiveColumnState>) -> some View {
        switch column {
        case .sidebar:
            sidebar
        case .content:
            content
        case .detail, .inspector:
            detail
                .toolbar {
                    if hasInspector {
                        ToolbarItem(placement: .primaryAction) {
                            inspectorToggle(columns: columns)
                        }
                    }
                }
        }
    }

    // MARK: - Inspector

    private func inspectorBinding(_ columns: Binding<AdaptiveColumnState>) -> Binding<Bool> {
        hasInspector ? columns.isInspectorPresented : .constant(false)
    }

    private func inspectorToggle(columns: Binding<AdaptiveColumnState>) -> some View {
        InspectorToggleButton(isPresented: columns.wrappedValue.isInspectorPresented) {
            withAnimation {
                columns.wrappedValue.toggleInspector()
            }
        }
    }
}

extension AdaptiveStack where Inspector == EmptyView {
    /// Creates the stack without an inspector: sidebar, content and detail only.
    public init(
        selection: Binding<AdaptiveSelection<SidebarID, ItemID>>,
        columns: Binding<AdaptiveColumnState>? = nil,
        policy: AdaptiveLayoutPolicy = AdaptiveLayoutPolicy(),
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        _selection = selection
        externalColumns = columns
        self.policy = policy
        hasInspector = false
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.inspector = EmptyView()
    }
}
