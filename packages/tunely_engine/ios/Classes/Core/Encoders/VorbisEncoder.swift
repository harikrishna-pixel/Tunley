import Foundation

#if canImport(vorbis)
  import vorbis
#endif

/// OGG Vorbis through libogg + libvorbis (`Frameworks/ogg.xcframework`, `vorbis.xcframework`, BSD).
/// Without the frameworks the format reports `unavailable`.
final class VorbisEncoder: PcmEncoder {
  #if canImport(vorbis)
    static let isBundled = true

    private var info = vorbis_info()
    private var comment = vorbis_comment()
    private var dsp = vorbis_dsp_state()
    private var block = vorbis_block()
    private var stream = ogg_stream_state()
    private let out: FileHandle
    private let channels: Int

    init(url: URL, sampleRate: Double, channels: Int, bitrateKbps: Int) throws {
      self.channels = channels
      vorbis_info_init(&info)
      let quality = VorbisEncoder.quality(forKbps: bitrateKbps)
      guard vorbis_encode_init_vbr(&info, Int(channels), Int(sampleRate), quality) == 0 else {
        vorbis_info_clear(&info)
        throw EngineError.encode("Vorbis rejected the settings.")
      }
      guard FileManager.default.createFile(atPath: url.path, contents: nil),
        let out = try? FileHandle(forWritingTo: url)
      else {
        vorbis_info_clear(&info)
        throw EngineError.io("Couldn't create the OGG file.")
      }
      self.out = out
      vorbis_comment_init(&comment)
      vorbis_comment_add_tag(&comment, "ENCODER", "Tunely")
      vorbis_analysis_init(&dsp, &info)
      vorbis_block_init(&dsp, &block)
      ogg_stream_init(&stream, Int32.random(in: 1...Int32.max))

      var header = ogg_packet()
      var headerComment = ogg_packet()
      var headerCode = ogg_packet()
      vorbis_analysis_headerout(&dsp, &comment, &header, &headerComment, &headerCode)
      ogg_stream_packetin(&stream, &header)
      ogg_stream_packetin(&stream, &headerComment)
      ogg_stream_packetin(&stream, &headerCode)
      var page = ogg_page()
      while ogg_stream_flush(&stream, &page) != 0 {
        try writePage(page)
      }
    }

    /// 128 / 256 / 320 kbps map to Vorbis quality 0.4 / 0.8 / 0.9.
    static func quality(forKbps kbps: Int) -> Float {
      switch kbps {
      case ..<160: return 0.4
      case ..<288: return 0.8
      default: return 0.9
      }
    }

    deinit {
      ogg_stream_clear(&stream)
      vorbis_block_clear(&block)
      vorbis_dsp_clear(&dsp)
      vorbis_comment_clear(&comment)
      vorbis_info_clear(&info)
      try? out.close()
    }

    func write(_ samples: UnsafePointer<Float>, frames: Int) throws {
      guard let buffers = vorbis_analysis_buffer(&dsp, Int32(frames)) else {
        throw EngineError.encode("Vorbis buffer failed.")
      }
      for c in 0..<channels {
        let dest = buffers[c]!
        for i in 0..<frames {
          dest[i] = samples[i * channels + c]
        }
      }
      vorbis_analysis_wrote(&dsp, Int32(frames))
      try drain()
    }

    func finish() throws {
      vorbis_analysis_wrote(&dsp, 0)
      try drain()
      try out.close()
    }

    private func drain() throws {
      var packet = ogg_packet()
      var page = ogg_page()
      while vorbis_analysis_blockout(&dsp, &block) == 1 {
        vorbis_analysis(&block, nil)
        vorbis_bitrate_addblock(&block)
        while vorbis_bitrate_flushpacket(&dsp, &packet) == 1 {
          ogg_stream_packetin(&stream, &packet)
          while ogg_stream_pageout(&stream, &page) != 0 {
            try writePage(page)
          }
        }
      }
    }

    private func writePage(_ page: ogg_page) throws {
      do {
        try out.write(contentsOf: Data(bytes: page.header, count: page.header_len))
        try out.write(contentsOf: Data(bytes: page.body, count: page.body_len))
      } catch {
        throw EngineError.from(error)
      }
    }
  #else
    static let isBundled = false

    init(url: URL, sampleRate: Double, channels: Int, bitrateKbps: Int) throws {
      throw EngineError.unavailable("The OGG encoder isn't bundled in this build.")
    }

    func write(_ samples: UnsafePointer<Float>, frames: Int) throws {}
    func finish() throws {}
  #endif
}
