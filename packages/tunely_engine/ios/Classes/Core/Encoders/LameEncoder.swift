import Foundation

#if canImport(lame)
  import lame
#endif

/// MP3 through LAME (`Frameworks/lame.xcframework`, dynamic, LGPL).
/// Without the framework the format reports `unavailable`.
final class LameEncoder: PcmEncoder {
  #if canImport(lame)
    static let isBundled = true

    private let handle: OpaquePointer
    private let out: FileHandle
    private let channels: Int
    private var mp3: [UInt8] = []

    init(url: URL, sampleRate: Double, channels: Int, bitrateKbps: Int) throws {
      guard let handle = lame_init() else {
        throw EngineError.encode("LAME didn't start.")
      }
      lame_set_in_samplerate(handle, Int32(sampleRate))
      lame_set_out_samplerate(handle, Int32(sampleRate))
      lame_set_num_channels(handle, Int32(channels))
      lame_set_mode(handle, channels == 1 ? MONO : JOINT_STEREO)
      lame_set_brate(handle, Int32(bitrateKbps))
      lame_set_VBR(handle, vbr_off)
      lame_set_quality(handle, 2)
      guard lame_init_params(handle) >= 0 else {
        lame_close(handle)
        throw EngineError.encode("LAME rejected the settings.")
      }
      guard FileManager.default.createFile(atPath: url.path, contents: nil),
        let out = try? FileHandle(forWritingTo: url)
      else {
        lame_close(handle)
        throw EngineError.io("Couldn't create the MP3 file.")
      }
      self.handle = handle
      self.out = out
      self.channels = channels
    }

    deinit {
      lame_close(handle)
      try? out.close()
    }

    func write(_ samples: UnsafePointer<Float>, frames: Int) throws {
      let needed = Int(1.25 * Double(frames)) + 7200
      if mp3.count < needed {
        mp3 = [UInt8](repeating: 0, count: needed)
      }
      let written = mp3.withUnsafeMutableBufferPointer { dest in
        channels == 1
          ? lame_encode_buffer_ieee_float(
            handle, samples, samples, Int32(frames), dest.baseAddress, Int32(dest.count))
          : lame_encode_buffer_interleaved_ieee_float(
            handle, samples, Int32(frames), dest.baseAddress, Int32(dest.count))
      }
      guard written >= 0 else {
        throw EngineError.encode("MP3 encoding failed (\(written)).")
      }
      try append(Int(written))
    }

    func finish() throws {
      if mp3.count < 7200 {
        mp3 = [UInt8](repeating: 0, count: 7200)
      }
      let written = mp3.withUnsafeMutableBufferPointer { dest in
        lame_encode_flush(handle, dest.baseAddress, Int32(dest.count))
      }
      if written > 0 {
        try append(Int(written))
      }
      try out.close()
    }

    private func append(_ count: Int) throws {
      guard count > 0 else { return }
      do {
        try out.write(contentsOf: Data(mp3[0..<count]))
      } catch {
        throw EngineError.from(error)
      }
    }
  #else
    static let isBundled = false

    init(url: URL, sampleRate: Double, channels: Int, bitrateKbps: Int) throws {
      throw EngineError.unavailable("The MP3 encoder isn't bundled in this build.")
    }

    func write(_ samples: UnsafePointer<Float>, frames: Int) throws {}
    func finish() throws {}
  #endif
}
