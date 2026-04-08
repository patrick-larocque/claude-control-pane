import XCTest
@testable import ClaudeControlPane

final class ClaudeGlobalConfigTests: XCTestCase {
    func testLocalMcpServersAreReadAndWrittenFromProjectsMap() {
        var config = ClaudeGlobalConfig(
            extraFields: [
                "projects": .dictionary([
                    "/tmp/example": .dictionary([
                        "mcpServers": .dictionary([
                            "github": .dictionary([
                                "command": .string("npx"),
                                "args": .array([.string("-y"), .string("@modelcontextprotocol/server-github")])
                            ])
                        ])
                    ])
                ])
            ]
        )

        XCTAssertEqual(
            config.localMcpServers(for: "/tmp/example")?.dictionaryValue?["github"]?.dictionaryValue?["command"]?.stringValue,
            "npx"
        )

        config.setLocalMcpServers(
            .dictionary([
                "filesystem": .dictionary([
                    "command": .string("node")
                ])
            ]),
            for: "/tmp/example"
        )

        XCTAssertEqual(
            config.localMcpServers(for: "/tmp/example")?.dictionaryValue?["filesystem"]?.dictionaryValue?["command"]?.stringValue,
            "node"
        )
    }

    func testEmptyLocalMcpServersPersistAsEmptyObject() {
        var config = ClaudeGlobalConfig()

        config.setLocalMcpServers(.dictionary([:]), for: "/tmp/example")

        XCTAssertEqual(config.localMcpServers(for: "/tmp/example")?.dictionaryValue?.count, 0)
        XCTAssertNotNil(config.extraFields["projects"]?.dictionaryValue?["/tmp/example"]?.dictionaryValue?["mcpServers"]?.dictionaryValue)
    }
}
