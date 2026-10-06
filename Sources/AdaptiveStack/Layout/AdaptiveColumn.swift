import Foundation

/// The four columns of an adaptive layout, from leading to trailing.
public enum AdaptiveColumn: String, CaseIterable, Codable, Hashable, Sendable, Comparable {
    /// The leading navigation column, for example a list of projects.
    case sidebar
    /// The middle column, for example the tasks of the selected project.
    case content
    /// The main column, for example the selected task.
    case detail
    /// The trailing column with metadata about the detail, for example the task's properties.
    case inspector

    public static func < (lhs: AdaptiveColumn, rhs: AdaptiveColumn) -> Bool {
        lhs.position < rhs.position
    }

    private var position: Int {
        switch self {
        case .sidebar: 0
        case .content: 1
        case .detail: 2
        case .inspector: 3
        }
    }
}

/// Which columns of the split view the user asked for.
///
/// Mirrors `NavigationSplitViewVisibility`, but is `Codable` with a stable string value, so it can
/// be saved with `@SceneStorage` or `@AppStorage` and restored on the next launch.
public enum AdaptiveColumnVisibility: String, CaseIterable, Codable, Hashable, Sendable {
    /// The policy decides: the sidebar shows whenever it fits next to the content and detail.
    case automatic
    /// Sidebar, content and detail.
    case all
    /// Content and detail; the sidebar is hidden.
    case doubleColumn
    /// The detail alone.
    case detailOnly
}

/// How the inspector is shown when it is presented.
public enum AdaptiveInspectorStyle: String, CaseIterable, Codable, Hashable, Sendable {
    /// A trailing column next to the detail.
    case column
    /// A sheet over the layout, used when there is no room for another column.
    case sheet
}

/// What the policy does when the inspector is presented but does not fit as a column.
public enum AdaptiveInspectorFallback: String, CaseIterable, Codable, Hashable, Sendable {
    /// `.collapseSidebar` on the Mac, `.sheet` on iPad.
    case automatic
    /// Show the inspector as a sheet and keep the columns as they are.
    case sheet
    /// Hide an automatic sidebar to make room and keep the inspector as a column.
    case collapseSidebar

    /// The concrete fallback for a platform; never `.automatic`.
    public func resolved(for platform: AdaptivePlatform) -> AdaptiveInspectorFallback {
        switch self {
        case .automatic: platform == .macOS ? .collapseSidebar : .sheet
        case .sheet, .collapseSidebar: self
        }
    }
}

/// The overall shape of an adaptive layout.
public enum AdaptiveLayoutMode: String, CaseIterable, Codable, Hashable, Sendable {
    /// One column at a time in a navigation stack: iPhone, Slide Over, narrow split screen or a
    /// narrow Mac window.
    case compact
    /// A split view without room for every column at its ideal width; the sidebar may collapse
    /// and the inspector may become a sheet.
    case medium
    /// Room for sidebar, content, detail and inspector side by side.
    case wide
}

/// A platform-independent size class, so the policy can be tested without SwiftUI.
public enum AdaptiveSizeClass: String, CaseIterable, Codable, Hashable, Sendable {
    case compact
    case regular
}

/// The platform a layout is computed for.
public enum AdaptivePlatform: String, CaseIterable, Codable, Hashable, Sendable {
    /// iPadOS and iOS: touch first, sheets are the natural fallback.
    case iOS
    /// macOS: resizable windows, columns are the natural fallback.
    case macOS

    /// The platform this code runs on.
    public static var current: AdaptivePlatform {
        #if os(macOS)
        return .macOS
        #else
        return .iOS
        #endif
    }
}
