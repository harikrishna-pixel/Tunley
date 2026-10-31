import AVFoundation

struct InspectedMedia {
  let path: String
  let bytes: Int64
  let durationSec: Double
  let hasAudio: Bool
  let hasVideo: Bool
  let isProtected: Bool
  let isLocal: Bool
  let sourceBitrateKbps: Int?
  let sampleRate: Int
  let channels: Int
  let container: String
  let variableFrameRate: Bool
}

enum MediaInspector {
  static func inspect(_ url: URL) async throws -> InspectedMedia {
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw EngineError.unreadable("The file is missing.")
    }
    let values = try? url.resourceValues(forKeys: [
      .fileSizeKey, .isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey,
    ])
    let isLocal =
      values?.isUbiquitousItem == true
      ? values?.ubiquitousItemDownloadingStatus == .current
      : true

    let asset = AVURLAsset(url: url)
    let duration: CMTime
    let isProtected: Bool
    let isReadable: Bool
    do {
      (duration, isProtected, isReadable) = try await asset.load(
        .duration, .hasProtectedContent, .isReadable)
    } catch {
      throw EngineError.unreadable(error.localizedDescription)
    }

    let audioTracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
    let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
    if !isReadable && !isProtected {
      throw EngineError.unreadable()
    }

    var bitrate: Int?
    var sampleRate = 0
    var channels = 0
    if let track = audioTracks.first {
      if let (rate, descriptions) = try? await track.load(.estimatedDataRate, .formatDescriptions) {
        if rate > 0 {
          bitrate = Int((Double(rate) / 1000).rounded())
        }
        if let description = descriptions.first,
          let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee
        {
          sampleRate = Int(asbd.mSampleRate)
          channels = Int(asbd.mChannelsPerFrame)
        }
      }
    }

    var variable = false
    if let video = videoTracks.first,
      let (nominal, minFrame) = try? await video.load(.nominalFrameRate, .minFrameDuration),
      nominal > 0, minFrame.isNumeric, minFrame.seconds > 0
    {
      // Peak rate well above the nominal one means frame times vary.
      variable = (1 / minFrame.seconds) / Double(nominal) > 1.1
    }

    let seconds = duration.isNumeric ? duration.seconds : 0
    return InspectedMedia(
      path: url.path,
      bytes: Int64(values?.fileSize ?? 0),
      durationSec: seconds,
      hasAudio: !audioTracks.isEmpty,
      hasVideo: !videoTracks.isEmpty,
      isProtected: isProtected,
      isLocal: isLocal,
      sourceBitrateKbps: bitrate,
      sampleRate: sampleRate,
      channels: channels,
      container: url.pathExtension.lowercased(),
      variableFrameRate: variable
    )
  }
}
