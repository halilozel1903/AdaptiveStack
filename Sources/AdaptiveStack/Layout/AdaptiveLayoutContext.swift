import Foundation

/// Everything the policy needs to know about the space it lays out: the container width, the
/// size classes and the platform.
public struct AdaptiveLayoutContext: Hashable, Sendable {
    /// The width of the container in points.
    public var width: CGFloat
    /// The horizontal size class. Always `.regular` on the Mac, where the width decides alone.
    public var horizontalSizeClass: AdaptiveSizeClass
    /// The vertical size class. `.compact` on an iPhone in landscape.
    public var verticalSizeClass: AdaptiveSizeClass
    /// The platform the layout is for.
    public var platform: AdaptivePlatform

    public init(
        width: CGFloat,
        horizontalSizeClass: AdaptiveSizeClass = .regular,
        verticalSizeClass: AdaptiveSizeClass = .regular,
        platform: AdaptivePlatform = .current
    ) {
        self.width = width
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        self.platform = platform
    }
}
