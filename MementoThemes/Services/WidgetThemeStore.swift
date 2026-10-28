import Foundation
import WidgetKit

enum WidgetThemeStore {
    static let appGroup = "group.ru.theinquisitor.mementothemes"
    private static let key = "active_widget_theme_v1"

    struct Snapshot: Codable, Equatable {
        var themeId: String
        var title: String
        var quote: String
        var subquote: String
        var accentHex: String
        var secondaryHex: String
        var backgroundHex: String
        var styleMode: String // "cathedral", "plague", "minimal"
        var showDate: Bool
        var updatedAt: Date
    }

    static func save(_ snapshot: Snapshot) {
        let defaults = UserDefaults(suiteName: appGroup) ?? .standard
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func load() -> Snapshot {
        let defaults = UserDefaults(suiteName: appGroup) ?? .standard
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            return decoded
        }
        return Snapshot(
            themeId: "plague-doctor",
            title: "Чумной Доктор",
            quote: "MEMENTO MORI",
            subquote: "Свет фонаря среди тумана и ворон",
            accentHex: "#E8943A",
            secondaryHex: "#8A6BB8",
            backgroundHex: "#0E0C14",
            styleMode: "cathedral",
            showDate: true,
            updatedAt: .now
        )
    }
}
