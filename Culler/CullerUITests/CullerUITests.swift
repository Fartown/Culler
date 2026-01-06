import XCTest

final class CullerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
    }

    func test_E2E_01_Launch_ShowsGrid() {
        // E2E_CASE:E2E-01
        app.launch()

        // Photo thumbnails exist (PhotoGridView)
        XCTAssertTrue(app.otherElements.matching(identifier: "photo_thumbnail").firstMatch.waitForExistence(timeout: 8))
    }

    func test_E2E_05_Filter_Rating_ChangesCount() {
        // E2E_CASE:E2E-05
        app.launch()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = countLabel.label

        let rating3 = app.images["filter_rating_3"]
        XCTAssertTrue(rating3.waitForExistence(timeout: 8))
        rating3.click()

        let after = countLabel.label
        XCTAssertNotEqual(before, after)

        // Clear filters button may appear
        let clear = app.buttons["sidebar_clear_filters"]
        if clear.waitForExistence(timeout: 2) {
            clear.click()
            XCTAssertEqual(countLabel.label, before)
        }
    }
}

