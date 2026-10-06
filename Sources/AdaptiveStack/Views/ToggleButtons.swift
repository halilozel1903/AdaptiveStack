import SwiftUI

/// Shows or hides the sidebar. ⌥⌘S on the Mac and with a hardware keyboard on iPad.
struct SidebarToggleButton: View {
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isVisible ? "Hide Sidebar" : "Show Sidebar", systemImage: "sidebar.left")
        }
        .keyboardShortcut("s", modifiers: [.command, .option])
        .help(isVisible ? "Hide Sidebar (⌥⌘S)" : "Show Sidebar (⌥⌘S)")
        .accessibilityIdentifier("adaptive-stack.toggle-sidebar")
    }
}

/// Presents or dismisses the inspector. ⌥⌘I on the Mac and with a hardware keyboard on iPad.
struct InspectorToggleButton: View {
    let isPresented: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isPresented ? "Hide Inspector" : "Show Inspector", systemImage: "sidebar.right")
        }
        .keyboardShortcut("i", modifiers: [.command, .option])
        .help(isPresented ? "Hide Inspector (⌥⌘I)" : "Show Inspector (⌥⌘I)")
        .accessibilityIdentifier("adaptive-stack.toggle-inspector")
    }
}
