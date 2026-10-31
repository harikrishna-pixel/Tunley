import CryptoKit
import Foundation

/// Peak values for the trim editor, cached by file path, size, date and bucket count.
enum Waveform {
  private static let rate: Double = 8000

  static func peaks(_ url: URL, buckets: Int, token: CancelToken? = nil) async throws -> [Double] {
    let count = max(1, buckets)
    let cacheURL = cacheFile(url, buckets: count)
    if let cacheURL, let data = try? Data(contentsOf: cacheURL),
      let cached = try? JSONDecoder().decode([Double].self, from: data), cached.count == count
    {
      return cached
    }

    let reader = try await PcmReader.open(url, sampleRate: rate, channels: 1)
    let total = max(1, reader.estimatedFrames)
    var peaks = [Float](repeating: 0, count: count)
    var position = 0
    while let chunk = try reader.next() {
      try token?.check()
      for sample in chunk {
        let bucket = min(count - 1, position * count / total)
        let level = abs(sample)
        if level > peaks[bucket] {
          peaks[bucket] = level
        }
        position += 1
      }
    }

    let loudest = peaks.max() ?? 0
    let normalised = peaks.map { loudest > 0 ? Double($0 / loudest) : 0 }
    if let cacheURL, let data = try? JSONEncoder().encode(normalised) {
      try? Storage.ensureDir(cacheURL.deletingLastPathComponent())
      try? data.write(to: cacheURL, options: .atomic)
    }
    return normalised
  }

  private static func cacheFile(_ url: URL, buckets: Int) -> URL? {
    guard
      let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
    else {
      return nil
    }
    let stamp = values.contentModificationDate?.timeIntervalSince1970 ?? 0
    let key = "\(url.path)|\(values.fileSize ?? 0)|\(stamp)|\(buckets)"
    let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
    return Storage.cacheDir.appendingPathComponent("waveforms", isDirectory: true)
      .appendingPathComponent("\(digest).json")
  }
}
