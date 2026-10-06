import AppKit
import SwiftUI

/// Prepares the window a screenshot scene is shown in, and renders it to a PNG when asked to.
///
/// Unlike a plain view, `NavigationSplitView` and `.inspector` need a real titled window: their
/// toolbars (with the sidebar and inspector buttons) live in its title bar. So the screenshot uses
/// the app's own SwiftUI window at a fixed size, and scripts/screenshots-mac.sh captures it with
/// `screencapture -l <window id>`. The renderer below is the fallback for when that fails.
struct ScreenshotWindow: NSViewRepresentable {
    /// The window's content size in points.
    static let size = CGSize(width: 1400, height: 860)

    let scene: ScreenshotScene

    func makeNSView(context: Context) -> NSView {
        ConfiguringView(scene: scene)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class ConfiguringView: NSView {
        private let scene: ScreenshotScene
        private var renderer: ScreenshotRenderer?

        init(scene: ScreenshotScene) {
            self.scene = scene
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is not used")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, renderer == nil else { return }

            window.title = "Atlas"
            window.appearance = NSAppearance(named: .aqua)
            window.isRestorable = false
            window.setContentSize(ScreenshotWindow.size)
            window.center()

            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate()
            window.makeKeyAndOrderFront(nil)

            renderer = ScreenshotRenderer(window: window, path: ScreenshotScene.renderPath)
        }
    }
}

/// The fallback: draws the window into a 2x bitmap with `cacheDisplay`, refuses a blank result,
/// writes the PNG and quits. Exits with status 1 on any failure so the CI script can give up.
/// `cacheDisplay` cannot draw everything (some materials, grouped forms), which is why
/// `screencapture` goes first.
@MainActor
final class ScreenshotRenderer {
    private let window: NSWindow

    init(window: NSWindow, path: String?) {
        self.window = window

        Task {
            // Make sure no other window (a restored one, a second scene) is on screen.
            try? await Task.sleep(for: .seconds(1))
            for other in NSApplication.shared.windows where other !== self.window && other.isVisible {
                other.orderOut(nil)
            }
            // Give SwiftUI and AppKit time to lay out the columns and draw materials and symbols.
            try? await Task.sleep(for: .seconds(3))
            if let path {
                self.render(to: path)
            }
        }
    }

    private func render(to path: String) {
        // The frame view holds the title bar and toolbar as well as the content.
        guard let view = window.contentView?.superview ?? window.contentView else {
            return fail("The window has no content view")
        }
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()

        let bounds = view.bounds
        let scale: CGFloat = 2
        guard bounds.width > 0, bounds.height > 0,
              let bitmap = NSBitmapImageRep(
                  bitmapDataPlanes: nil,
                  pixelsWide: Int(bounds.width * scale),
                  pixelsHigh: Int(bounds.height * scale),
                  bitsPerSample: 8,
                  samplesPerPixel: 4,
                  hasAlpha: true,
                  isPlanar: false,
                  colorSpaceName: .deviceRGB,
                  bytesPerRow: 0,
                  bitsPerPixel: 0
              )
        else { return fail("Could not create a bitmap for \(bounds)") }

        // The bitmap's size in points against its pixel size makes the view draw at 2x.
        bitmap.size = bounds.size
        view.cacheDisplay(in: bounds, to: bitmap)

        guard Self.distinctColorCount(in: bitmap) > 24 else {
            return fail("The rendered image is blank")
        }
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            return fail("Could not encode the PNG")
        }
        do {
            try png.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            return fail("Could not write \(path): \(error.localizedDescription)")
        }
        print("Rendered \(path) (\(bitmap.pixelsWide)x\(bitmap.pixelsHigh), \(png.count) bytes)")
        exit(0)
    }

    /// Samples a grid of pixels. A blank or single-color image has only a handful of colors.
    private static func distinctColorCount(in bitmap: NSBitmapImageRep) -> Int {
        var colors = Set<UInt32>()
        let step = max(1, min(bitmap.pixelsWide, bitmap.pixelsHigh) / 60)
        for y in stride(from: 0, to: bitmap.pixelsHigh, by: step) {
            for x in stride(from: 0, to: bitmap.pixelsWide, by: step) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                colors.insert(channel(color.redComponent) << 16 | channel(color.greenComponent) << 8 | channel(color.blueComponent))
            }
        }
        return colors.count
    }

    private static func channel(_ component: CGFloat) -> UInt32 {
        UInt32(min(255, max(0, (component * 255).rounded())))
    }

    private func fail(_ message: String) {
        FileHandle.standardError.write(Data("Screenshot failed: \(message)\n".utf8))
        exit(1)
    }
}
