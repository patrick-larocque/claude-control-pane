import SwiftUI

struct SettingsDetailView: View {
    @Bindable var manager: SettingsFileManager
    let title: String
    let locationSummary: String
    let locationPaths: [LocationInfoPath]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LocationInfoView(
                title: title,
                summary: locationSummary,
                paths: locationPaths
            )

            TabView {
                HooksView(manager: manager)
                    .tabItem { Label("Hooks", systemImage: "bell") }
                PermissionsView(manager: manager)
                    .tabItem { Label("Permissions", systemImage: "lock.shield") }
                EnvVarsView(manager: manager)
                    .tabItem { Label("Environment", systemImage: "terminal") }
                PluginsView(manager: manager)
                    .tabItem { Label("Plugins", systemImage: "puzzlepiece.extension") }
                AdvancedSettingsView(manager: manager)
                    .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
                ManagedTextEditorView(
                    title: title,
                    subtitle: "Raw JSON editor for the full settings file.",
                    filePath: manager.filePath,
                    defaultContent: "{}\n",
                    validationMode: .json
                )
                .tabItem { Label("JSON", systemImage: "curlybraces") }
            }
        }
        .padding()
        .navigationTitle(title)
        .overlay(alignment: .top) {
            if manager.hasError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(manager.errorMessage)
                        .font(.callout)
                }
                .padding(8)
                .background(.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                .padding(.top, 8)
            }
        }
    }
}
