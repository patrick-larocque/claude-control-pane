import SwiftUI

struct DiagnosticsView: View {
    let report: DiagnosticsReport
    let machineSettingsPath: String
    let machineGlobalConfigPath: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LocationInfoView(
                    title: "Diagnostics",
                    summary: "These checks compare the live shell environment with Claude Code’s documented config locations on macOS.",
                    paths: [
                        .init(label: "Machine settings", path: machineSettingsPath),
                        .init(label: "Machine global config", path: machineGlobalConfigPath)
                    ]
                )

                Form {
                    Section("Shell and Environment") {
                        ForEach(report.checks) { check in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: icon(for: check.status))
                                        .foregroundStyle(color(for: check.status))
                                    Text(check.title)
                                        .fontWeight(.medium)
                                }
                                Text(check.message)
                                    .font(.callout)
                                Text(check.source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Section("macOS Terminal Guidance") {
                        Text("Terminal.app: enable “Use Option as Meta Key” for Claude shortcut support.")
                        Text("iTerm2: set Left/Right Option key to “Esc+” and enable Notification Center Alerts if you want desktop notifications.")
                        Text("VS Code terminal: set `terminal.integrated.macOptionIsMeta` to `true` and use `/terminal-setup` if Shift+Enter does not work.")
                        Text("If long sessions flicker or jump, the docs recommend `CLAUDE_CODE_NO_FLICKER=1`.")
                    }

                    Section("Where Features Live") {
                        Text("Shell PATH and terminal behavior are external to Claude JSON files.")
                        Text("Machine-wide Claude preferences live in `~/.claude/settings.json` and `~/.claude.json`.")
                        Text("Workspace-shared settings live in `.claude/settings.json` and `.mcp.json`.")
                        Text("Workspace-local overrides live in `.claude/settings.local.json` and `CLAUDE.local.md`.")
                    }
                }
                .formStyle(.grouped)
            }
        }
    }

    private func icon(for status: DiagnosticsReport.Check.Status) -> String {
        switch status {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private func color(for status: DiagnosticsReport.Check.Status) -> Color {
        switch status {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .info:
            return .blue
        }
    }
}
