import SwiftUI

struct SettingsDetailView: View {
    @Bindable var manager: SettingsFileManager
    let title: String

    var body: some View {
        TabView {
            HooksView(manager: manager)
                .tabItem { Label("Hooks", systemImage: "bell") }
            PermissionsView(manager: manager)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
            EnvVarsView(manager: manager)
                .tabItem { Label("Environment", systemImage: "terminal") }
            PluginsView(manager: manager)
                .tabItem { Label("Plugins", systemImage: "puzzlepiece.extension") }
        }
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
