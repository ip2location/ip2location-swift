import XCTest
@testable import IP2LocationSwift

final class IP2LanguageTests: XCTestCase {

    /// Every language documented by the API (ISO 639-1 values) must be present.
    func testAllDocumentedLanguagesAreCovered() {
        let documented: Set<String> = [
            "ar", "cs", "da", "de", "en", "es", "et", "fi", "fr", "ga",
            "it", "ja", "ko", "ms", "nl", "pt", "ru", "sv", "tr", "vi",
            "zh-cn", "zh-tw"
        ]
        XCTAssertEqual(Set(IP2Language.allCases.map(\.rawValue)), documented)
    }

    func testRepresentativeRawValues() {
        XCTAssertEqual(IP2Language.english.rawValue, "en")
        XCTAssertEqual(IP2Language.korean.rawValue, "ko")
        XCTAssertEqual(IP2Language.japanese.rawValue, "ja")
        XCTAssertEqual(IP2Language.chineseSimplified.rawValue, "zh-cn")
        XCTAssertEqual(IP2Language.chineseTraditional.rawValue, "zh-tw")
    }

    func testRawValueInitialization() {
        XCTAssertEqual(IP2Language(rawValue: "de"), .german)
        XCTAssertNil(IP2Language(rawValue: "xx"))
    }
}
