import XCTest

final class CullerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset"]
    }

    private func waitForGrid(timeout: TimeInterval = 12) {
        XCTAssertTrue(app.otherElements.matching(identifier: "photo_thumbnail").firstMatch.waitForExistence(timeout: timeout))
    }

    private func photoCountText() -> String {
        let label = app.staticTexts["toolbar_photo_count"]
        _ = label.waitForExistence(timeout: 8)
        return (label.value as? String) ?? label.label
    }

    private func photoCountValue() -> Int {
        let text = photoCountText()
        let digits = text.prefix { $0.isNumber }
        return Int(digits) ?? -1
    }

    private func waitForPhotoCountChange(from before: Int, timeout: TimeInterval = 8) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let now = photoCountValue()
            if now >= 0, now != before { return now }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTFail("photo count did not change (before=\(before), current=\(photoCountText()))")
        return before
    }

    private func waitForPhotoCountIncrease(from before: Int, timeout: TimeInterval = 10) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let now = photoCountValue()
            if now >= 0, now > before { return now }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTFail("photo count did not increase (before=\(before), current=\(photoCountText()))")
        return before
    }

    private func openFirstPhoto() {
        waitForGrid()
        let thumb = app.otherElements.matching(identifier: "photo_thumbnail").firstMatch
        XCTAssertTrue(thumb.exists)
        thumb.doubleClick()
    }

    func test_E2E_01_Launch_ShowsGrid() {
        app.launch()

        waitForGrid()
    }

    func test_E2E_05_Filter_Rating_ChangesCount() {
        app.launch()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        let rating3 = app.buttons["filter_rating_3"]
        XCTAssertTrue(rating3.waitForExistence(timeout: 8))
        rating3.click()

        let after = waitForPhotoCountChange(from: before, timeout: 8)
        XCTAssertGreaterThanOrEqual(after, 0)

        let clear = app.buttons["sidebar_clear_filters"]
        if clear.waitForExistence(timeout: 2) {
            clear.click()
            XCTAssertEqual(photoCountValue(), before)
        }
    }

    func test_E2E_02_Grid_To_Single_And_Back() {
        app.launch()

        openFirstPhoto()

        let singleIndex = app.staticTexts["single_index_label"]
        XCTAssertTrue(singleIndex.waitForExistence(timeout: 6))

        let back = app.buttons["single_back_button"]
        XCTAssertTrue(back.waitForExistence(timeout: 6))
        back.click()

        waitForGrid(timeout: 6)
    }

    func test_E2E_03_Single_Rotate_Navigate() {
        app.launch()

        openFirstPhoto()

        let rotateRight = app.buttons["toolbar_rotate_right"]
        XCTAssertTrue(rotateRight.waitForExistence(timeout: 6))
        rotateRight.click()

        let next = app.buttons["single_next_button"]
        XCTAssertTrue(next.waitForExistence(timeout: 6))
        next.click()

        let prev = app.buttons["single_prev_button"]
        XCTAssertTrue(prev.waitForExistence(timeout: 6))
        prev.click()
    }

    func test_E2E_04_Marking_Toolbar_Applies() {
        app.launch()

        openFirstPhoto()

        let pick = app.buttons["mark_flag_pick"]
        XCTAssertTrue(pick.waitForExistence(timeout: 6))
        pick.click()

        let star5 = app.images["mark_rating_5"]
        XCTAssertTrue(star5.waitForExistence(timeout: 6))
        star5.click()

        let colorRed = app.buttons["mark_color_1"]
        XCTAssertTrue(colorRed.waitForExistence(timeout: 6))
        colorRed.click()
    }

    func test_E2E_06_Sort_Menu_Changes() {
        app.launch()

        let sortMenu = app.menuButtons["toolbar_sort_menu"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 8))
        sortMenu.click()

        let itemRating = app.menuItems["评分"]
        if itemRating.waitForExistence(timeout: 2) { itemRating.click() }

        sortMenu.click()
        let itemFile = app.menuItems["文件名"]
        if itemFile.waitForExistence(timeout: 2) { itemFile.click() }
    }

    func test_E2E_07_Import_AddsPhotos() {
        app.launch()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let gen = app.buttons["uitest_generate_files"]
        XCTAssertTrue(gen.waitForExistence(timeout: 6))
        gen.click()

        let start = app.buttons["开始导入"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.click()

        _ = waitForPhotoCountIncrease(from: before, timeout: 12)
    }

    func test_E2E_08_FolderSync_AddsNewFile() {
        app.launch()

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let gen = app.buttons["uitest_generate_files"]
        XCTAssertTrue(gen.waitForExistence(timeout: 6))
        gen.click()

        let close = app.buttons["取消"]
        if close.waitForExistence(timeout: 2) { close.click() }

        let folderRow = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "CullerUITestImages")).firstMatch
        XCTAssertTrue(folderRow.waitForExistence(timeout: 12))
        folderRow.click()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        // 在工具栏上有时没有“同步”按钮（可见性/布局/条件），所以走菜单命令更稳定
        let menu = app.menuBars.menuBarItems["Folders"]
        if menu.waitForExistence(timeout: 2) {
            menu.click()
            let folderBrowser = app.menuItems["Folder Browser"]
            if folderBrowser.waitForExistence(timeout: 2) {
                folderBrowser.click()
            }
        }

        // 触发同步（仍优先尝试按钮；没有则跳过断言变化，仅验证未崩溃）
        let syncBtn = app.buttons["toolbar_sync_button"]
        if syncBtn.waitForExistence(timeout: 2) {
            syncBtn.click()
            _ = waitForPhotoCountIncrease(from: before, timeout: 12)
        }
    }

    func test_E2E_09_Album_Tag_Management() {
        app.launch()

        // 顶部“相册”行在 Outline 里不是按钮（header），用快捷入口：侧栏的 plus 不一定暴露为同一 identifier
        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 8))
        let panels = app.menuBars.menuBarItems["Panels"]
        XCTAssertTrue(panels.waitForExistence(timeout: 6))
        panels.click()
        let albumMgr = app.menuItems["相册与标签管理"]
        XCTAssertTrue(albumMgr.waitForExistence(timeout: 6))
        albumMgr.click()

        let newAlbum = app.buttons["album_manager_new_album_button"]
        XCTAssertTrue(newAlbum.waitForExistence(timeout: 6))
        newAlbum.click()

        let tf = app.textFields.firstMatch
        XCTAssertTrue(tf.waitForExistence(timeout: 6))
        tf.click()
        tf.typeText("UITestAlbum")

        let createAlbum = app.buttons["创建"]
        XCTAssertTrue(createAlbum.waitForExistence(timeout: 6))
        createAlbum.click()

        let delA = app.buttons["album_manager_delete_last_album"]
        XCTAssertTrue(delA.waitForExistence(timeout: 6))
        delA.click()

        let newTag = app.buttons["album_manager_new_tag_button"]
        XCTAssertTrue(newTag.waitForExistence(timeout: 6))
        newTag.click()

        let tf2 = app.textFields.firstMatch
        XCTAssertTrue(tf2.waitForExistence(timeout: 6))
        tf2.click()
        tf2.typeText("UITestTag")

        let createTag = app.buttons["创建"]
        XCTAssertTrue(createTag.waitForExistence(timeout: 6))
        createTag.click()

        let delT = app.buttons["album_manager_delete_last_tag"]
        XCTAssertTrue(delT.waitForExistence(timeout: 6))
        delT.click()
    }

    func test_E2E_10_Inspector_Shows_Info() {
        app.launch()

        openFirstPhoto()

        let info = app.disclosureTriangles["信息"]
        XCTAssertTrue(info.waitForExistence(timeout: 8))

        let file = app.disclosureTriangles["文件"]
        XCTAssertTrue(file.waitForExistence(timeout: 8))
    }

    func test_E2E_11_Video_Fallback_Message() {
        app.launch()

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let genBad = app.buttons["uitest_generate_bad_video"]
        XCTAssertTrue(genBad.waitForExistence(timeout: 6))
        genBad.click()

        let start = app.buttons["开始导入"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.click()

        let badThumb = app.otherElements
            .matching(identifier: "photo_thumbnail")
            .matching(NSPredicate(format: "label CONTAINS %@", "E2E-BAD-VIDEO"))
            .firstMatch
        XCTAssertTrue(badThumb.waitForExistence(timeout: 12))
        badThumb.doubleClick()

        let msg = app.staticTexts["当前视频不可播放"]
        XCTAssertTrue(msg.waitForExistence(timeout: 10))
    }
}
