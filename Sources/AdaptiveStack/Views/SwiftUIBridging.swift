import SwiftUI

extension AdaptiveColumnVisibility {
    /// The matching `NavigationSplitView` visibility.
    public var splitViewVisibility: NavigationSplitViewVisibility {
        switch self {
        case .automatic: .automatic
        case .all: .all
        case .doubleColumn: .doubleColumn
        case .detailOnly: .detailOnly
        }
    }

    /// The matching value for a `NavigationSplitView` visibility.
    public init(_ visibility: NavigationSplitViewVisibility) {
        if visibility == .all {
            self = .all
        } else if visibility == .doubleColumn {
            self = .doubleColumn
        } else if visibility == .detailOnly {
            self = .detailOnly
        } else {
            self = .automatic
        }
    }
}

#if os(iOS)
extension AdaptiveSizeClass {
    /// The matching size class; `nil` (unknown) counts as regular.
    public init(_ sizeClass: UserInterfaceSizeClass?) {
        self = sizeClass == .compact ? .compact : .regular
    }
}
#endif

private struct AdaptiveLayoutKey: EnvironmentKey {
    static let defaultValue: AdaptiveLayout? = nil
}

extension EnvironmentValues {
    /// The layout of the nearest `AdaptiveStack` or `AdaptiveLayoutReader`, or `nil` outside of one.
    public var adaptiveLayout: AdaptiveLayout? {
        get { self[AdaptiveLayoutKey.self] }
        set { self[AdaptiveLayoutKey.self] = newValue }
    }
}
