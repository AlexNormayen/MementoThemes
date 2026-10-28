import SwiftUI
import AVKit

struct ThemeStudioTabView: View {
    let theme: ThemeManifest
    @EnvironmentObject var repository: ThemeRepository

    @State private var isExportingLive = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var showLiveAnimationPreview = true

    private var themeDir: URL {
        repository.themeDirectory(for: theme.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Banner
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(theme.widgetQuote)
                                .font(.custom("CormorantUnicase-Bold", size: 28))
                                .foregroundStyle(Color(hex: theme.accentHex))
                            Spacer()
                            Text("v\(theme.version)")
                                .font(.caption.monospaced())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.08), in: Capsule())
                        }
                        Text(theme.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(theme.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(hex: theme.backgroundHex))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color(hex: theme.secondaryHex).opacity(0.45), lineWidth: 1.5)
                            )
                    )

                    // Interactive Live Ravens & Wallpapers Preview
                    VStack(spacing: 14) {
                        Picker("Режим просмотра", selection: $showLiveAnimationPreview) {
                            Text("Живые вороны (Live)").tag(true)
                            Text("Домашний экран").tag(false)
                        }
                        .pickerStyle(.segmented)

                        ZStack {
                            if showLiveAnimationPreview,
                               let liveFile = theme.liveVideoFile {
                                let videoURL = themeDir.appendingPathComponent(liveFile)
                                LoopingVideoPlayerView(videoURL: videoURL, fallbackImageURL: themeDir.appendingPathComponent(theme.lockscreenFile))
                                    .frame(height: 520)
                                    .clipShape(RoundedRectangle(cornerRadius: 34))
                                    .overlay(alignment: .top) {
                                        VStack(spacing: 4) {
                                            HStack {
                                                Label("LIVE", systemImage: "livephoto")
                                                    .font(.caption2.weight(.bold))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(.ultraThinMaterial, in: Capsule())
                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.top, 16)

                                            Text("СРЕДА, 28 ОКТЯБРЯ")
                                                .font(.custom("CormorantUnicase-Bold", size: 15))
                                                .foregroundStyle(.white.opacity(0.85))
                                                .padding(.top, 6)
                                            Text("16:40")
                                                .font(.system(size: 64, weight: .bold, design: .serif))
                                                .foregroundStyle(.white.opacity(0.92))
                                        }
                                    }
                            } else {
                                let homeURL = themeDir.appendingPathComponent(theme.homescreenFile)
                                if let uiImg = UIImage(contentsOfFile: homeURL.path) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 520)
                                        .clipShape(RoundedRectangle(cornerRadius: 34))
                                }
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 34)
                                .stroke(Color(hex: theme.accentHex).opacity(0.55), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.6), radius: 18, y: 8)
                    }

                    // 1-Tap Action Buttons for Wallpapers & Live Photo
                    VStack(spacing: 12) {
                        Button {
                            Task { await exportLivePhotoWallpaper() }
                        } label: {
                            HStack(spacing: 12) {
                                if isExportingLive {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "livephoto.play")
                                        .font(.title3.weight(.bold))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Сохранить Живые обои (Live Photo)")
                                        .font(.headline)
                                    Text("Анимация летающих и клюющих ворон для Экрана блокировки")
                                        .font(.caption)
                                        .opacity(0.85)
                                }
                                Spacer()
                                Image(systemName: "arrow.down.to.line")
                            }
                            .foregroundStyle(.black)
                            .padding(16)
                            .background(Color(hex: theme.accentHex), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .disabled(isExportingLive)

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await saveStaticWallpaper(
                                        fileName: theme.lockscreenFile,
                                        label: "Обои Экрана блокировки (1290×2796)"
                                    )
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "lock.iphone")
                                        .font(.title2)
                                    Text("Экран блокировки")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Статичные 1290×2796")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                            }

                            Button {
                                Task {
                                    await saveStaticWallpaper(
                                        fileName: theme.homescreenFile,
                                        label: "Матовые обои Экрана «Домой» (1290×2796)"
                                    )
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "apps.iphone")
                                        .font(.title2)
                                    Text("Домашний экран")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Туман под иконки")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .foregroundStyle(.white)
                    }

                    // Step-by-step instruction card
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Как включить анимацию ворон на блокировке", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(Color(hex: theme.accentHex))
                        Text("1. Нажмите «Сохранить Живые обои (Live Photo)» выше — приложение автоматически сконвертирует видео с воронами в системную связку Apple Live Photo и сохранит в вашу медиатеку.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("2. Откройте Настройки iPhone → Обои → Добавить новые обои → Live Photo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("3. Выберите сохранённый кадр, убедитесь, что внизу слева горит значок LIVE, и нажмите «Готово».")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(16)
            }
            .background(Color(red: 0.05, green: 0.04, blue: 0.07).ignoresSafeArea())
            .navigationTitle("Memento Themes")
            .navigationBarTitleDisplayMode(.inline)
            .alert(alertTitle, isPresented: $showAlert) {
                Button("ОК", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func exportLivePhotoWallpaper() async {
        guard let liveFile = theme.liveVideoFile else { return }
        isExportingLive = true
        defer { isExportingLive = false }
        let videoURL = themeDir.appendingPathComponent(liveFile)
        let posterURL = themeDir.appendingPathComponent(theme.lockscreenFile)
        do {
            try await LivePhotoCreator.shared.saveLiveWallpaper(videoURL: videoURL, posterImageURL: posterURL)
            alertTitle = "Живые обои сохранены в Фото!"
            alertMessage = "Откройте Настройки → Обои → Добавить новые обои → Live Photo и выберите только что созданный кадр с летающими и клюющими воронами."
            showAlert = true
        } catch {
            alertTitle = "Ошибка сохранения"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func saveStaticWallpaper(fileName: String, label: String) async {
        let url = themeDir.appendingPathComponent(fileName)
        do {
            try await LivePhotoCreator.shared.saveStillWallpaper(at: url)
            alertTitle = "Сохранено в Фото"
            alertMessage = "\(label) добавлены в вашу медиатеку Фото."
            showAlert = true
        } catch {
            alertTitle = "Ошибка"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct LoopingVideoPlayerView: View {
    let videoURL: URL
    let fallbackImageURL: URL

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack {
            if let uiImg = UIImage(contentsOfFile: fallbackImageURL.path) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            }
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .scaledToFill()
            }
        }
        .onAppear {
            guard FileManager.default.fileExists(atPath: videoURL.path) else { return }
            let item = AVPlayerItem(url: videoURL)
            let qPlayer = AVQueuePlayer(playerItem: item)
            qPlayer.isMuted = true
            self.looper = AVPlayerLooper(player: qPlayer, templateItem: item)
            self.player = qPlayer
            qPlayer.play()
        }
        .onDisappear {
            player?.pause()
        }
    }
}
