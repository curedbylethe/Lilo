import AppKit
import XCTest
@testable import Lilo

/// Every chrome load, including a reload, must re-seed the fresh UI and leave the sidebar unlocked.
@MainActor
final class ChromeReloadResetTests: XCTestCase {
    private var browserContext: TemporaryBrowserContext!

    override func setUp() async throws {
        try await super.setUp()
        browserContext = try await TemporaryBrowserContext()
    }

    override func tearDown() {
        browserContext.tearDown()
        browserContext = nil
        super.tearDown()
    }

    func testAChromeReloadSendsTheInitialStateAgain() throws {
        let context = browserContext.context
        let profileId = try context.profileManager!.createProfile(name: "P").id
        let space = try context.spaceManager!.createSpace(name: "S", profileId: profileId, isPrivate: false)
        let window = makeTestWindow(context, showing: space.id)
        XCTAssertNotNil(window.createTabStateFirst(url: nil))
        let events = BridgeEventRecorder(window.bridgeRouter)

        window.finishSessionRestore()
        window.handleChromeReady()
        drainMainQueue()
        XCTAssertEqual(events.data("initialState").count, 1)

        // What the bootstrap script posts after the chrome reloads.
        window.handleChromeReady()
        drainMainQueue()
        XCTAssertEqual(events.data("initialState").count, 2)
    }

    func testAChromeReloadReleasesTheSidebarCollapseLock() throws {
        let context = browserContext.context
        let profileId = try context.profileManager!.createProfile(name: "P").id
        let space = try context.spaceManager!.createSpace(name: "S", profileId: profileId, isPrivate: false)
        let window = makeTestWindow(context, showing: space.id)

        window.setSidebarCollapseLocked(true)
        XCTAssertTrue(window.sidebarCollapseLocked)

        window.handleChromeReady()

        XCTAssertFalse(window.sidebarCollapseLocked)
        let visibleBefore = window.sidebarVisible
        window.toggleSidebar()
        XCTAssertNotEqual(window.sidebarVisible, visibleBefore)
    }
}
