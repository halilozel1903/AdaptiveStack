import AdaptiveStack
import SwiftUI

@main
struct AtlasMacApp: App {
    var body: some Scene {
        WindowGroup("Atlas") {
            if let scene = ScreenshotScene.current {
                // A window of a fixed size with a fixed selection, for scripts/screenshots-mac.sh.
                ScreenshotView(scene: scene)
                    .frame(width: ScreenshotWindow.size.width, height: ScreenshotWindow.size.height)
                    .background(ScreenshotWindow(scene: scene))
            } else {
                // Resize the window: the sidebar and the inspector make room for each other, and
                // below 680 points the columns collapse into a navigation stack.
                AtlasSceneView()
                    .frame(minWidth: 560, minHeight: 480)
            }
        }
        .defaultSize(width: 1400, height: 860)
    }
}
