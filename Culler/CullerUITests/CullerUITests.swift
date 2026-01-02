import XCTest

final class CullerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        addUIInterruptionMonitor(withDescription: "Handle external interruptions") { _ in
            self.app.activate()
            return true
        }
    }

    func testE2E_Screenshots() {
        app.launch()

        capture("01_home_grid")
        openImportSheet()
        capture("02_import_sheet")
        closeSheetIfNeeded()

        selectFirstPhotoIfExists()
        capture("02b_grid_selected")

        switchToSingleView()
        capture("03_single_view")

        switchToFullscreen()
        capture("04_fullscreen")
        exitFullscreen()

        applyMarkingActionsIfPossible()
        capture("04b_after_marking")

        openAlbumManager()
        capture("05_album_manager")

        resetDemoData()
        capture("06_after_reset")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func openImportSheet() {
        let importButton = app.buttons["Import"]
        if importButton.waitForExistence(timeout: 3) {
            importButton.click()
        }
    }

    private func closeSheetIfNeeded() {
        let cancel = app.buttons["Cancel"]
        if cancel.waitForExistence(timeout: 2) {
            cancel.click()
        }
    }

    private func selectFirstPhotoIfExists() {
        let first = app.otherElements.matching(identifier: "photo_thumbnail").firstMatch
        if first.waitForExistence(timeout: 3) {
            first.click()
        }
    }

    private func switchToSingleView() {
        let single = app.buttons["toolbar_single"]
        if single.waitForExistence(timeout: 2) {
            single.click()
        }
    }

    private func switchToFullscreen() {
        let full = app.buttons["toolbar_fullscreen"]
        if full.waitForExistence(timeout: 2) {
            full.click()
        }
    }

    private func exitFullscreen() {
        let close = app.buttons.matching(identifier: "fullscreen_exit").firstMatch
        if close.waitForExistence(timeout: 2) {
            close.click()
            return
        }
        app.typeKey(.escape, modifierFlags: [])
    }

    private func openAlbumManager() {
        let menuItem = app.menuItems["Open Album Manager"]
        if menuItem.waitForExistence(timeout: 2) {
            menuItem.click()
            return
        }
        app.typeKey("m", modifierFlags: [.command, .shift])
    }

    private func resetDemoData() {
        let menuItem = app.menuItems["Reset Demo Data"]
        if menuItem.waitForExistence(timeout: 2) {
            menuItem.click()
            return
        }
        app.typeKey("r", modifierFlags: [.command, .shift])
    }

    private func applyMarkingActionsIfPossible() {
        let pick = app.buttons["mark_flag_pick"]
        if pick.waitForExistence(timeout: 2) {
            pick.click()
        }

        let rating3 = app.buttons["mark_rating_3"]
        if rating3.waitForExistence(timeout: 2) {
            rating3.click()
        }

        let colorBlue = app.buttons["mark_color_4"]
        if colorBlue.waitForExistence(timeout: 2) {
            colorBlue.click()
        }
    }

    func testE2E_GridScrollMemory() {
        app.launch()

        app.typeKey("a", modifierFlags: [.command, .shift])
        for _ in 0..<5 { app.typeKey(.downArrow, modifierFlags: [.shift]) }

        let singleBtn = app.buttons["toolbar_single"]
        if singleBtn.waitForExistence(timeout: 2) {
            singleBtn.click()
        }

        let gridButton = app.buttons["toolbar_grid"]
        if gridButton.waitForExistence(timeout: 3) {
            gridButton.click()
        }

        XCTAssertTrue(app.staticTexts["• 1 selected"].waitForExistence(timeout: 3))

        if singleBtn.waitForExistence(timeout: 2) { singleBtn.click() }
    }
}
