import XCTest

final class ClipboardUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testMenuBarIconExists() {
        // Verify menu bar icon exists
        let menuBarIcon = app.statusItems["Clipboard History"]
        XCTAssertTrue(menuBarIcon.exists)
    }
    
    func testSettingsWindow() {
        // Click menu bar icon
        let menuBarIcon = app.statusItems["Clipboard History"]
        menuBarIcon.click()
        
        // Click settings button
        let settingsButton = app.buttons["Settings"]
        settingsButton.click()
        
        // Verify settings window appears
        let settingsWindow = app.windows["Settings"]
        XCTAssertTrue(settingsWindow.exists)
        
        // Verify shortcut configuration exists
        let shortcutButton = settingsWindow.buttons["Paste History Shortcut:"]
        XCTAssertTrue(shortcutButton.exists)
    }
    
    func testClipboardHistoryWindow() {
        // Click menu bar icon
        let menuBarIcon = app.statusItems["Clipboard History"]
        menuBarIcon.click()
        
        // Verify history window appears
        let historyWindow = app.windows["Clipboard History"]
        XCTAssertTrue(historyWindow.exists)
        
        // Verify search field exists
        let searchField = historyWindow.textFields["Search"]
        XCTAssertTrue(searchField.exists)
        
        // Verify clear button exists
        let clearButton = historyWindow.buttons["Clear History"]
        XCTAssertTrue(clearButton.exists)
    }
    
    func testSearchFunctionality() {
        // Click menu bar icon
        let menuBarIcon = app.statusItems["Clipboard History"]
        menuBarIcon.click()
        
        // Get search field
        let searchField = app.textFields["Search"]
        
        // Enter search text
        searchField.click()
        searchField.typeText("test")
        
        // Verify search is working
        // Note: This is a basic test as we can't easily verify the filtered results
        XCTAssertEqual(searchField.value as? String, "test")
    }
} 