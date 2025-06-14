import XCTest
@testable import ClipboardHistoryCore

final class StringExtensionTests: XCTestCase {
    
    // MARK: - truncated(to:trailing:) Tests
    
    func testTruncateShortString() {
        let shortString = "Hello"
        let result = shortString.truncated(to: 10)
        
        XCTAssertEqual(result, "Hello", "Short string should not be truncated")
    }
    
    func testTruncateLongString() {
        let longString = "This is a very long string that should be truncated"
        let result = longString.truncated(to: 10)
        
        XCTAssertEqual(result, "This is a ...", "Long string should be truncated with default trailing")
    }
    
    func testTruncateWithCustomTrailing() {
        let longString = "This is a very long string"
        let result = longString.truncated(to: 10, trailing: "***")
        
        XCTAssertEqual(result, "This is a ***", "Long string should be truncated with custom trailing")
    }
    
    func testTruncateExactLength() {
        let exactString = "1234567890"
        let result = exactString.truncated(to: 10)
        
        XCTAssertEqual(result, "1234567890", "String of exact length should not be truncated")
    }
    
    func testTruncateEmptyString() {
        let emptyString = ""
        let result = emptyString.truncated(to: 5)
        
        XCTAssertEqual(result, "", "Empty string should remain empty")
    }
    
    func testTruncateToZeroLength() {
        let string = "Hello"
        let result = string.truncated(to: 0)
        
        XCTAssertEqual(result, "...", "Truncating to zero should return only trailing")
    }
    
    func testTruncateWithEmptyTrailing() {
        let longString = "This is a long string"
        let result = longString.truncated(to: 10, trailing: "")
        
        XCTAssertEqual(result, "This is a ", "Truncating with empty trailing should work")
    }
    
    // MARK: - cleanedForDisplay() Tests
    
    func testCleanNewlines() {
        let stringWithNewlines = "Line 1\nLine 2\nLine 3"
        let result = stringWithNewlines.cleanedForDisplay()
        
        XCTAssertEqual(result, "Line 1 Line 2 Line 3", "Newlines should be replaced with spaces")
    }
    
    func testCleanCarriageReturns() {
        let stringWithCR = "Line 1\rLine 2\rLine 3"
        let result = stringWithCR.cleanedForDisplay()
        
        XCTAssertEqual(result, "Line 1 Line 2 Line 3", "Carriage returns should be replaced with spaces")
    }
    
    func testCleanTabs() {
        let stringWithTabs = "Column 1\tColumn 2\tColumn 3"
        let result = stringWithTabs.cleanedForDisplay()
        
        XCTAssertEqual(result, "Column 1 Column 2 Column 3", "Tabs should be replaced with spaces")
    }
    
    func testCleanMixedWhitespace() {
        let mixedString = "Text\n\twith\r\nmixed\t\rwhitespace"
        let result = mixedString.cleanedForDisplay()
        
        XCTAssertEqual(result, "Text  with  mixed  whitespace", "All whitespace types should be replaced")
    }
    
    func testCleanWithLeadingTrailingWhitespace() {
        let stringWithWhitespace = "  \n\tHello World\t\n  "
        let result = stringWithWhitespace.cleanedForDisplay()
        
        XCTAssertEqual(result, "Hello World", "Leading and trailing whitespace should be trimmed")
    }
    
    func testCleanEmptyString() {
        let emptyString = ""
        let result = emptyString.cleanedForDisplay()
        
        XCTAssertEqual(result, "", "Empty string should remain empty")
    }
    
    func testCleanOnlyWhitespace() {
        let whitespaceString = "\n\t\r   "
        let result = whitespaceString.cleanedForDisplay()
        
        XCTAssertEqual(result, "", "String with only whitespace should become empty")
    }
    
    func testCleanNormalString() {
        let normalString = "Hello World"
        let result = normalString.cleanedForDisplay()
        
        XCTAssertEqual(result, "Hello World", "Normal string should remain unchanged")
    }
    
    func testCleanStringWithMultipleSpaces() {
        let stringWithSpaces = "Hello    World"
        let result = stringWithSpaces.cleanedForDisplay()
        
        XCTAssertEqual(result, "Hello    World", "Multiple spaces should be preserved")
    }
    
    // MARK: - Combined Tests
    
    func testTruncateAndCleanCombined() {
        let messyLongString = "This is a very\nlong string\twith\rmixed whitespace that needs cleaning and truncation"
        let result = messyLongString.cleanedForDisplay().truncated(to: 30)
        
        XCTAssertEqual(result, "This is a very long string wit...", "Combined cleaning and truncation should work")
    }
    
    func testCleanAndTruncateCombined() {
        let messyString = "\n\tShort\r\n"
        let result = messyString.cleanedForDisplay().truncated(to: 10)
        
        XCTAssertEqual(result, "Short", "Short cleaned string should not be truncated")
    }
} 