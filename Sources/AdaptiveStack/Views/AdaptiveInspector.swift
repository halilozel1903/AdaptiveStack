import SwiftUI

extension View {
    /// Presents an inspector the way the current layout asks for: a trailing column (SwiftUI's
    /// `.inspector`) when there is room, a sheet with a Done button when there is not.
    ///
    /// Inside an `AdaptiveStack` or `AdaptiveLayoutReader` the style and width come from the
    /// environment's `AdaptiveLayout`. Elsewhere it is a plain `.inspector`, which iOS turns into a
    /// sheet in a compact size class by itself.
    ///
    /// ```swift
    /// TaskDetail(task: task)
    ///     .adaptiveInspector(isPresented: $showsInspector) {
    ///         TaskInspector(task: task)
    ///     }
    /// ```
    public func adaptiveInspector<Inspector: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Inspector
    ) -> some View {
        modifier(AdaptiveInspectorModifier(isPresented: isPresented, style: nil, width: nil, inspector: content()))
    }

    /// Presents an inspector with a fixed style and width.
    public func adaptiveInspector<Inspector: View>(
        isPresented: Binding<Bool>,
        style: AdaptiveInspectorStyle,
        width: AdaptiveColumnWidth = .inspector,
        @ViewBuilder content: () -> Inspector
    ) -> some View {
        modifier(AdaptiveInspectorModifier(isPresented: isPresented, style: style, width: width, inspector: content()))
    }
}

/// Applies both presentations, each gated by the resolved style, so switching between a column
/// and a sheet never changes the view's identity.
struct AdaptiveInspectorModifier<Inspector: View>: ViewModifier {
    @Binding var isPresented: Bool
    let style: AdaptiveInspectorStyle?
    let width: AdaptiveColumnWidth?
    let inspector: Inspector

    @Environment(\.adaptiveLayout) private var layout

    func body(content: Content) -> some View {
        let resolvedStyle = style ?? layout?.inspectorStyle ?? AdaptiveInspectorStyle.column
        let resolvedWidth = width ?? layout?.policy.inspectorWidth ?? AdaptiveColumnWidth.inspector
        let presented = $isPresented

        content
            .inspector(isPresented: Binding(
                get: { presented.wrappedValue && resolvedStyle == .column },
                set: { newValue in
                    if resolvedStyle == .column, presented.wrappedValue != newValue {
                        presented.wrappedValue = newValue
                    }
                }
            )) {
                inspector
                    .inspectorColumnWidth(
                        min: resolvedWidth.minimum,
                        ideal: resolvedWidth.ideal,
                        max: resolvedWidth.maximum
                    )
            }
            .sheet(isPresented: Binding(
                get: { presented.wrappedValue && resolvedStyle == .sheet },
                set: { newValue in
                    if resolvedStyle == .sheet, presented.wrappedValue != newValue {
                        presented.wrappedValue = newValue
                    }
                }
            )) {
                InspectorSheet(isPresented: presented, inspector: inspector)
            }
    }
}

/// The inspector in a sheet: a navigation stack for its title and a Done button.
struct InspectorSheet<Inspector: View>: View {
    @Binding var isPresented: Bool
    let inspector: Inspector

    var body: some View {
        NavigationStack {
            inspector
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        #if os(macOS)
        .frame(minWidth: 380, idealWidth: 420, minHeight: 460, idealHeight: 560)
        #endif
    }
}
