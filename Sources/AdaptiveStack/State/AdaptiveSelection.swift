import Foundation

/// What is selected in the sidebar and in the content column.
///
/// The same value drives the split view and the compact navigation stack, so rotating an iPad,
/// entering Slide Over or narrowing a Mac window keeps the user where they were. It is `Codable`
/// and `RawRepresentable`, so it can be restored with `@SceneStorage` or `@AppStorage`:
///
/// ```swift
/// @SceneStorage("selection") private var selection = AdaptiveSelection<Project.ID, Task.ID>()
/// ```
public struct AdaptiveSelection<SidebarID, ItemID>: Sendable
where SidebarID: Hashable & Codable & Sendable, ItemID: Hashable & Codable & Sendable {
    /// The selected sidebar row, for example a project. Changing it clears ``item``, which belongs
    /// to the previous sidebar row.
    public var sidebar: SidebarID? {
        didSet {
            if sidebar != oldValue {
                item = nil
            }
        }
    }

    /// The selected content row, for example a task, shown in the detail column.
    public var item: ItemID?

    public init(sidebar: SidebarID? = nil, item: ItemID? = nil) {
        self.sidebar = sidebar
        self.item = item
    }

    /// Selects a sidebar row and an item in one step, without clearing the new item.
    public mutating func select(sidebar: SidebarID?, item: ItemID?) {
        self.sidebar = sidebar
        self.item = item
    }

    /// `true` when nothing is selected.
    public var isEmpty: Bool {
        sidebar == nil && item == nil
    }

    /// The columns pushed onto the compact navigation stack, whose root is the sidebar:
    /// `[]`, `[.content]`, `[.content, .detail]`, or `[.detail]` for an item without a sidebar row.
    public var compactPath: [AdaptiveColumn] {
        var path: [AdaptiveColumn] = []
        if sidebar != nil { path.append(.content) }
        if item != nil { path.append(.detail) }
        return path
    }

    /// The column on top of the compact navigation stack.
    public var compactColumn: AdaptiveColumn {
        compactPath.last ?? .sidebar
    }

    /// Applies a navigation stack path after the user went back: a column missing from the path
    /// clears its selection.
    public mutating func applyCompactPath(_ path: [AdaptiveColumn]) {
        if !path.contains(.detail) {
            item = nil
        }
        if !path.contains(.content) && sidebar != nil {
            sidebar = nil
        }
    }

    /// Goes back one level: clears the item, or the sidebar row when no item is selected.
    public mutating func goBack() {
        if item != nil {
            item = nil
        } else {
            sidebar = nil
        }
    }
}

extension AdaptiveSelection: Hashable {
    public static func == (lhs: AdaptiveSelection, rhs: AdaptiveSelection) -> Bool {
        lhs.sidebar == rhs.sidebar && lhs.item == rhs.item
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(sidebar)
        hasher.combine(item)
    }
}

// Written out by hand: a type that is both `Codable` and `RawRepresentable` would otherwise get the
// standard library's raw value coding, which calls `rawValue`, which encodes again, forever.
extension AdaptiveSelection: Codable {
    private enum CodingKeys: String, CodingKey {
        case sidebar
        case item
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sidebar = try container.decodeIfPresent(SidebarID.self, forKey: .sidebar)
        let item = try container.decodeIfPresent(ItemID.self, forKey: .item)
        self.init(sidebar: sidebar, item: item)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(sidebar, forKey: .sidebar)
        try container.encodeIfPresent(item, forKey: .item)
    }
}

extension AdaptiveSelection: RawRepresentable {
    /// Restores a selection from its JSON, or returns `nil` for anything that does not decode.
    public init?(rawValue: String) {
        guard let selection = StateCoding.decode(AdaptiveSelection.self, from: rawValue) else {
            return nil
        }
        self = selection
    }

    /// The selection as JSON, for example `{"item":"ATL-142","sidebar":"ipad"}`.
    public var rawValue: String {
        StateCoding.encode(self) ?? "{}"
    }
}
