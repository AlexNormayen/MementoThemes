import SwiftUI
import AVKit
import PhotosUI

struct RootThemeView: View {
    @EnvironmentObject var repository: ThemeRepository
    @State private var selectedTab: Int = 0

    var activeTheme: ThemeManifest {
        repository.installedThemes.first(where: { $0.id == repository.activeThemeId })
            ?? repository.installedThemes.first
            ?? ThemeManifest(
                id: "plague-doctor",
                title: "Чумной Доктор · Memento Mori",
                subtitle: "Готический собор, живые вороны и янтарный фонарь",
                author: "Dark Tarkhan",
                version: "1.0.0",
                accentHex: "#E8943A",
                secondaryHex: "#8A6BB8",
                backgroundHex: "#0E0C14",
                widgetQuote: "MEMENTO MORI",
                widgetSubquote: "Свет фонаря среди тумана и ворон",
                lockscreenFile: "lockscreen.png",
                homescreenFile: "homescreen.png",
                liveVideoFile: "live_wallpaper.mp4",
                fonts: [],
                icons: []
            )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ThemeStudioTabView(theme: activeTheme)
                .tabItem {
                    Label("Студия темы", systemImage: "moon.stars.fill")
                }
                .tag(0)

            IconsAndFontsInstallerTabView(theme: activeTheme)
                .tabItem {
                    Label("Иконки и шрифты", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            ThemeCatalogAndImportTabView()
                .tabItem {
                    Label("Каталог тем", systemImage: "arrow.down.doc.fill")
                }
                .tag(2)

            WidgetCustomizerTabView(theme: activeTheme)
                .tabItem {
                    Label("Виджеты", systemImage: "rectangle.3.group.fill")
                }
                .tag(3)
        }
        .tint(Color(hex: activeTheme.accentHex))
    }
}
