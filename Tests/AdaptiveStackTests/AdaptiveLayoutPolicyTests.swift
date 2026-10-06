import Foundation
import Testing
@testable import AdaptiveStack

@Suite("Layout policy")
struct AdaptiveLayoutPolicyTests {
    let policy = AdaptiveLayoutPolicy()
    let inspectorShown = AdaptiveColumnState(isInspectorPresented: true)

    // MARK: Thresholds

    @Test func defaultThresholds() {
        #expect(policy.compactWidthThreshold == 680)   // content 240 + detail 440
        #expect(policy.wideWidthThreshold == 1340)     // sidebar 260 + content 340 + detail 440 + inspector 300
    }

    @Test func modes() {
        #expect(policy.mode(for: AdaptiveLayoutContext(width: 1376, platform: .iOS)) == .wide)
        #expect(policy.mode(for: AdaptiveLayoutContext(width: 1340, platform: .iOS)) == .wide)
        #expect(policy.mode(for: AdaptiveLayoutContext(width: 1339, platform: .iOS)) == .medium)
        #expect(policy.mode(for: AdaptiveLayoutContext(width: 680, platform: .macOS)) == .medium)
        #expect(policy.mode(for: AdaptiveLayoutContext(width: 679, platform: .macOS)) == .compact)
    }

    @Test func compactSizeClassAlwaysStacks() {
        let slideOver = AdaptiveLayoutContext(width: 1200, horizontalSizeClass: .compact, platform: .iOS)
        #expect(policy.mode(for: slideOver) == .compact)
    }

    @Test func phoneInLandscapeStacks() {
        let phone = AdaptiveLayoutContext(width: 932, horizontalSizeClass: .regular, verticalSizeClass: .compact, platform: .iOS)
        #expect(policy.mode(for: phone) == .compact)

        // A short Mac window is not a phone.
        let mac = AdaptiveLayoutContext(width: 932, horizontalSizeClass: .regular, verticalSizeClass: .compact, platform: .macOS)
        #expect(policy.mode(for: mac) == .medium)
    }

    // MARK: iPad

