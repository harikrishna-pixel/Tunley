import AVFoundation

/// Decodes the audio of one asset to interleaved Float32 PCM.
final class PcmReader {
  let sampleRate: Double
  let channels: Int
  let durationSec: Double

  private let reader: AVAssetReader
  private let output: AVAssetReaderOutput
  private var scratch: [Float] = []

  private init(
    reader: AVAssetReader, output: AVAssetReaderOutput, sampleRate: Double, channels: Int,
    durationSec: Double
  ) {
    self.reader = reader
    self.output = output
    self.sampleRate = sampleRate
    self.channels = channels
    self.durationSec = durationSec
  }

  /// `startSec`/`endSec` trim the input. `endSec <= 0` reads to the end.
  static func open(
    _ url: URL, sampleRate: Double, channels: Int, startSec: Double = 0, endSec: Double = 0
  ) async throws -> PcmReader {
    let asset = AVURLAsset(url: url)
    let duration: CMTime
    let isProtected: Bool
    do {
      (duration, isProtected) = try await asset.load(.duration, .hasProtectedContent)
    } catch {
      throw EngineError.unreadable(error.localizedDescription)
    }
    if isProtected {
      throw EngineError.protected
    }
    let tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
    if tracks.isEmpty {
      throw EngineError.noAudio
    }

    let total = duration.isNumeric ? duration.seconds : 0
    let start = max(0, min(startSec, total))
    let end = endSec > 0 ? min(endSec, total) : total
    guard end > start else {
      throw EngineError.decode("The selected range is empty.")
    }

    let reader: AVAssetReader
    do {
      reader = try AVAssetReader(asset: asset)
    } catch {
      throw EngineError.unreadable(error.localizedDescription)
    }
    let timescale: CMTimeScale = 600_000
    reader.timeRange = CMTimeRange(
      start: CMTime(seconds: start, preferredTimescale: timescale),
      end: CMTime(seconds: end, preferredTimescale: timescale))

    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 32,
      AVLinearPCMIsFloatKey: true,
      AVLinearPCMIsNonInterleaved: false,
      AVLinearPCMIsBigEndianKey: false,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: channels,
    ]
    let output = AVAssetReaderAudioMixOutput(audioTracks: tracks, audioSettings: settings)
    output.alwaysCopiesSampleData = false
    guard reader.canAdd(output) else {
      throw EngineError.decode("The audio track can't be decoded.")
    }
    reader.add(output)
    guard reader.startReading() else {
      throw EngineError.decode(reader.error?.localizedDescription ?? "Decoding didn't start.")
    }
    return PcmReader(
      reader: reader, output: output, sampleRate: sampleRate, channels: channels,
      durationSec: end - start)
  }

  var estimatedFrames: Int { Int((durationSec * sampleRate).rounded()) }

  /// Next chunk of interleaved samples, or nil at the end.
  func next() throws -> [Float]? {
    while true {
      guard let buffer = output.copyNextSampleBuffer() else {
        if reader.status == .failed {
          throw EngineError.decode(reader.error?.localizedDescription ?? "Decoding failed.")
        }
        return nil
      }
      guard let block = CMSampleBufferGetDataBuffer(buffer) else {
        continue
      }
      let length = CMBlockBufferGetDataLength(block)
      let count = length / MemoryLayout<Float>.size
      if count == 0 {
        continue
      }
      if scratch.count != count {
        scratch = [Float](repeating: 0, count: count)
      }
      let status = scratch.withUnsafeMutableBytes { raw in
        CMBlockBufferCopyDataBytes(
          block, atOffset: 0, dataLength: length, destination: raw.baseAddress!)
      }
      guard status == kCMBlockBufferNoErr else {
        throw EngineError.decode("Couldn't read decoded audio.")
      }
      return scratch
    }
  }

  func cancel() {
    reader.cancelReading()
  }
}
