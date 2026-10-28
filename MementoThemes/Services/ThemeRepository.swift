import Foundation
import SwiftUI

@MainActor
final class ThemeRepository: ObservableObject {
    static let shared = ThemeRepository()

    @Published var installedThemes: [ThemeManifest] = []
    @Published var remoteThemes: [ThemeManifest] = []
    @Published var activeThemeId: String = "plague-doctor"
    @Published var catalogURLString: String = "https://at.theinquisitor.ru/memento/catalog.json"
    @Published var isLoadingCatalog: Bool = false
    @Published var statusMessage: String?

    private let fm = FileManager.default

    init() {
        if let savedURL = UserDefaults.standard.string(forKey: "memento_catalog_url"), !savedURL.isEmpty {
            catalogURLString = savedURL
        }
        ensureBundledPlagueDoctorInstalled()
        reloadInstalledThemes()
    }

    var themesRootDir: URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("InstalledThemes", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func themeDirectory(for themeId: String) -> URL {
        themesRootDir.appendingPathComponent(themeId, isDirectory: true)
    }

    /// Copies the built-in "Plague Doctor · Memento Mori" theme from the app bundle into `Documents/InstalledThemes/plague-doctor` on first launch.
    func ensureBundledPlagueDoctorInstalled() {
        let destDir = themeDirectory(for: "plague-doctor")
        let manifestURL = destDir.appendingPathComponent("theme.json")
        guard !fm.fileExists(atPath: manifestURL.path) else { return }

        try? fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: destDir.appendingPathComponent("icons"), withIntermediateDirectories: true)
        try? fm.createDirectory(at: destDir.appendingPathComponent("fonts"), withIntermediateDirectories: true)

        // Look up bundled resources either in BundledThemes/plague-doctor subfolder or flat bundle resources
        let bundle = Bundle.main
        if let bundledSubdir = bundle.resourceURL?.appendingPathComponent("BundledThemes/plague-doctor"),
           fm.fileExists(atPath: bundledSubdir.appendingPathComponent("theme.json").path) {
            try? fm.removeItem(at: destDir)
            try? fm.copyItem(at: bundledSubdir, to: destDir)
            return
        }

        // Flat bundle fallback (when Xcode copies resources flatly into .app root)
        if let tURL = bundle.url(forResource: "theme", withExtension: "json") {
            try? fm.copyItem(at: tURL, to: manifestURL)
        }
        for name in ["lockscreen.png", "homescreen.png", "live_wallpaper.mp4"] {
            let parts = name.split(separator: ".")
            if parts.count == 2,
               let src = bundle.url(forResource: String(parts[0]), withExtension: String(parts[1])) {
                try? fm.copyItem(at: src, to: destDir.appendingPathComponent(name))
            }
        }
        let iconNames = [
            "01-Phone", "02-Telegram", "03-YouTube", "04-Safari",
            "05-VKMusic", "06-AuthorToday", "07-AmneziaVPN", "08-Messages",
            "09-Settings", "10-Camera", "11-YandexMaps", "12-YandexGo",
            "13-Raiffeisen", "14-Discord", "15-GuitarTuna", "16-Clock"
        ]
        for ic in iconNames {
            if let src = bundle.url(forResource: ic, withExtension: "png") {
                try? fm.copyItem(at: src, to: destDir.appendingPathComponent("icons/\(ic).png"))
            }
        }
        let fontNames = ["CormorantUnicase-Bold", "RuslanDisplay-Regular", "UnifrakturMaguntia-Book"]
        for fn in fontNames {
            if let src = bundle.url(forResource: fn, withExtension: "ttf") {
                try? fm.copyItem(at: src, to: destDir.appendingPathComponent("fonts/\(fn).ttf"))
            }
        }
    }

    func reloadInstalledThemes() {
        var loaded: [ThemeManifest] = []
        if let items = try? fm.contentsOfDirectory(at: themesRootDir, includingPropertiesForKeys: nil) {
            for folder in items {
                let jsonURL = folder.appendingPathComponent("theme.json")
                if let data = try? Data(contentsOf: jsonURL),
                   let manifest = try? JSONDecoder().decode(ThemeManifest.self, from: data) {
                    loaded.append(manifest)
                }
            }
        }
        installedThemes = loaded.sorted { $0.id == "plague-doctor" ? true : ($1.id == "plague-doctor" ? false : $0.title < $1.title) }
    }

    /// Fetches the remote theme catalog JSON from `catalogURLString` (e.g. `https://at.theinquisitor.ru/memento/catalog.json` or any custom URL).
    func fetchRemoteCatalog() async {
        UserDefaults.standard.set(catalogURLString, forKey: "memento_catalog_url")
        guard let url = URL(string: catalogURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            statusMessage = "Некорректный URL каталога"
            return
        }
        isLoadingCatalog = true
        defer { isLoadingCatalog = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let catalog = try? JSONDecoder().decode(RemoteCatalogResponse.self, from: data) {
                remoteThemes = catalog.themes
                statusMessage = "Каталог обновлён: доступно тем — \(catalog.themes.count)"
            } else if let singleTheme = try? JSONDecoder().decode(ThemeManifest.self, from: data) {
                remoteThemes = [singleTheme]
                statusMessage = "Загружен манифест темы «\(singleTheme.title)»"
            } else {
                statusMessage = "Не удалось распознать формат JSON каталога"
            }
        } catch {
            statusMessage = "Сервер каталога пока недоступен (\(error.localizedDescription)). Вы можете добавить любую тему по прямой ссылке или из файла."
        }
    }

