import SwiftUI

struct ManagedTextEditorView: View {
    let title: String
    let subtitle: String
    let filePath: String
    let defaultContent: String
    let validationMode: TextFileManager.ValidationMode

    @State private var manager: TextFileManager

    init(
        title: String,
        subtitle: String,
        filePath: String,
        defaultContent: String = "",
        validationMode: TextFileManager.ValidationMode = .none
    ) {
        self.title = title
        self.subtitle = subtitle
        self.filePath = filePath
        self.defaultContent = defaultContent
        self.validationMode = validationMode
        _manager = State(initialValue: TextFileManager(
            filePath: filePath,
            defaultContent: defaultContent,
            validationMode: validationMode
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(filePath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            TextEditor(text: Binding(
                get: { manager.content },
                set: { manager.setContent($0) }
            ))
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 280)
            .padding(8)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                if manager.hasError {
                    Label(manager.errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if manager.fileExists {
                    Text("Watching file for external changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("File does not exist yet. It will be created on save.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Reload") {
                    manager.loadFromDisk()
                }
                .buttonStyle(.borderless)

                Button("Save") {
                    manager.saveToDisk()
                }
                .disabled(!manager.hasUnsavedChanges)
            }
        }
        .onDisappear {
            manager.cleanup()
        }
    }
}

struct JSONObjectFieldView: View {
    let title: String
    let subtitle: String
    let currentValue: AnyCodableValue?
    var onSave: (AnyCodableValue?) -> Void

    @State private var text: String
    @State private var errorMessage = ""

    init(title: String, subtitle: String, currentValue: AnyCodableValue?, onSave: @escaping (AnyCodableValue?) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.currentValue = currentValue
        self.onSave = onSave
        _text = State(initialValue: Self.editorText(for: currentValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.system(.callout, design: .monospaced))
                .frame(minHeight: 120)
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))

            HStack {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("Reset") {
                    text = Self.editorText(for: currentValue)
                    errorMessage = ""
                }
                .buttonStyle(.borderless)

                Button("Save") {
                    do {
                        let parsed = try AnyCodableValue.parseJSONObject(from: text, emptyHandling: .clearField)
                        onSave(parsed)
                        text = Self.editorText(for: parsed)
                        errorMessage = ""
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .onChange(of: currentValue) { _, newValue in
            text = Self.editorText(for: newValue)
            errorMessage = ""
        }
    }

    private static func editorText(for value: AnyCodableValue?) -> String {
        guard let value else { return "" }
        return AnyCodableValue.jsonString(from: value)
    }
}
