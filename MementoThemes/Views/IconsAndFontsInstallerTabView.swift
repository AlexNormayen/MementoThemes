import SwiftUI

struct IconsAndFontsInstallerTabView: View {
    let theme: ThemeManifest
    @EnvironmentObject var repository: ThemeRepository

    @State private var selectedIconIds: Set<String> = []
    @State private var includeFonts: Bool = true
    @State private var exportedProfileURL: URL?
    @State private var showShareSheet: Bool = false
    @State private var statusBanner: String?

    private var themeDir: URL {
        repository.themeDirectory(for: theme.id)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1-Click Profile Installer Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title2)
                                .foregroundStyle(Color(hex: theme.accentHex))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Установка в 1 клик (.mobileconfig)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Выбрано иконок: \(selectedIconIds.count) из \(theme.icons.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        Toggle(isOn: $includeFonts) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Включить 3 готических шрифта в профиль")
                                    .font(.subheadline.weight(.medium))
                                Text("Cormorant Unicase, Ruslan Display, UnifrakturMaguntia")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color(hex: theme.accentHex))

                        HStack(spacing: 10) {
                            Button {
                                installProfileDirectlyViaSafari()
                            } label: {
                                Label("Установить через Safari", systemImage: "safari.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: theme.accentHex), in: RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                exportProfileToFiles()
                            } label: {
                                Label("Сохранить в Файлы", systemImage: "folder.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        if let banner = statusBanner {
                            Text(banner)
                                .font(.caption)
                                .foregroundStyle(Color(hex: theme.accentHex))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))

                    // Selection controls
                    HStack {
                        Text("Готические иконки (\(theme.icons.count))")
                            .font(.headline)
                        Spacer()
                        Button(selectedIconIds.count == theme.icons.count ? "Снять все" : "Выбрать все") {
                            if selectedIconIds.count == theme.icons.count {
                                selectedIconIds.removeAll()
                            } else {
                                selectedIconIds = Set(theme.icons.map(\.id))
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(hex: theme.accentHex))
                    }

                    // 4x4 Grid of Custom Gothic Icons
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(theme.icons) { icon in
                            let isSelected = selectedIconIds.contains(icon.id)
                            let iconURL = themeDir.appendingPathComponent("icons").appendingPathComponent(icon.fileName)
                            Button {
                                if isSelected {
                                    selectedIconIds.remove(icon.id)
                                } else {
                                    selectedIconIds.insert(icon.id)
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        if let uiImg = UIImage(contentsOfFile: iconURL.path) {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 68, height: 68)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(
                                                            isSelected ? Color(hex: theme.accentHex) : Color.white.opacity(0.15),
                                                            lineWidth: isSelected ? 2.5 : 1
                                                        )
                                                )
                                        } else {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.08))
                                                .frame(width: 68, height: 68)
                                        }

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.caption)
                                            .foregroundStyle(isSelected ? Color(hex: theme.accentHex) : .white.opacity(0.5))
                                            .padding(4)
                                    }

                                    Text(icon.appName)
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Fonts specimen preview card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Готические шрифты в комплекте", systemImage: "textformat")
                            .font(.headline)
                            .foregroundStyle(Color(hex: theme.accentHex))

                        ForEach(theme.fonts) { fontItem in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(fontItem.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("MEMENTO MORI · Чумной Доктор")
                                    .font(.custom(fontItem.postScriptName, size: 22))
                                    .foregroundStyle(.white)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.04, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Иконки и Шрифты")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if selectedIconIds.isEmpty {
                    selectedIconIds = Set(theme.icons.map(\.id))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedProfileURL {
                    ShareSheetView(items: [url])
                }
            }
        }
    }

    private func installProfileDirectlyViaSafari() {
        let chosen = theme.icons.filter { selectedIconIds.contains($0.id) }
        do {
            let data = try MobileConfigGenerator.shared.buildMobileConfig(
                theme: theme,
                themeDir: themeDir,
                selectedIcons: chosen,
                includeFonts: includeFonts
            )
            statusBanner = "Откроется Safari → разрешите загрузку профиля → откройте Настройки → «Профиль загружен» → Установить."
            MobileConfigGenerator.shared.installViaLocalSafariServer(data: data)
        } catch {
            statusBanner = "Ошибка генерации профиля: \(error.localizedDescription)"
        }
    }

    private func exportProfileToFiles() {
        let chosen = theme.icons.filter { selectedIconIds.contains($0.id) }
        do {
            let data = try MobileConfigGenerator.shared.buildMobileConfig(
                theme: theme,
                themeDir: themeDir,
                selectedIcons: chosen,
                includeFonts: includeFonts
            )
            let url = try MobileConfigGenerator.shared.writeTempMobileConfigFile(data: data, themeId: theme.id)
            exportedProfileURL = url
            showShareSheet = true
            statusBanner = "Сохраните файл в «Файлы», нажмите на него, затем откройте Настройки → «Профиль загружен»."
        } catch {
            statusBanner = "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