    /// Downloads and installs a remote theme (wallpapers, live video, icons, fonts) from a `ThemeManifest` whose assets live under `remoteBaseURL`.
    func downloadAndInstallRemoteTheme(_ manifest: ThemeManifest) async throws {
        let baseStr = manifest.remoteBaseURL ?? (URL(string: catalogURLString)?.deletingLastPathComponent().appendingPathComponent(manifest.id).absoluteString ?? "")
        guard let baseURL = URL(string: baseStr) else {
            throw NSError(domain: "MementoThemes", code: 400, userInfo: [NSLocalizedDescriptionKey: "Не указан базовый URL файлов темы"])
        }

        let destDir = themeDirectory(for: manifest.id)
        try? fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: destDir.appendingPathComponent("icons"), withIntermediateDirectories: true)
        try? fm.createDirectory(at: destDir.appendingPathComponent("fonts"), withIntermediateDirectories: true)

        // Save manifest
        let encoded = try JSONEncoder().encode(manifest)
        try encoded.write(to: destDir.appendingPathComponent("theme.json"), options: .atomic)

        // Download wallpapers & live video
        for file in [manifest.lockscreenFile, manifest.homescreenFile, manifest.liveVideoFile].compactMap({ $0 }) {
            let fileURL = baseURL.appendingPathComponent(file)
            if let (data, _) = try? await URLSession.shared.data(from: fileURL) {
                try? data.write(to: destDir.appendingPathComponent(file), options: .atomic)
            }
        }

        // Download icons
        for icon in manifest.icons {
            let iconURL = icon.remoteURL.flatMap { URL(string: $0) } ?? baseURL.appendingPathComponent("icons").appendingPathComponent(icon.fileName)
            if let (data, _) = try? await URLSession.shared.data(from: iconURL) {
                try? data.write(to: destDir.appendingPathComponent("icons").appendingPathComponent(icon.fileName), options: .atomic)
            }
        }

        // Download fonts
        for font in manifest.fonts {
            let fontURL = font.remoteURL.flatMap { URL(string: $0) } ?? baseURL.appendingPathComponent("fonts").appendingPathComponent(font.fileName)
            if let (data, _) = try? await URLSession.shared.data(from: fontURL) {
                try? data.write(to: destDir.appendingPathComponent("fonts").appendingPathComponent(font.fileName), options: .atomic)
            }
        }

        reloadInstalledThemes()
    }

    /// Creates a new custom theme on-device from user-selected photos/videos or imported folder.
    func createCustomTheme(
        title: String,
        subtitle: String,
        quote: String,
        accentHex: String,
        lockscreenData: Data,
        homescreenData: Data?,
        liveVideoURL: URL?
    ) throws -> ThemeManifest {
        let slug = "custom-\(Int(Date().timeIntervalSince1970))"
        let destDir = themeDirectory(for: slug)
        try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: destDir.appendingPathComponent("icons"), withIntermediateDirectories: true)
        try fm.createDirectory(at: destDir.appendingPathComponent("fonts"), withIntermediateDirectories: true)

        try lockscreenData.write(to: destDir.appendingPathComponent("lockscreen.png"), options: .atomic)
        try (homescreenData ?? lockscreenData).write(to: destDir.appendingPathComponent("homescreen.png"), options: .atomic)

        var liveFile: String? = nil
        if let videoURL = liveVideoURL {
            let targetVideo = destDir.appendingPathComponent("live_wallpaper.mp4")
            try? fm.copyItem(at: videoURL, to: targetVideo)
            liveFile = "live_wallpaper.mp4"
        }

        // Copy default gothic icons & fonts so the new theme immediately has a full icon/font pack
        let defaultDir = themeDirectory(for: "plague-doctor")
        if let defaultIcons = try? fm.contentsOfDirectory(at: defaultDir.appendingPathComponent("icons"), includingPropertiesForKeys: nil) {
            for ic in defaultIcons {
                try? fm.copyItem(at: ic, to: destDir.appendingPathComponent("icons").appendingPathComponent(ic.lastPathComponent))
            }
        }
        if let defaultFonts = try? fm.contentsOfDirectory(at: defaultDir.appendingPathComponent("fonts"), includingPropertiesForKeys: nil) {
            for fn in defaultFonts {
                try? fm.copyItem(at: fn, to: destDir.appendingPathComponent("fonts").appendingPathComponent(fn.lastPathComponent))
            }
        }

        let baseManifest = installedThemes.first(where: { $0.id == "plague-doctor" })
        let manifest = ThemeManifest(
            id: slug,
            title: title,
            subtitle: subtitle,
            author: "Пользователь",
            version: "1.0",
            accentHex: accentHex,
            secondaryHex: "#8A6BB8",
            backgroundHex: "#0E0C14",
            widgetQuote: quote,
            widgetSubquote: subtitle,
            lockscreenFile: "lockscreen.png",
            homescreenFile: "homescreen.png",
            liveVideoFile: liveFile,
            fonts: baseManifest?.fonts ?? [],
            icons: baseManifest?.icons ?? []
        )

        let data = try JSONEncoder().encode(manifest)
        try data.write(to: destDir.appendingPathComponent("theme.json"), options: .atomic)
        reloadInstalledThemes()
        return manifest
    }
}
