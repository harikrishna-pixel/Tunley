import AVFoundation
import CryptoKit
import ImageIO
import UniformTypeIdentifiers

/// First meaningful frame of a video as a cached JPEG.
enum Thumbnail {
  static func jpeg(_ url: URL, maxPixels: Int) async throws -> URL? {
    let asset = AVURLAsset(url: url)
    let videos = (try? await asset.loadTracks(withMediaType: .video)) ?? []
    if videos.isEmpty {
      return nil
    }
    guard let target = cacheFile(url, maxPixels: maxPixels) else {
      return nil
    }
    if FileManager.default.fileExists(atPath: target.path) {
      return target
    }

    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: maxPixels, height: maxPixels)
    let duration = (try? await asset.load(.duration)).map(\.seconds) ?? 0
    let at = CMTime(seconds: min(1, duration / 2), preferredTimescale: 600)
    let image: CGImage
    do {
      image = try await generator.image(at: at).image
    } catch {
      return nil
    }

    try Storage.ensureDir(target.deletingLastPathComponent())
    guard
      let dest = CGImageDestinationCreateWithURL(
        target as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
    else {
      return nil
    }
    CGImageDestinationAddImage(
      dest, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
    return CGImageDestinationFinalize(dest) ? target : nil
  }

  private static func cacheFile(_ url: URL, maxPixels: Int) -> URL? {
    guard
      let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
    else {
      return nil
    }
    let stamp = values.contentModificationDate?.timeIntervalSince1970 ?? 0
    let key = "\(url.path)|\(values.fileSize ?? 0)|\(stamp)|\(maxPixels)"
    let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    return Storage.cacheDir.appendingPathComponent("thumbs", isDirectory: true)
      .appendingPathComponent("\(digest).jpg")
  }
}
