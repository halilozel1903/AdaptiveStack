import AdaptiveStack
import SwiftUI

@main
struct AtlasPadApp: App {
    var body: some Scene {
        WindowGroup {
            if let scene = ScreenshotScene.current {
                // Fixed selection and columns, nothing restored or saved.
                ScreenshotView(scene: scene)
            } else {
                // Rotate, use split screen or Slide Over: the columns reflow and the selection stays.
                AtlasSceneView()
            }
        }
    }
}
