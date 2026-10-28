import Foundation
import AVFoundation
import Photos
import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

enum LivePhotoExportError: LocalizedError {
    case permissionDenied
    case videoNotFound
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Разрешите доступ к Фото в Настройках iPhone, чтобы сохранить живые обои."
        case .videoNotFound:
            return "Видеофайл живых обоев не найден в пакете темы."
        case .exportFailed(let reason):
            return "Ошибка создания Live Photo: \(reason)"
        }
    }
}

final class LivePhotoCreator {
    static let shared = LivePhotoCreator()

    /// Saves a still image (Lock Screen or Home Screen wallpaper) directly to the user's Photo Library.
    func saveStillWallpaper(at imageURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw LivePhotoExportError.permissionDenied
        }
        guard let image = UIImage(contentsOfFile: imageURL.path) else {
            throw LivePhotoExportError.exportFailed("Не удалось прочитать изображение обоев")
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    /// Converts an MP4 video + poster image into a genuine Apple Live Photo (paired JPEG + QuickTime MOV with matching ContentIdentifier) and saves it to the Photo Library for use as an animated iOS Lock Screen wallpaper.
    func saveLiveWallpaper(videoURL: URL, posterImageURL: URL?) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw LivePhotoExportError.permissionDenied
        }
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw LivePhotoExportError.videoNotFound
        }

        let assetIdentifier = UUID().uuidString
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("livephoto-\(assetIdentifier)", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let pairedImageURL = tempDir.appendingPathComponent("IMG.JPG")
        let pairedVideoURL = tempDir.appendingPathComponent("IMG.MOV")

        // 1. Extract or load base image and write JPEG with Apple MakerNote assetIdentifier (key "17")
        let baseImage: UIImage
        if let posterURL = posterImageURL, let img = UIImage(contentsOfFile: posterURL.path) {
            baseImage = img
        } else {
            baseImage = try await extractFirstFrame(from: videoURL)
        }
        try writeLivePhotoJPEG(image: baseImage, assetIdentifier: assetIdentifier, to: pairedImageURL)

        // 2. Remux video into QuickTime .mov with `com.apple.quicktime.content.identifier` metadata and `still-image-time` track
        try await writeLivePhotoMOV(sourceVideoURL: videoURL, assetIdentifier: assetIdentifier, to: pairedVideoURL)

        // 3. Save paired photo + video resource into Photos as a single Live Photo
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let photoOptions = PHAssetResourceCreationOptions()
            request.addResource(with: .photo, fileURL: pairedImageURL, options: photoOptions)
            let videoOptions = PHAssetResourceCreationOptions()
            videoOptions.shouldMoveFile = false
            request.addResource(with: .pairedVideo, fileURL: pairedVideoURL, options: videoOptions)
        }

        try? FileManager.default.removeItem(at: tempDir)
    }

    private func extractFirstFrame(from videoURL: URL) async throws -> UIImage {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }

    private func writeLivePhotoJPEG(image: UIImage, assetIdentifier: String, to destinationURL: URL) throws {
        guard let cgImage = image.cgImage,
              let dest = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw LivePhotoExportError.exportFailed("Не удалось создать JPEG контейнер")
        }
        let makerNote: [String: Any] = ["17": assetIdentifier]
        let properties: [String: Any] = [
            kCGImagePropertyMakerAppleDictionary as String: makerNote,
            kCGImageDestinationLossyCompressionQuality as String: 0.95
        ]
        CGImageDestinationAddImage(dest, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw LivePhotoExportError.exportFailed("Не удалось записать метаданные Live Photo в JPEG")
        }
    }

    private func writeLivePhotoMOV(sourceVideoURL: URL, assetIdentifier: String, to destinationURL: URL) async throws {
        let asset = AVURLAsset(url: sourceVideoURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw LivePhotoExportError.exportFailed("Не удалось инициализировать экспорт QuickTime MOV")
        }

        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = "com.apple.quicktime.content.identifier" as (NSCopying & NSObjectProtocol)
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)
        item.dataType = kCMMetadataBaseDataType_UTF8 as String

        let stillItem = AVMutableMetadataItem()
        stillItem.keySpace = .quickTimeMetadata
        stillItem.key = "com.apple.quicktime.still-image-time" as (NSCopying & NSObjectProtocol)
        stillItem.value = 0 as (NSCopying & NSObjectProtocol)
        stillItem.dataType = kCMMetadataBaseDataType_SInt8 as String

        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mov
        exportSession.metadata = [item, stillItem]

        await exportSession.export()
        if let err = exportSession.error {
            throw LivePhotoExportError.exportFailed(err.localizedDescription)
        }
    }
}
