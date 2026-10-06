import AdaptiveStack
import SwiftUI

/// Scenes used by CI to capture the README screenshots on iPad and on the Mac.
///
/// Launch with `-screenshot <scene>`; normal launches are unaffected. A `mac-` or `ipad-` prefix is
/// accepted too, so `-screenshot ipad-full` is the same as `-screenshot full`.
enum ScreenshotScene: String, Sendable {
    /// Every column: projects, tasks, the open task and the inspector.
    /// On iPad it is laid out on a landscape canvas (see `LandscapeCanvas`).
    case full
    /// iPad in its natural portrait orientation: the sidebar collapses and the inspector is a sheet.
    case collapsed
    /// Mac: projects, tasks and the open task with the inspector dismissed.
    case inspectorHidden = "inspector-hidden"

    static var current: ScreenshotScene? {
        guard var name = argument(after: "-screenshot") else { return nil }
        for prefix in ["mac-", "ipad-"] where name.hasPrefix(prefix) {
            name.removeFirst(prefix.count)
        }
        return ScreenshotScene(rawValue: name)
    }

    /// Where `-render-screenshot` asks the PNG to be written (Mac only).
    static var renderPath: String? {
        argument(after: "-render-screenshot")
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    /// Whether the inspector is presented in this scene.
    var showsInspector: Bool {
        self != .inspectorHidden
    }
}

/// The app with a fixed selection and fixed columns that are never saved, in the light appearance.
struct ScreenshotView: View {
    let scene: ScreenshotScene

    @State private var selection = AdaptiveSelection<Project.ID, AtlasTask.ID>(
        sidebar: AtlasData.screenshotProjectID,
        item: AtlasData.screenshotTaskID
    )
    @State private var columns: AdaptiveColumnState

    init(scene: ScreenshotScene) {
        self.scene = scene
        _columns = State(initialValue: AdaptiveColumnState(isInspectorPresented: scene.showsInspector))
    }

    var body: some View {
        canvas
            .preferredColorScheme(.light)
            .task {
                // Tells scripts/screenshots-ipad.sh that the scene is on screen.
                let marker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
                try? await Task.sleep(for: .seconds(1))
                try? scene.rawValue.write(to: marker, atomically: true, encoding: .utf8)
            }
    }

    @ViewBuilder
    private var canvas: some View {
        #if os(iOS)
        if scene == .full {
            LandscapeCanvas {
                AtlasRootView(selection: $selection, columns: $columns)
            }
        } else {
            AtlasRootView(selection: $selection, columns: $columns)
        }
        #else
        AtlasRootView(selection: $selection, columns: $columns)
        #endif
    }
}

#if os(iOS)
/// Lays its content out at the size of a 13-inch iPad Pro in landscape (1376 × 1032 points) and
/// scales it to fit the screen.
///
/// Rotating a simulator from the command line is unreliable (`simctl` has no rotate command and the
/// Simulator app's menu needs UI scripting), so the simulator stays in its default portrait
/// orientation. The app still lays out at the full landscape size, with the same size classes, so
/// `AdaptiveStack` and `NavigationSplitView` produce exactly the landscape layout.
/// scripts/screenshots-ipad.sh crops the 4:3 band out of the portrait capture.
struct LandscapeCanvas<Content: View>: View {
    static var size: CGSize { CGSize(width: 1376, height: 1032) }

    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / Self.size.width, proxy.size.height / Self.size.height)
            content
                .frame(width: Self.size.width, height: Self.size.height)
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .statusBarHidden()
    }
}
#endif
