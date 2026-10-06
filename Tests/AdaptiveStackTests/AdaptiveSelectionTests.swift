import Foundation
import Testing
@testable import AdaptiveStack

@Suite("Selection")
struct AdaptiveSelectionTests {
    typealias Selection = AdaptiveSelection<String, Int>

    @Test func emptySelectionShowsTheSidebar() {
        let selection = Selection()
        #expect(selection.isEmpty)
        #expect(selection.compactPath.isEmpty)
        #expect(selection.compactColumn == .sidebar)
    }

    @Test func compactPathFollowsTheSelection() {
        let project = Selection(sidebar: "atlas")
        #expect(project.compactPath == [.content])
        #expect(project.compactColumn == .content)

        let task = Selection(sidebar: "atlas", item: 142)
        #expect(task.compactPath == [.content, .detail])
        #expect(task.compactColumn == .detail)

        let orphan = Selection(item: 7)
        #expect(orphan.compactPath == [.detail])
    }

    @Test func changingTheSidebarClearsTheItem() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.sidebar = "website"
        #expect(selection.sidebar == "website")
        #expect(selection.item == nil)
    }

    @Test func reselectingTheSameSidebarKeepsTheItem() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.sidebar = "atlas"
        #expect(selection.item == 142)
    }

    @Test func selectSetsBoth() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.select(sidebar: "website", item: 9)
        #expect(selection == Selection(sidebar: "website", item: 9))
    }

    @Test func poppingTheStackClearsTheSelection() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.applyCompactPath([.content])
        #expect(selection == Selection(sidebar: "atlas"))

        selection.applyCompactPath([])
        #expect(selection.isEmpty)
    }

    @Test func unchangedPathKeepsTheSelection() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.applyCompactPath([.content, .detail])
        #expect(selection == Selection(sidebar: "atlas", item: 142))
    }

    @Test func goBack() {
        var selection = Selection(sidebar: "atlas", item: 142)
        selection.goBack()
        #expect(selection == Selection(sidebar: "atlas"))
        selection.goBack()
        #expect(selection.isEmpty)
    }

    @Test func codableRoundTrip() throws {
        let selection = Selection(sidebar: "atlas", item: 142)
        let data = try JSONEncoder().encode(selection)
        let decoded = try JSONDecoder().decode(Selection.self, from: data)
        #expect(decoded == selection)
    }

    @Test func rawValueRoundTrip() {
        let selection = Selection(sidebar: "atlas", item: 142)
        let rawValue = selection.rawValue
        #expect(rawValue == #"{"item":142,"sidebar":"atlas"}"#)
        #expect(Selection(rawValue: rawValue) == selection)
    }

    @Test func emptyRawValue() {
        let rawValue = Selection().rawValue
        #expect(rawValue == "{}")
        #expect(Selection(rawValue: rawValue) == Selection())
    }

    @Test func invalidRawValueIsRejected() {
        #expect(Selection(rawValue: "not json") == nil)
        #expect(Selection(rawValue: #"{"sidebar":12}"#) == nil)
    }

    @Test func hashableMatchesEquality() {
        let set: Set<Selection> = [Selection(sidebar: "a", item: 1), Selection(sidebar: "a", item: 1), Selection(sidebar: "b")]
        #expect(set.count == 2)
    }
}
