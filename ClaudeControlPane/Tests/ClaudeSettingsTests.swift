import XCTest
@testable import ClaudeControlPane

final class ClaudeSettingsTests: XCTestCase {
    func testAdvancedSettingsRoundTripPreservesStructuredFields() throws {
        let json = """
        {
          "model": "claude-sonnet-4-6",
          "language": "english",
          "outputStyle": "Explanatory",
          "statusLine": {
            "type": "command",
            "command": "~/.claude/statusline.sh"
          },
          "sandbox": {
            "enabled": true,
            "network": {
              "allowedDomains": ["github.com"]
            }
          },
          "voiceEnabled": true,
          "includeGitInstructions": false,
          "useAutoModeDuringPlan": true
        }
        """.data(using: .utf8)!

        let settings = try ClaudeSettings.decode(from: json)
        XCTAssertEqual(settings.model, "claude-sonnet-4-6")
        XCTAssertEqual(settings.language, "english")
        XCTAssertEqual(settings.outputStyle, "Explanatory")
        XCTAssertEqual(settings.voiceEnabled, true)
        XCTAssertEqual(settings.includeGitInstructions, false)
        XCTAssertEqual(settings.useAutoModeDuringPlan, true)
        XCTAssertEqual(settings.statusLine?.dictionaryValue?["type"]?.stringValue, "command")
        XCTAssertEqual(settings.sandbox?.dictionaryValue?["enabled"]?.boolValue, true)

        let encoded = try settings.encode()
        let decodedAgain = try ClaudeSettings.decode(from: encoded)
        XCTAssertEqual(decodedAgain, settings)
    }

    func testHookRoundTripPreservesExtendedFields() throws {
        let json = """
        {
          "hooks": {
            "PostToolUseFailure": [
              {
                "matcher": "Bash",
                "hooks": [
                  {
                    "type": "http",
                    "url": "https://hooks.example.com/failure",
                    "if": "Bash(git *)",
                    "timeout": 10,
                    "headers": {
                      "X-Test": "1"
                    }
                  }
                ]
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let settings = try ClaudeSettings.decode(from: json)
        let hook = try XCTUnwrap(settings.hooks["PostToolUseFailure"]?.first?.hooks.first)
        XCTAssertEqual(hook.type, "http")
        XCTAssertEqual(hook.url, "https://hooks.example.com/failure")
        XCTAssertEqual(hook.ifCondition, "Bash(git *)")
        XCTAssertEqual(hook.timeout, 10)
        XCTAssertEqual(hook.extraFields["headers"]?.dictionaryValue?["X-Test"]?.stringValue, "1")

        let encoded = try settings.encode()
        let decodedAgain = try ClaudeSettings.decode(from: encoded)
        let hookAgain = try XCTUnwrap(decodedAgain.hooks["PostToolUseFailure"]?.first?.hooks.first)
        XCTAssertEqual(hookAgain.extraFields["headers"]?.dictionaryValue?["X-Test"]?.stringValue, "1")
    }

    func testHookTypeTransitionsClearInactivePrimaryFields() throws {
        var hook = Hook(
            type: "command",
            command: "echo hello",
            model: "claude-sonnet-4-6",
            ifCondition: "Bash(git *)",
            timeout: 10,
            extraFields: [
                "headers": .dictionary([
                    "X-Test": .string("1")
                ])
            ]
        )

        hook.normalizePrimaryPayload(for: "http")
        XCTAssertEqual(hook.type, "http")
        XCTAssertEqual(hook.url, "echo hello")
        XCTAssertEqual(hook.command, "")
        XCTAssertNil(hook.prompt)

        hook.updatePrimaryValue("https://hooks.example.com/failure")
        hook.normalizePrimaryPayload(for: "prompt")
        XCTAssertEqual(hook.type, "prompt")
        XCTAssertEqual(hook.prompt, "https://hooks.example.com/failure")
        XCTAssertEqual(hook.command, "")
        XCTAssertNil(hook.url)

        let encoded = try JSONEncoder().encode(hook)
        let encodedObject = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNil(encodedObject["command"])
        XCTAssertNil(encodedObject["url"])
        XCTAssertEqual(encodedObject["prompt"] as? String, "https://hooks.example.com/failure")
        XCTAssertEqual(encodedObject["model"] as? String, "claude-sonnet-4-6")
        XCTAssertEqual(encodedObject["if"] as? String, "Bash(git *)")
        XCTAssertEqual(encodedObject["timeout"] as? Int, 10)

        let decoded = try JSONDecoder().decode(Hook.self, from: encoded)
        XCTAssertEqual(decoded.prompt, "https://hooks.example.com/failure")
        XCTAssertEqual(decoded.model, "claude-sonnet-4-6")
        XCTAssertEqual(decoded.ifCondition, "Bash(git *)")
        XCTAssertEqual(decoded.timeout, 10)
        XCTAssertEqual(decoded.extraFields["headers"]?.dictionaryValue?["X-Test"]?.stringValue, "1")
    }
}
