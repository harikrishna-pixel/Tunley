import AVFoundation

/// AAC (M4A, M4R, ADTS), WAV 16-bit and FLAC through Apple's `AVAudioFile` (ExtAudioFile).
final class AudioFileEncoder: PcmEncoder {
  private var file: AVAudioFile?
  private let buffer: AVAudioPCMBuffer
  private let channels: Int

  init(url: URL, format: EngineFormat, sampleRate: Double, channels: Int, bitrateKbps: Int) throws {
    self.channels = channels
    var settings: [String: Any] = [
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: channels,
    ]
    switch format {
    case .m4a, .m4r, .aac:
      settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
      settings[AVEncoderBitRateKey] = bitrateKbps * 1000
    case .wav:
      settings[AVFormatIDKey] = kAudioFormatLinearPCM
      settings[AVLinearPCMBitDepthKey] = 16
      settings[AVLinearPCMIsFloatKey] = false
      settings[AVLinearPCMIsBigEndianKey] = false
      settings[AVLinearPCMIsNonInterleaved] = false
    case .flac:
      settings[AVFormatIDKey] = kAudioFormatFLAC
      settings[AVEncoderBitDepthHintKey] = 16
    case .mp3, .ogg:
      throw EngineError.encode("\(format.rawValue) isn't an Apple format.")
    }

    let file: AVAudioFile
    do {
      file = try AVAudioFile(
        forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: true)
    } catch {
      throw EngineError.encode(error.localizedDescription)
    }
    guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 8192)
    else {
      throw EngineError.encode("Couldn't allocate the audio buffer.")
    }
    self.file = file
    self.buffer = buffer
  }

  func write(_ samples: UnsafePointer<Float>, frames: Int) throws {
    guard let file else {
      throw EngineError.encode("The encoder is closed.")
    }
    let capacity = Int(buffer.frameCapacity)
    var offset = 0
    while offset < frames {
      let n = min(capacity, frames - offset)
      buffer.frameLength = AVAudioFrameCount(n)
      buffer.floatChannelData![0].update(from: samples + offset * channels, count: n * channels)
      do {
        try file.write(from: buffer)
      } catch {
        throw EngineError.from(error)
      }
      offset += n
    }
  }

  func finish() throws {
    file = nil
  }
}
