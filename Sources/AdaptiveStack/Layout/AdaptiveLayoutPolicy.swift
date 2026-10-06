import Foundation

/// Decides which columns show for a container width, the size classes and the user's choices.
///
/// The policy is a plain value with no SwiftUI in it, so every decision can be unit tested:
///
/// - **Compact**: a compact horizontal size class (iPhone, Slide Over, narrow split screen), a
///   compact vertical size class on iOS (iPhone in landscape), or a width below
///   ``compactWidthThreshold``. One column at a time in a navigation stack, the inspector as a sheet.
/// - **Medium**: a split view. The sidebar shows when it fits at its ideal width next to the
///   content and the detail (or when the user asked for it). The inspector is a column when it
///   fits, otherwise the ``inspectorFallback`` applies: a sheet on iPad, a collapsed sidebar on the Mac.
/// - **Wide**: at least ``wideWidthThreshold`` points: sidebar, content, detail and inspector
///   side by side.
///
/// With the default widths a 13-inch iPad Pro is wide in landscape (1376 points) and medium in
/// portrait (1032 points, no sidebar, inspector as a sheet).
public struct AdaptiveLayoutPolicy: Hashable, Sendable {
    /// The sidebar width. Its ideal width is what has to fit for an automatic sidebar to show.
    public var sidebarWidth: AdaptiveColumnWidth
    /// The content column width.
    public var contentWidth: AdaptiveColumnWidth
    /// The detail width. Its minimum is what the detail keeps before other columns give way.
    public var detailWidth: AdaptiveColumnWidth
    /// The inspector width. Its ideal width is what has to fit for the inspector to be a column.
    public var inspectorWidth: AdaptiveColumnWidth
    /// What happens when the inspector is presented but does not fit as a column.
    public var inspectorFallback: AdaptiveInspectorFallback

    public init(
        sidebarWidth: AdaptiveColumnWidth = .sidebar,
        contentWidth: AdaptiveColumnWidth = .content,
        detailWidth: AdaptiveColumnWidth = .detail,
        inspectorWidth: AdaptiveColumnWidth = .inspector,
        inspectorFallback: AdaptiveInspectorFallback = .automatic
    ) {
        self.sidebarWidth = sidebarWidth
        self.contentWidth = contentWidth
        self.detailWidth = detailWidth
        self.inspectorWidth = inspectorWidth
        self.inspectorFallback = inspectorFallback
    }

    /// Below this width the layout is compact: the content and detail minimums side by side.
    public var compactWidthThreshold: CGFloat {
        contentWidth.minimum + detailWidth.minimum
    }

    /// From this width on the layout is wide: every column at its ideal width, the detail at its minimum.
    public var wideWidthThreshold: CGFloat {
        sidebarWidth.ideal + contentWidth.ideal + detailWidth.minimum + inspectorWidth.ideal
    }

    /// Compact, medium or wide for a context.
    public func mode(for context: AdaptiveLayoutContext) -> AdaptiveLayoutMode {
        if context.horizontalSizeClass == .compact {
            return .compact
        }
        if context.platform == .iOS && context.verticalSizeClass == .compact {
            return .compact
        }
        if context.width < compactWidthThreshold {
            return .compact
        }
        return context.width >= wideWidthThreshold ? .wide : .medium
    }

    /// Computes the layout.
    ///
    /// - Parameters:
    ///   - context: The container width, size classes and platform.
    ///   - columns: The user's choices: sidebar visibility and whether the inspector is presented.
    ///   - compactColumn: The column the navigation stack shows when the layout is compact, usually
    ///     ``AdaptiveSelection/compactColumn``. The inspector maps to the detail, under its sheet.
    public func layout(
        in context: AdaptiveLayoutContext,
        columns: AdaptiveColumnState = AdaptiveColumnState(),
        compactColumn: AdaptiveColumn = .sidebar
    ) -> AdaptiveLayout {
        let stackTop: AdaptiveColumn = compactColumn == .inspector ? .detail : compactColumn
        let mode = self.mode(for: context)

        guard mode != .compact else {
            return AdaptiveLayout(
                mode: .compact,
                width: context.width,
                visibleColumns: [stackTop],
                columnVisibility: .detailOnly,
                inspectorStyle: .sheet,
                isInspectorPresented: columns.isInspectorPresented,
                compactColumn: stackTop,
                policy: self
            )
        }

        let width = context.width
        let showsContent = columns.columnVisibility != .detailOnly
        let mainWidth = detailWidth.minimum + (showsContent ? contentWidth.ideal : 0)

        var showsSidebar: Bool
        switch columns.columnVisibility {
        case .automatic:
            showsSidebar = width >= mainWidth + sidebarWidth.ideal
        case .all:
            // An explicit choice is honored even when the detail has to shrink.
            showsSidebar = true
        case .doubleColumn, .detailOnly:
            showsSidebar = false
        }

        let usedWidth = mainWidth + (showsSidebar ? sidebarWidth.ideal : 0)
        let inspectorStyle: AdaptiveInspectorStyle
        if usedWidth + inspectorWidth.ideal <= width {
            inspectorStyle = .column
        } else {
            switch inspectorFallback.resolved(for: context.platform) {
            case .collapseSidebar:
                inspectorStyle = .column
                if columns.isInspectorPresented && columns.columnVisibility == .automatic {
                    showsSidebar = false
                }
            case .sheet, .automatic:
                inspectorStyle = .sheet
            }
        }

        var visible: [AdaptiveColumn] = []
        if showsSidebar { visible.append(.sidebar) }
        if showsContent { visible.append(.content) }
        visible.append(.detail)
        if columns.isInspectorPresented && inspectorStyle == .column {
            visible.append(.inspector)
        }

        let resolvedVisibility: AdaptiveColumnVisibility
        if showsSidebar {
            resolvedVisibility = .all
        } else if showsContent {
            resolvedVisibility = .doubleColumn
        } else {
            resolvedVisibility = .detailOnly
        }

        return AdaptiveLayout(
            mode: mode,
            width: width,
            visibleColumns: visible,
            columnVisibility: resolvedVisibility,
            inspectorStyle: inspectorStyle,
            isInspectorPresented: columns.isInspectorPresented,
            compactColumn: stackTop,
            policy: self
        )
    }
}
