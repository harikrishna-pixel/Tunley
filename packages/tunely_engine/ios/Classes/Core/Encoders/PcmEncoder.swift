import Foundation

/// Receives interleaved Float32 PCM (-1...1) and writes one output file.
protocol PcmEncoder: AnyObject {
  func write(_ samples: UnsafePointer<Float>, frames: Int) throws
  func finish() throws
}

enum Encoders {
  static func isAvailable(_ format: EngineFormat) -> Bool {
    switch format {
    case .m4a, .m4r, .aac, .wav, .flac:
      return true
    case .mp3:
      return LameEncoder.isBundled
    case .ogg:
      return VorbisEncoder.isBundled
    }
  }

  /// Extension used while writing. M4R is written as M4A and renamed.
  static func workingExtension(_ format: EngineFormat) -> String {
    format == .m4r ? "m4a" : format.fileExtension
  }

  static func make(
    _ format: EngineFormat, url: URL, sampleRate: Double, channels: Int, bitrateKbps: Int
  ) throws -> PcmEncoder {
    switch format {
    case .m4a, .m4r, .aac, .wav, .flac:
      return try AudioFileEncoder(
        url: url, format: format, sampleRate: sampleRate, channels: channels,
        bitrateKbps: bitrateKbps)
    case .mp3:
      return try LameEncoder(
        url: url, sampleRate: sampleRate, channels: channels, bitrateKbps: bitrateKbps)
    case .ogg:
      return try VorbisEncoder(
        url: url, sampleRate: sampleRate, channels: channels, bitrateKbps: bitrateKbps)
    }
  }
}
