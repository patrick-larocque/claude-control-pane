import SwiftUI

struct LocationInfoPath: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let path: String
}

struct LocationInfoView: View {
    let title: String
    let summary: String
    let paths: [LocationInfoPath]
    var recommended = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(title, systemImage: "folder")
                    .font(.headline)
                if recommended {
                    Text("Recommended by docs")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                }
            }

            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(paths) { entry in
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(entry.path)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}
