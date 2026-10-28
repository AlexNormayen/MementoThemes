import SwiftUI

struct WidgetCustomizerTabView: View {
    let theme: ThemeManifest
    @State private var quote: String = "MEMENTO MORI"
    @State private var subquote: String = "Свет фонаря среди тумана и ворон"
    @State private var styleMode: String = "cathedral"
    @State private var showDate: Bool = true
    @State private var savedBanner: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live Widget Preview Card
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(Color(hex: theme.accentHex))
                            Text(quote)
                                .font(.custom("CormorantUnicase-Bold", size: 22))
                                .foregroundStyle(Color(hex: theme.accentHex))
                            Spacer()
                            if showDate {
                                Text(Date.now, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(subquote)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color(hex: theme.backgroundHex))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(Color(hex: theme.secondaryHex).opacity(0.6), lineWidth: 2)
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 12, y: 6)

                    // Widget Settings Form
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Настройка виджета на Экран «Домой» и Блокировки")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Главный готический девиз")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("MEMENTO MORI", text: $quote)
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Подпись / статус")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Свет фонаря среди тумана и ворон", text: $subquote)
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }

                        Picker("Оформление виджета", selection: $styleMode) {
                            Text("Собор и туман").tag("cathedral")
                            Text("Фонарь Доктора").tag("plague")
                            Text("Минимализм").tag("minimal")
                        }
                        .pickerStyle(.segmented)

                        Toggle("Показывать текущую дату и фазу ночи", isOn: $showDate)
                            .tint(Color(hex: theme.accentHex))

                        Button {
                            applyToSystemWidget()
                        } label: {
                            Label("Применить к виджету iPhone", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(hex: theme.accentHex), in: RoundedRectangle(cornerRadius: 16))
                        }

                        if savedBanner {
                            Text("Виджет обновлён! Добавьте виджет «Memento Виджет» на рабочий стол или экран блокировки iPhone.")
                                .font(.caption)
                                .foregroundStyle(Color(hex: theme.accentHex))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.04, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Виджеты Темы")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                let current = WidgetThemeStore.load()
                quote = current.quote
                subquote = current.subquote
                styleMode = current.styleMode
                showDate = current.showDate
            }
        }
    }

    private func applyToSystemWidget() {
        let snap = WidgetThemeStore.Snapshot(
            themeId: theme.id,
            title: theme.title,
            quote: quote,
            subquote: subquote,
            accentHex: theme.accentHex,
            secondaryHex: theme.secondaryHex,
            backgroundHex: theme.backgroundHex,
            styleMode: styleMode,
            showDate: showDate,
            updatedAt: .now
        )
        WidgetThemeStore.save(snap)
        savedBanner = true
    }
}
