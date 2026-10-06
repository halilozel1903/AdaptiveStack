import Foundation
import Testing
@testable import AdaptiveStack

@Suite("Column state")
struct AdaptiveColumnStateTests {
    let policy = AdaptiveLayoutPolicy()

    @Test func defaults() {
        let state = AdaptiveColumnState()
        #expect(state.columnVisibility == .automatic)
        #expect(!state.isInspectorPresented)
    }

    @Test func toggleSidebarHidesAVisibleSidebar() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1376, platform: .iOS))
        #expect(layout.isSidebarVisible)

        var state = AdaptiveColumnState()
        state.toggleSidebar(in: layout)
        #expect(state.columnVisibility == .doubleColumn)

        let hidden = policy.layout(in: AdaptiveLayoutContext(width: 1376, platform: .iOS), columns: state)
        #expect(!hidden.isSidebarVisible)
    }

    @Test func toggleSidebarShowsACollapsedSidebar() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1032, platform: .iOS))
        #expect(!layout.isSidebarVisible)

        var state = AdaptiveColumnState()
        state.toggleSidebar(in: layout)
        #expect(state.columnVisibility == .all)

        let shown = policy.layout(in: AdaptiveLayoutContext(width: 1032, platform: .iOS), columns: state)
        #expect(shown.isSidebarVisible)
    }

    @Test func setAndResetSidebar() {
        var state = AdaptiveColumnState()
        state.setSidebarVisible(false)
        #expect(state.columnVisibility == .doubleColumn)
        state.setSidebarVisible(true)
        #expect(state.columnVisibility == .all)
        state.resetSidebar()
        #expect(state.columnVisibility == .automatic)
    }

    @Test func toggleInspector() {
        var state = AdaptiveColumnState()
        state.toggleInspector()
        #expect(state.isInspectorPresented)
        state.toggleInspector()
        #expect(!state.isInspectorPresented)
    }

    @Test func rawValueRoundTrip() {
        let state = AdaptiveColumnState(columnVisibility: .doubleColumn, isInspectorPresented: true)
        let rawValue = state.rawValue
        #expect(rawValue == #"{"columnVisibility":"doubleColumn","isInspectorPresented":true}"#)
        #expect(AdaptiveColumnState(rawValue: rawValue) == state)
    }

    @Test func lenientDecoding() {
        let unknown = AdaptiveColumnState(rawValue: #"{"columnVisibility":"tripleColumn","isInspectorPresented":true}"#)
        #expect(unknown == AdaptiveColumnState(columnVisibility: .automatic, isInspectorPresented: true))

        let empty = AdaptiveColumnState(rawValue: "{}")
        #expect(empty == AdaptiveColumnState())

        #expect(AdaptiveColumnState(rawValue: "[]") == nil)
        #expect(AdaptiveColumnState(rawValue: "") == nil)
    }

    @Test func userDefaultsRoundTrip() throws {
        let suite = "AdaptiveStackTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(AdaptiveColumnState.restored(from: defaults, forKey: "columns") == nil)

        let state = AdaptiveColumnState(columnVisibility: .all, isInspectorPresented: true)
        state.save(to: defaults, forKey: "columns")
        #expect(AdaptiveColumnState.restored(from: defaults, forKey: "columns") == state)
    }
}
