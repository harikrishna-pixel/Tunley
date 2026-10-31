import AVFoundation

/// Compatibility mode (`05` §6, E1): Apple's own exporter reads files our
/// reader can't (variable frame rate, odd containers). Output is an M4A that
/// the normal pipeline then turns into the chosen format.
enum Compatibility {
  static func exportM4A(
    _ url: URL, startSec: Double, endSec: Double, token: CancelToken
  ) async throws -> URL {
    let asset = AVURLAsset(url: url)
    guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
    else {
      throw EngineError.encode("Compatibility export isn't available for this file.")
    }
    let dir = try Storage.freshTempDir("compat")
    let output = dir.appendingPathComponent("compat.m4a")
    session.outputURL = output
    session.outputFileType = .m4a
    if startSec > 0 || endSec > 0 {
      let duration = (try? await asset.load(.duration)) ?? .positiveInfinity
      let timescale: CMTimeScale = 600_000
      let end = endSec > 0 ? CMTime(seconds: endSec, preferredTimescale: timescale) : duration
      session.timeRange = CMTimeRange(
        start: CMTime(seconds: max(0, startSec), preferredTimescale: timescale), end: end)
    }

    let watcher = Task {
      while !Task.isCancelled {
        if (try? token.check()) == nil {
          session.cancelExport()
          return
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
      }
    }
    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
      session.exportAsynchronously { done.resume() }
    }
    watcher.cancel()
    try token.check()

    switch session.status {
    case .completed:
      return output
    case .cancelled:
      throw EngineError.cancelled
    default:
      try? FileManager.default.removeItem(at: dir)
      if let error = session.error {
        throw EngineError.from(error).code == "io"
          ? EngineError.encode(error.localizedDescription)
          : EngineError.from(error)
      }
      throw EngineError.encode("Compatibility export failed.")
    }
  }
}
