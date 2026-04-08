import XCTest
@testable import ClaudeControlPane

final class AnyCodableValueTests: XCTestCase {
    func testParseJSONObjectAcceptsObjects() throws {
        let parsed = try AnyCodableValue.parseJSONObject(
            from: """
            {
              "enabled": true
            }
            """,
            emptyHandling: .clearField
        )

        XCTAssertEqual(parsed?.dictionaryValue?["enabled"]?.boolValue, true)
    }

    func testParseJSONObjectRejectsNonObjects() {
        for invalid in ["[]", "\"x\"", "1", "true", "null"] {
            XCTAssertThrowsError(
                try AnyCodableValue.parseJSONObject(from: invalid, emptyHandling: .clearField),
                "Expected non-object input \(invalid) to be rejected"
            ) { error in
                XCTAssertEqual(error.localizedDescription, "Expected a JSON object.")
            }
        }
    }

    func testParseJSONObjectClearsFieldForEmptyInput() throws {
        let parsed = try AnyCodableValue.parseJSONObject(from: "  \n", emptyHandling: .clearField)
        XCTAssertNil(parsed)
    }

    func testParseJSONObjectNormalizesEmptyObjectForMapEditors() throws {
        let parsed = try AnyCodableValue.parseJSONObject(from: "", emptyHandling: .emptyObject)
        XCTAssertEqual(parsed?.dictionaryValue?.count, 0)
    }
}
