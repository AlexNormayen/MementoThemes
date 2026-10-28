import SwiftUI

@main
struct MementoThemesApp: App {
    @StateObject private var repository = ThemeRepository.shared

    var body: some Scene {
        WindowGroup {
            RootThemeView()
                .environmentObject(repository)
                .preferredColorScheme(.dark)
        }
    }
}
