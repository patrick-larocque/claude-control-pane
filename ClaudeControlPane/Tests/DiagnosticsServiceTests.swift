import XCTest
@testable import ClaudeControlPane

final class DiagnosticsServiceTests: XCTestCase {
    func testDiagnosticsWarnWhenClaudeEnvPathMissesBinaryDirectory() {
        let machineSettings = ClaudeSettings(
            env: [
                "PATH": "/usr/bin:/bin"
            ]
        )

        let report = DiagnosticsService.generate(
            machineSettings: machineSettings,
            shellEnvironment: [
                "SHELL": "/bin/zsh",
                "PATH": "/tmp/fake/bin:/usr/bin:/bin"
            ],
            resolvedClaudeBinary: "/tmp/fake/bin/claude"
        )

        let binaryCheck = report.checks.first { $0.id == "binary-visible-to-claude" }
        XCTAssertEqual(binaryCheck?.status, .warning)
    }

    func testDiagnosticsPassWhenClaudeEnvIncludesBinaryDirectory() {
        let machineSettings = ClaudeSettings(
            env: [
                "PATH": "/tmp/fake/bin:/usr/bin:/bin:/opt/homebrew/bin:/Users/test/.local/bin"
            ]
        )

        let report = DiagnosticsService.generate(
            machineSettings: machineSettings,
            shellEnvironment: [
                "SHELL": "/bin/zsh",
                "PATH": "/tmp/fake/bin:/usr/bin:/bin"
            ],
            resolvedClaudeBinary: "/tmp/fake/bin/claude"
        )

        let envCheck = report.checks.first { $0.id == "claude-settings-path" }
        XCTAssertEqual(envCheck?.status, .ok)
    }
}
