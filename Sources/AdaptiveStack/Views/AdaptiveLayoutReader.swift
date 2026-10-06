import SwiftUI

/// Measures the space it is given, asks the policy for a layout and passes it to its content.
///
/// The layout is also put in the environment, so any view below can read it with
/// `@Environment(\.adaptiveLayout)`:
///
/// ```swift
/// AdaptiveLayoutReader(columns: columns) { layout in
///     if layout.isCollapsed {
///         CompactBoard()
///     } else {
///         Board(columns: layout.visibleColumns)
///     }
/// }
/// ```
///
/// `AdaptiveStack` uses one internally; use it directly for layouts of your own.
public struct AdaptiveLayoutReader<Content: View>: View {
    private let policy: AdaptiveLayoutPolicy
    private let columns: AdaptiveColumnState
    private let compactColumn: AdaptiveColumn
    private let content: (AdaptiveLayout) -> Content

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    /// - Parameters:
    ///   - policy: The column widths and fallbacks.
    ///   - columns: The user's sidebar and inspector choices.
    ///   - compactColumn: The column a compact layout shows.
    ///   - content: Builds the view for a layout. Called again whenever the size or the size classes change.
    public init(
        policy: AdaptiveLayoutPolicy = AdaptiveLayoutPolicy(),
        columns: AdaptiveColumnState = AdaptiveColumnState(),
        compactColumn: AdaptiveColumn = .sidebar,
        @ViewBuilder content: @escaping (AdaptiveLayout) -> Content
    ) {
        self.policy = policy
        self.columns = columns
        self.compactColumn = compactColumn
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let layout = policy.layout(
                in: context(width: proxy.size.width),
                columns: columns,
                compactColumn: compactColumn
            )
            content(layout)
                .environment(\.adaptiveLayout, layout)
        }
    }

    private func context(width: CGFloat) -> AdaptiveLayoutContext {
        #if os(iOS)
        return AdaptiveLayoutContext(
            width: width,
            horizontalSizeClass: AdaptiveSizeClass(horizontalSizeClass),
            verticalSizeClass: AdaptiveSizeClass(verticalSizeClass),
            platform: .iOS
        )
        #else
        return AdaptiveLayoutContext(width: width, platform: .macOS)
        #endif
    }
}
