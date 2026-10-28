import Foundation
import Network
import UIKit

final class MobileConfigGenerator {
    static let shared = MobileConfigGenerator()

    private var listener: NWListener?
    private var activeProfileData: Data?
    private let port: UInt16 = 8765

    /// Dynamically builds an iOS Configuration Profile (`.mobileconfig`) containing selected custom app icons (WebClips) and/or custom Gothic TTF fonts.
    func buildMobileConfig(
        theme: ThemeManifest,
        themeDir: URL,
        selectedIcons: [ThemeIconItem],
        includeFonts: Bool,
        customSchemeOverrides: [String: String] = [:]
    ) throws -> Data {
        var payloads: [[String: Any]] = []

        if includeFonts {
            for font in theme.fonts {
                let fontURL = themeDir.appendingPathComponent("fonts").appendingPathComponent(font.fileName)
                let fallbackURL = Bundle.main.url(forResource: font.fileName.replacingOccurrences(of: ".ttf", with: ""), withExtension: "ttf")
                if let data = (try? Data(contentsOf: fontURL)) ?? (fallbackURL.flatMap { try? Data(contentsOf: $0) }) {
                    payloads.append([
                        "PayloadType": "com.apple.font",
                        "PayloadVersion": 1,
                        "PayloadIdentifier": "ru.theinquisitor.mementothemes.\(theme.id).font.\(font.id)",
                        "PayloadUUID": UUID().uuidString.uppercased(),
                        "PayloadDisplayName": "Шрифт: \(font.displayName)",
                        "Name": font.displayName,
                        "Font": data
                    ])
                }
            }
        }

        for icon in selectedIcons {
            let iconURL = themeDir.appendingPathComponent("icons").appendingPathComponent(icon.fileName)
            guard let rawData = try? Data(contentsOf: iconURL),
                  let uiImg = UIImage(data: rawData),
                  let resizedData = resizeIconPNG(uiImg, size: CGSize(width: 180, height: 180)) else {
                continue
            }
            let targetScheme = customSchemeOverrides[icon.id] ?? icon.urlScheme
            payloads.append([
                "PayloadType": "com.apple.webClip.managed",
                "PayloadVersion": 1,
                "PayloadIdentifier": "ru.theinquisitor.mementothemes.\(theme.id).icon.\(icon.id)",
                "PayloadUUID": UUID().uuidString.uppercased(),
                "PayloadDisplayName": "Иконка: \(icon.appName)",
                "Label": icon.appName,
                "URL": targetScheme,
                "Icon": resizedData,
                "IsRemovable": true,
                "FullScreen": true,
                "Precomposed": true
            ])
        }

        let profileDict: [String: Any] = [
            "PayloadContent": payloads,
            "PayloadDisplayName": "Тема «\(theme.title)»",
            "PayloadDescription": "Кастомные иконки (\(selectedIcons.count) шт.) и шрифты темы «\(theme.title)». Устанавливаются и удаляются одним нажатием.",
            "PayloadIdentifier": "ru.theinquisitor.mementothemes.profile.\(theme.id)",
            "PayloadOrganization": "Memento Themes (\(theme.author))",
            "PayloadRemovalDisallowed": false,
            "PayloadType": "Configuration",
            "PayloadUUID": UUID().uuidString.uppercased(),
            "PayloadVersion": 1
        ]

        return try PropertyListSerialization.data(fromPropertyList: profileDict, format: .xml, options: 0)
    }

    /// Writes the `.mobileconfig` to a temporary file so the user can export/share it to Files or AirDrop, AND starts a lightweight localhost HTTP server (`http://127.0.0.1:8765/theme.mobileconfig`) so Safari on iOS can trigger the native "Profile Downloaded" prompt in 1 tap!
    func writeTempMobileConfigFile(data: Data, themeId: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Memento-\(themeId).mobileconfig")
        try data.write(to: url, options: .atomic)
        return url
    }

    func installViaLocalSafariServer(data: Data) {
        self.activeProfileData = data
        startServerIfNeeded()
        if let url = URL(string: "http://127.0.0.1:\(port)/install.mobileconfig") {
            UIApplication.shared.open(url)
        }
    }

    private func startServerIfNeeded() {
        guard listener == nil else { return }
        do {
            let params = NWParameters.tcp
            guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
            let lst = try NWListener(using: params, on: nwPort)
            lst.newConnectionHandler = { [weak self] conn in
                self?.handleConnection(conn)
            }
            lst.start(queue: .global(qos: .userInitiated))
            self.listener = lst
        } catch {
            print("Local profile server error: \(error)")
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, _, _ in
            guard let self = self, let payload = self.activeProfileData else {
                connection.cancel()
                return
            }
            let header = [
                "HTTP/1.1 200 OK",
                "Content-Type: application/x-apple-aspen-config",
                "Content-Disposition: attachment; filename=\"MementoTheme.mobileconfig\"",
                "Content-Length: \(payload.count)",
                "Connection: close",
                "",
                ""
            ].joined(separator: "\r\n")
            var responseData = Data(header.utf8)
            responseData.append(payload)
            connection.send(content: responseData, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func resizeIconPNG(_ image: UIImage, size: CGSize) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.pngData()
    }
}
