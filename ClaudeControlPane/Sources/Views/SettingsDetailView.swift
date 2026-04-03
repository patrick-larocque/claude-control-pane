import SwiftUI

struct SettingsDetailView: View {
    @Bindable var manager: SettingsFileManager
    let title: String

    var body: some View {
        TabView {
            Text("Hooks (coming next)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Hooks", systemImage: "bell") }
            Text("Permissions (coming soon)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
            Text("Environment Variables (coming soon)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tabItem { Label("Environment", systemImage: "terminal") }
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