    @Test func iPadLandscapeShowsEveryColumn() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1376, platform: .iOS), columns: inspectorShown)
        #expect(layout.mode == .wide)
        #expect(layout.visibleColumns == [.sidebar, .content, .detail, .inspector])
        #expect(layout.columnVisibility == .all)
        #expect(layout.inspectorStyle == .column)
        #expect(layout.showsInspectorColumn)
        #expect(!layout.showsInspectorSheet)
    }

    @Test func iPadPortraitCollapsesSidebarAndUsesSheet() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1032, platform: .iOS), columns: inspectorShown)
        #expect(layout.mode == .medium)
        #expect(layout.visibleColumns == [.content, .detail])
        #expect(layout.columnVisibility == .doubleColumn)
        #expect(layout.inspectorStyle == .sheet)
        #expect(layout.showsInspectorSheet)
    }

    @Test func mediumIPadKeepsSidebarAndUsesSheet() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1180, platform: .iOS), columns: inspectorShown)
        #expect(layout.mode == .medium)
        #expect(layout.visibleColumns == [.sidebar, .content, .detail])
        #expect(layout.inspectorStyle == .sheet)
    }

    @Test func slideOverShowsTheStackTop() {
        let context = AdaptiveLayoutContext(width: 375, horizontalSizeClass: .compact, platform: .iOS)
        let layout = policy.layout(in: context, columns: inspectorShown, compactColumn: .content)
        #expect(layout.isCollapsed)
        #expect(layout.visibleColumns == [.content])
        #expect(layout.compactColumn == .content)
        #expect(layout.inspectorStyle == .sheet)
        #expect(layout.showsInspectorSheet)
    }

    @Test func compactInspectorColumnMapsToDetail() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 400, platform: .iOS), compactColumn: .inspector)
        #expect(layout.visibleColumns == [.detail])
        #expect(layout.compactColumn == .detail)
    }

    // MARK: Mac

    @Test func macCollapsesAutomaticSidebarForInspector() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1180, platform: .macOS), columns: inspectorShown)
        #expect(layout.mode == .medium)
        #expect(layout.visibleColumns == [.content, .detail, .inspector])
        #expect(layout.inspectorStyle == .column)
        #expect(layout.columnVisibility == .doubleColumn)
    }

    @Test func macKeepsSidebarWithoutInspector() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1180, platform: .macOS))
        #expect(layout.visibleColumns == [.sidebar, .content, .detail])
        #expect(layout.inspectorStyle == .column)
        #expect(!layout.showsInspectorColumn)
    }

    @Test func explicitSidebarIsHonored() {
        let columns = AdaptiveColumnState(columnVisibility: .all, isInspectorPresented: true)
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1180, platform: .macOS), columns: columns)
        #expect(layout.visibleColumns == [.sidebar, .content, .detail, .inspector])
        #expect(layout.columnVisibility == .all)
    }

    @Test func sheetFallbackOnMac() {
        var custom = AdaptiveLayoutPolicy()
        custom.inspectorFallback = .sheet
        let layout = custom.layout(in: AdaptiveLayoutContext(width: 1180, platform: .macOS), columns: inspectorShown)
        #expect(layout.visibleColumns == [.sidebar, .content, .detail])
        #expect(layout.inspectorStyle == .sheet)
    }

    @Test func fallbackResolution() {
        #expect(AdaptiveInspectorFallback.automatic.resolved(for: .macOS) == .collapseSidebar)
        #expect(AdaptiveInspectorFallback.automatic.resolved(for: .iOS) == .sheet)
        #expect(AdaptiveInspectorFallback.sheet.resolved(for: .macOS) == .sheet)
    }

    // MARK: User choices

    @Test func hiddenSidebarStaysHiddenWhenWide() {
        let columns = AdaptiveColumnState(columnVisibility: .doubleColumn, isInspectorPresented: true)
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1600, platform: .iOS), columns: columns)
        #expect(layout.visibleColumns == [.content, .detail, .inspector])
        #expect(layout.columnVisibility == .doubleColumn)
    }

    @Test func detailOnly() {
        let columns = AdaptiveColumnState(columnVisibility: .detailOnly, isInspectorPresented: true)
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1032, platform: .iOS), columns: columns)
        #expect(layout.visibleColumns == [.detail, .inspector])
        #expect(layout.columnVisibility == .detailOnly)
    }

    @Test func dismissedInspectorIsNotVisible() {
        let layout = policy.layout(in: AdaptiveLayoutContext(width: 1376, platform: .iOS))
        #expect(layout.visibleColumns == [.sidebar, .content, .detail])
        #expect(!layout.showsInspectorColumn)
        #expect(!layout.showsInspectorSheet)
    }

    // MARK: Widths

    @Test func customWidthsMoveTheThresholds() {
        let compact = AdaptiveLayoutPolicy(
            sidebarWidth: AdaptiveColumnWidth(minimum: 180, ideal: 200, maximum: 260),
            contentWidth: AdaptiveColumnWidth(minimum: 220, ideal: 260, maximum: 320),
            detailWidth: AdaptiveColumnWidth(minimum: 320, ideal: 480, maximum: 2000),
            inspectorWidth: AdaptiveColumnWidth(minimum: 220, ideal: 240, maximum: 300)
        )
        #expect(compact.wideWidthThreshold == 1020)
        #expect(compact.mode(for: AdaptiveLayoutContext(width: 1032, platform: .iOS)) == .wide)
    }

    @Test func columnWidthIsClamped() {
        let width = AdaptiveColumnWidth(minimum: 300, ideal: 200, maximum: 100)
        #expect(width.minimum == 300)
        #expect(width.ideal == 300)
        #expect(width.maximum == 300)
    }

    @Test func columnsAreOrdered() {
        #expect(AdaptiveColumn.allCases.sorted() == [.sidebar, .content, .detail, .inspector])
        let layout = AdaptiveLayout(
            mode: .wide,
            width: 1400,
            visibleColumns: [.inspector, .sidebar, .detail],
            columnVisibility: .all,
            inspectorStyle: .column,
            isInspectorPresented: true,
            compactColumn: .sidebar
        )
        #expect(layout.visibleColumns == [.sidebar, .detail, .inspector])
    }
}
