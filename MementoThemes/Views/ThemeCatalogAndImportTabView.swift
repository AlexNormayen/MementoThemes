import SwiftUI
import PhotosUI

struct ThemeCatalogAndImportTabView: View {
    @EnvironmentObject var repository: ThemeRepository

    @State private var showCreateSheet = false
    @State private var downloadingThemeId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Installed themes section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Установленные темы (\(repository.installedThemes.count))", systemImage: "checkmark.seal.fill")
                                .font(.headline)
                            Spacer()
                            Button {
                                showCreateSheet = true
                            } label: {
                                Label("Создать свою тему", systemImage: "plus.circle.fill")
                                    .font(.caption.weight(.bold))
                            }
                        }

                        ForEach(repository.installedThemes) { item in
                            let isCurrent = item.id == repository.activeThemeId
                            Button {
                                repository.activeThemeId = item.id
                            } label: {
                                HStack(spacing: 14) {
                                    let thumbURL = repository.themeDirectory(for: item.id).appendingPathComponent(item.lockscreenFile)
                                    if let uiImg = UIImage(contentsOfFile: thumbURL.path) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 58, height: 104)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.title)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            if isCurrent {
                                                Text("АКТИВНА")
                                                    .font(.caption2.weight(.bold))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color(hex: item.accentHex), in: Capsule())
                                                    .foregroundStyle(.black)
                                            }
                                        }
                                        Text(item.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                        Text("Иконок: \(item.icons.count) · Шрифтов: \(item.fonts.count) · Live: \(item.liveVideoFile != nil ? "Да" : "Нет")")
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: item.accentHex))
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(isCurrent ? Color(hex: item.accentHex) : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Remote catalog loader section (supports downloading future themes from server or custom URL)
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Онлайн-каталог и загрузка новых тем", systemImage: "icloud.and.arrow.down.fill")
                            .font(.headline)

                        Text("Подключите свой сервер тем (по умолчанию `at.theinquisitor.ru/memento/catalog.json`) или вставьте ссылку на JSON-манифест любой новой темы.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            TextField("https://at.theinquisitor.ru/memento/catalog.json", text: $repository.catalogURLString)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.caption.monospaced())
                                .padding(12)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                            Button {
                                Task { await repository.fetchRemoteCatalog() }
                            } label: {
                                if repository.isLoadingCatalog {
                                    ProgressView()
                                        .padding(.horizontal, 12)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(12)
                                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        if let msg = repository.statusMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(repository.remoteThemes) { remoteItem in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(remoteItem.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text(remoteItem.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    Task {
                                        downloadingThemeId = remoteItem.id
                                        try? await repository.downloadAndInstallRemoteTheme(remoteItem)
                                        repository.activeThemeId = remoteItem.id
                                        downloadingThemeId = nil
                                    }
                                } label: {
                                    if downloadingThemeId == remoteItem.id {
                                        ProgressView()
                                    } else {
                                        Label("Скачать", systemImage: "arrow.down.circle.fill")
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: remoteItem.accentHex), in: Capsule())
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.04, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Каталог и Импорт")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCreateSheet) {
                CreateCustomThemeSheetView()
                    .environmentObject(repository)
            }
        }
    }
}

struct CreateCustomThemeSheetView: View {
    @EnvironmentObject var repository: ThemeRepository
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = "Ночной Погост II"
    @State private var subtitle: String = "Кастомная готическая тема"
    @State private var quote: String = "MEMENTO MORI"
    @State private var accentHex: String = "#E8943A"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var errorMsg: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Название и стиль новой темы") {
                    TextField("Название темы", text: $title)
                    TextField("Подзаголовок", text: $subtitle)
                    TextField("Девиз на виджете", text: $quote)
                    TextField("Акцентный HEX-цвет (#E8943A)", text: $accentHex)
                }

                Section("Обои темы из медиатеки") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(
                            selectedPhotoData == nil ? "Выбрать картинку обоев (1290×2796)" : "Картинка выбрана ✓",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                }

                if let err = errorMsg {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Новая тема")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        saveCustomTheme()
                    }
                }
            }
        }
    }

    private func saveCustomTheme() {
        let fallbackURL = repository.themeDirectory(for: "plague-doctor").appendingPathComponent("lockscreen.png")
        guard let imgData = selectedPhotoData ?? (try? Data(contentsOf: fallbackURL)) else {
            errorMsg = "Выберите изображение для обоев"
            return
        }
        do {
            let created = try repository.createCustomTheme(
                title: title,
                subtitle: subtitle,
                quote: quote,
                accentHex: accentHex,
                lockscreenData: imgData,
                homescreenData: imgData,
                liveVideoURL: repository.themeDirectory(for: "plague-doctor").appendingPathComponent("live_wallpaper.mp4")
            )
            repository.activeThemeId = created.id
            dismiss()
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
