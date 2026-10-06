import Foundation

/// The minimum, ideal and maximum width of a column in points.
public struct AdaptiveColumnWidth: Hashable, Sendable {
    /// The narrowest the column may become.
    public var minimum: CGFloat
    /// The width the column gets when there is room. The policy uses it to decide what fits.
    public var ideal: CGFloat
    /// The widest the column may become when the user drags its divider.
    public var maximum: CGFloat

    /// Creates a width. `ideal` is raised to `minimum` and `maximum` to `ideal` when they are smaller.
    public init(minimum: CGFloat, ideal: CGFloat, maximum: CGFloat) {
        self.minimum = minimum
        self.ideal = Swift.max(minimum, ideal)
        self.maximum = Swift.max(self.ideal, maximum)
    }

    /// The default sidebar width: 200 to 340 points, ideally 260.
    public static let sidebar = AdaptiveColumnWidth(minimum: 200, ideal: 260, maximum: 340)
    /// The default content width: 240 to 440 points, ideally 340.
    public static let content = AdaptiveColumnWidth(minimum: 240, ideal: 340, maximum: 440)
    /// The default detail width: at least 440 points, ideally 600, otherwise as wide as it gets.
    public static let detail = AdaptiveColumnWidth(minimum: 440, ideal: 600, maximum: .greatestFiniteMagnitude)
    /// The default inspector width: 240 to 380 points, ideally 300.
    public static let inspector = AdaptiveColumnWidth(minimum: 240, ideal: 300, maximum: 380)
}
