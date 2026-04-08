import Foundation

struct DiagnosticsReport: Sendable, Equatable {
    struct Check: Identifiable, Sendable, Equatable {
        enum Status: String, Sendable {
            case ok
            case warning
            case info
        }

        let id: String
        let title: String
        let status: Status
        let message: String
        let source: String
    }

    let checks: [Check]
}

enum DiagnosticsService {
    static func generate(
        machineSettings: ClaudeSettings,
        shellEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        resolvedClaudeBinary: String? = nil
    ) -> DiagnosticsReport {
        let shellPath = shellEnvironment["SHELL"] ?? ""
        let shellPathValue = shellEnvironment["PATH"] ?? ""
        let shellEntries = shellPathValue.split(separator: ":").map(String.init)
        let claudeBinary = resolvedClaudeBinary ?? resolveBinary(named: "claude", searchPaths: shellEntries)
        let claudeEnvPath = machineSettings.env["PATH"]
        let claudeEnvEntries = claudeEnvPath?.split(separator: ":").map(String.init) ?? []

        var checks: [DiagnosticsReport.Check] = []

        if let claudeBinary {
            checks.append(.init(
                id: "claude-on-path",
                title: "Claude CLI on shell PATH",
                status: .ok,
                message: claudeBinary,
                source: "shell PATH"
            ))
        } else {
            checks.append(.init(
                id: "claude-on-path",
                title: "Claude CLI on shell PATH",
                status: .warning,
                message: "No `claude` binary was found on the current shell PATH.",
                source: "shell PATH"
            ))
        }

        if let claudeEnvPath {
            let includesHomebrew = claudeEnvEntries.contains("/opt/homebrew/bin")
            let includesLocalBin = claudeEnvEntries.contains { $0.hasSuffix("/.local/bin") }
            let status: DiagnosticsReport.Check.Status = includesHomebrew && includesLocalBin ? .ok : .warning
            checks.append(.init(
                id: "claude-settings-path",
                title: "Claude env PATH",
                status: status,
                message: claudeEnvPath,
                source: "~/.claude/settings.json env.PATH"
            ))
        } else {
            checks.append(.init(
                id: "claude-settings-path",
                title: "Claude env PATH",
                status: .info,
                message: "No PATH override is configured in `~/.claude/settings.json`.",
                source: "~/.claude/settings.json"
            ))
        }

        if let claudeBinary,
           claudeEnvPath != nil,
           let binaryDirectory = URL(fileURLWithPath: claudeBinary).deletingLastPathComponent().path.removingPercentEncoding {
            let status: DiagnosticsReport.Check.Status = claudeEnvEntries.contains(binaryDirectory) ? .ok : .warning
            checks.append(.init(
                id: "binary-visible-to-claude",
                title: "Claude binary visible to Claude env",
                status: status,
                message: status == .ok
                    ? "\(binaryDirectory) is present in Claude's PATH override."
                    : "\(binaryDirectory) is on the shell PATH but missing from Claude's env.PATH.",
                source: "shell PATH + settings env"
            ))
        }

        let optionMetaMessage: String
        if shellPath.contains("zsh") {
            optionMetaMessage = "For macOS shortcuts like Option+T and Alt+B/F/Y, set Option as Meta in Terminal.app, iTerm2, or VS Code terminal."
        } else {
            optionMetaMessage = "Check the terminal docs for Option/Alt key handling if Claude shortcuts do not work."
        }
        checks.append(.init(
            id: "option-meta",
            title: "macOS terminal shortcut guidance",
            status: .info,
            message: optionMetaMessage,
            source: "Claude Code terminal docs"
        ))

        checks.append(.init(
            id: "no-flicker",
            title: "Fullscreen rendering guidance",
            status: .info,
            message: "If you see flicker or scroll jumps during long sessions, the docs recommend `CLAUDE_CODE_NO_FLICKER=1`.",
            source: "Claude Code terminal docs"
        ))

        return DiagnosticsReport(checks: checks)
    }

    private static func resolveBinary(named name: String, searchPaths: [String]) -> String? {
        for path in searchPaths {
            let candidate = URL(fileURLWithPath: path).appendingPathComponent(name).path
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }
}
