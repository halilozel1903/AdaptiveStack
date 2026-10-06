import Foundation

/// The result of the layout policy: which columns are on screen and how the inspector is shown.
///
/// `AdaptiveStack` computes one for its current size and passes it to its columns in the
/// environment; read it with `@Environment(\.adaptiveLayout)` or `AdaptiveLayoutReader`.
public struct AdaptiveLayout: Hashable, Sendable {
    /// Compact (one column at a time), medium or wide.
    public var mode: AdaptiveLayoutMode
    /// The container width the layout was computed for.
    public var width: CGFloat
    /// The columns on screen, from leading to trailing. A compact layout has exactly one: the top
    /// of the navigation stack. The inspector is listed only while it is shown as a column.
    public var visibleColumns: [AdaptiveColumn]
    /// The resolved split view visibility: `.all`, `.doubleColumn` or `.detailOnly`, never
    /// `.automatic`. A compact layout reports `.detailOnly`, one column at a time.
    public var columnVisibility: AdaptiveColumnVisibility
    /// How the inspector is shown when it is presented. Always `.sheet` in a compact layout.
    public var inspectorStyle: AdaptiveInspectorStyle
    /// Whether the user asked for the inspector.
    public var isInspectorPresented: Bool
    /// The column the navigation stack shows when the layout is (or would be) compact.
    public var compactColumn: AdaptiveColumn
    /// The policy that produced the layout, with its column widths.
    public var policy: AdaptiveLayoutPolicy

    public init(
        mode: AdaptiveLayoutMode,
        width: CGFloat,
        visibleColumns: [AdaptiveColumn],
        columnVisibility: AdaptiveColumnVisibility,
        inspectorStyle: AdaptiveInspectorStyle,
        isInspectorPresented: Bool,
        compactColumn: AdaptiveColumn,
        policy: AdaptiveLayoutPolicy = AdaptiveLayoutPolicy()
    ) {
        self.mode = mode
        self.width = width
        self.visibleColumns = visibleColumns.sorted()
        self.columnVisibility = columnVisibility
        self.inspectorStyle = inspectorStyle
        self.isInspectorPresented = isInspectorPresented
        self.compactColumn = compactColumn
        self.policy = policy
    }

    /// `true` when the columns collapse into a single navigation stack.
    public var isCollapsed: Bool {
        mode == .compact
    }

    /// Whether a column is on screen.
    public func isVisible(_ column: AdaptiveColumn) -> Bool {
        visibleColumns.contains(column)
    }

    /// Whether the sidebar is on screen as a column.
    public var isSidebarVisible: Bool {
        isVisible(.sidebar)
    }

    /// Whether the inspector is on screen as a trailing column.
    public var showsInspectorColumn: Bool {
        isVisible(.inspector)
    }

    /// Whether the inspector is on screen as a sheet.
    public var showsInspectorSheet: Bool {
        isInspectorPresented && inspectorStyle == .sheet
    }

    /// The layout of a 1024-point wide container with the default policy and nothing presented.
    public static let standard = AdaptiveLayoutPolicy().layout(in: AdaptiveLayoutContext(width: 1024))
}
