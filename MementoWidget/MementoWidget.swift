import WidgetKit
import SwiftUI

struct MementoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MementoWidgetEntry {
        MementoWidgetEntry(date: .now, snapshot: WidgetThemeStore.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (MementoWidgetEntry) -> Void) {
        completion(MementoWidgetEntry(date: .now, snapshot: WidgetThemeStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MementoWidgetEntry>) -> Void) {
        let entry = MementoWidgetEntry(date: .now, snapshot: WidgetThemeStore.load())
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

struct MementoWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetThemeStore.Snapshot
}

struct MementoWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: MementoWidgetEntry

    private var accentColor: Color {
        Color(hex: entry.snapshot.accentHex)
    }

    private var secondaryColor: Color {
        Color(hex: entry.snapshot.secondaryHex)
    }

    private var bgColor: Color {
        Color(hex: entry.snapshot.backgroundHex)
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "moon.stars.fill")
                        .font(.title3)
                }
            case .accessoryInline:
                Text("☾ \(entry.snapshot.quote)")
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.snapshot.quote)
                        .font(.headline.weight(.bold))
                    Text(entry.snapshot.subquote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(accentColor)
                        Text(entry.snapshot.quote)
                            .font(.system(.headline, design: .serif).weight(.bold))
                            .foregroundStyle(accentColor)
                        Spacer()
                        if entry.snapshot.showDate {
                            Text(entry.date, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Text(entry.snapshot.subquote)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    HStack {
                        Text(entry.snapshot.title)
                            .font(.caption2)
                            .foregroundStyle(secondaryColor)
                        Spacer()
                        if entry.snapshot.showDate {
                            Text(entry.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) {
            bgColor
        }
    }
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

struct MementoGothicWidget: Widget {
    let kind = "MementoGothicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MementoWidgetProvider()) { entry in
            MementoWidgetView(entry: entry)
        }
        .configurationDisplayName("Чумной Доктор · Девиз")
        .description("Готический виджет для Экрана блокировки и рабочего стола.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct MementoWidgetBundle: WidgetBundle {
    var body: some Widget {
        MementoGothicWidget()
    }
}
