import Foundation

/// The user's column choices: sidebar visibility and whether the inspector is presented.
///
/// `Codable` and `RawRepresentable`, so it can be restored per window with `@SceneStorage` or for
/// the whole app with `@AppStorage`:
///
/// ```swift
/// @SceneStorage("columns") private var columns = AdaptiveColumnState()
/// ```
public struct AdaptiveColumnState: Sendable {
    /// The sidebar choice. `.automatic` lets the policy show the sidebar whenever it fits.
    public var columnVisibility: AdaptiveColumnVisibility
    /// Whether the inspector is presented, as a column or as a sheet.
    public var isInspectorPresented: Bool

    public init(columnVisibility: AdaptiveColumnVisibility = .automatic, isInspectorPresented: Bool = false) {
        self.columnVisibility = columnVisibility
        self.isInspectorPresented = isInspectorPresented
    }

    /// Hides the sidebar when the layout shows it, shows it otherwise. The result is an explicit
    /// choice (`.doubleColumn` or `.all`) that the policy honors at every width.
    public mutating func toggleSidebar(in layout: AdaptiveLayout) {
        columnVisibility = layout.isSidebarVisible ? .doubleColumn : .all
    }

    /// Shows or hides the sidebar explicitly.
    public mutating func setSidebarVisible(_ isVisible: Bool) {
        columnVisibility = isVisible ? .all : .doubleColumn
    }

    /// Lets the policy decide about the sidebar again.
    public mutating func resetSidebar() {
        columnVisibility = .automatic
    }

    /// Presents or dismisses the inspector.
    public mutating func toggleInspector() {
        isInspectorPresented.toggle()
    }
}

extension AdaptiveColumnState: Hashable {
    public static func == (lhs: AdaptiveColumnState, rhs: AdaptiveColumnState) -> Bool {
        lhs.columnVisibility == rhs.columnVisibility && lhs.isInspectorPresented == rhs.isInspectorPresented
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(columnVisibility)
        hasher.combine(isInspectorPresented)
    }
}

// Written out by hand (see `AdaptiveSelection`), and lenient: a missing or unknown value falls back
// to its default, so state saved by another version of the app still restores.
extension AdaptiveColumnState: Codable {
    private enum CodingKeys: String, CodingKey {
        case columnVisibility
        case isInspectorPresented
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let visibility = try? container.decodeIfPresent(AdaptiveColumnVisibility.self, forKey: .columnVisibility)
        let inspector = try? container.decodeIfPresent(Bool.self, forKey: .isInspectorPresented)
        self.init(columnVisibility: visibility ?? .automatic, isInspectorPresented: inspector ?? false)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columnVisibility, forKey: .columnVisibility)
        try container.encode(isInspectorPresented, forKey: .isInspectorPresented)
    }
}

extension AdaptiveColumnState: RawRepresentable {
    /// Restores the state from its JSON, or returns `nil` for anything that is not a JSON object.
    public init?(rawValue: String) {
        guard let state = StateCoding.decode(AdaptiveColumnState.self, from: rawValue) else {
            return nil
        }
        self = state
    }

    /// The state as JSON, for example `{"columnVisibility":"automatic","isInspectorPresented":true}`.
    public var rawValue: String {
        StateCoding.encode(self) ?? "{}"
    }
}

extension AdaptiveColumnState {
    /// Reads a state saved with ``save(to:forKey:)``, or `nil` when there is none.
    public static func restored(from defaults: UserDefaults, forKey key: String) -> AdaptiveColumnState? {
        defaults.string(forKey: key).flatMap(AdaptiveColumnState.init(rawValue:))
    }

    /// Saves the state as a JSON string, for apps that persist outside SwiftUI's property wrappers.
    public func save(to defaults: UserDefaults, forKey key: String) {
        defaults.set(rawValue, forKey: key)
    }
}
