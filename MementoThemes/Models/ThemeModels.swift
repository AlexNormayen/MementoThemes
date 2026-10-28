import Foundation
import SwiftUI

struct ThemeManifest: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var subtitle: String
    var author: String
    var version: String
    var accentHex: String
    var secondaryHex: String
    var backgroundHex: String
    var widgetQuote: String
    var widgetSubquote: String
    var lockscreenFile: String
    var homescreenFile: String
    var liveVideoFile: String?
    var fonts: [ThemeFontItem]
    var icons: [ThemeIconItem]

    // Optional remote URLs when fetched from an online catalog
    var remoteBaseURL: String?
}

struct ThemeFontItem: Codable, Identifiable, Equatable {
    var id: String
    var displayName: String
    var postScriptName: String
    var fileName: String
    var remoteURL: String?
}

struct ThemeIconItem: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var appName: String
    var urlScheme: String
    var fileName: String
    var category: String
    var remoteURL: String?
}

struct RemoteCatalogResponse: Codable {
    var catalogTitle: String
    var updatedAt: String
    var themes: [ThemeManifest]
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (232, 148, 58)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }
}
