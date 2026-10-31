import Accelerate
import Foundation

/// One pass: decode → [trim, merge crossfade, fades, gain + soft limiter] → encode.
/// Writes to `tmp/Tunely/jobs/` and moves the finished file into `outputDir`.
enum Converter {
  static let channels = 2

  static func run(
    _ spec: ConvertSpec,
    outputDir: URL,
    token: CancelToken,
    progress: @escaping (Double) -> Void
  ) async throws -> ConvertOutput {
    guard !spec.inputs.isEmpty else {
      throw EngineError.unreadable("No input file.")
    }
    guard Encoders.isAvailable(spec.format) else {
      throw EngineError.unavailable("\(spec.format.rawValue) isn't bundled in this build.")
    }

    if spec.compatibilityMode && spec.inputs.count == 1 {
      let exported = try await Compatibility.exportM4A(
        spec.inputs[0], startSec: spec.startSec, endSec: spec.endSec, token: token)
      defer { try? FileManager.default.removeItem(at: exported.deletingLastPathComponent()) }
      progress(0.3)
      var next = spec
      next.inputs = [exported]
      next.startSec = 0
      next.endSec = 0
      next.compatibilityMode = false
      return try await run(next, outputDir: outputDir, token: token) { fraction in
        progress(0.3 + 0.7 * fraction)
      }
    }

    let sampleRate = Double(spec.sampleRate ?? 44_100)
    let merging = spec.inputs.count > 1
    var readers: [PcmReader] = []
    for url in spec.inputs {
      let reader = try await PcmReader.open(
        url, sampleRate: sampleRate, channels: channels,
        startSec: merging ? 0 : spec.startSec,
        endSec: merging ? 0 : spec.endSec)
      readers.append(reader)
    }

    let shortest = readers.map(\.estimatedFrames).min() ?? 0
    let crossfade =
      merging ? min(Int(max(0, spec.crossfadeSec) * sampleRate), shortest / 2) : 0
    let totalFrames = max(
      1, readers.reduce(0) { $0 + $1.estimatedFrames } - crossfade * (readers.count - 1))

    let workDir = try Storage.freshTempDir("jobs")
    defer { try? FileManager.default.removeItem(at: workDir) }
    let workURL = workDir.appendingPathComponent("output.\(Encoders.workingExtension(spec.format))")
    let encoder = try Encoders.make(
      spec.format, url: workURL, sampleRate: sampleRate, channels: channels,
      bitrateKbps: spec.bitrateKbps)

    let shaper = Shaper(
      totalFrames: totalFrames,
      fadeInFrames: Int(max(0, spec.fadeInSec) * sampleRate),
      fadeOutFrames: Int(max(0, spec.fadeOutSec) * sampleRate),
      gainDb: spec.gainDb,
      channels: channels)
    var emitted = 0
    func emit(_ samples: inout [Float], from start: Int, frames: Int) throws {
      guard frames > 0 else { return }
      try samples.withUnsafeMutableBufferPointer { buffer in
        let base = buffer.baseAddress! + start * channels
        shaper.apply(base, frames: frames, position: emitted)
        try encoder.write(base, frames: frames)
      }
      emitted += frames
      progress(min(0.99, Double(emitted) / Double(totalFrames)))
    }

    do {
      var tail: [Float] = []
      for (index, reader) in readers.enumerated() {
        let holdBack = index < readers.count - 1 ? crossfade : 0
        var pending: [Float] = []
        var mixed = 0
        let tailFrames = tail.count / channels
        while var chunk = try reader.next() {
          try token.check()
          if mixed < tailFrames {
            let frames = chunk.count / channels
            let n = min(frames, tailFrames - mixed)
            for f in 0..<n {
              let t = Float(mixed + f) / Float(max(1, tailFrames))
              for c in 0..<channels {
                let i = f * channels + c
                chunk[i] = tail[(mixed + f) * channels + c] * (1 - t) + chunk[i] * t
              }
            }
            mixed += n
          }
          if holdBack == 0 {
            try emit(&chunk, from: 0, frames: chunk.count / channels)
            continue
          }
          pending.append(contentsOf: chunk)
          let ready = pending.count / channels - holdBack
          if ready > 0 {
            try emit(&pending, from: 0, frames: ready)
            pending.removeFirst(ready * channels)
          }
        }
        if mixed < tailFrames {
          var rest = Array(tail[(mixed * channels)...])
          try emit(&rest, from: 0, frames: rest.count / channels)
        }
        tail = pending
      }
      if !tail.isEmpty {
        try emit(&tail, from: 0, frames: tail.count / channels)
      }
      try token.check()
      try encoder.finish()
    } catch {
      readers.forEach { $0.cancel() }
      throw EngineError.from(error)
    }

    do {
      try Storage.ensureDir(outputDir)
      let final = Storage.uniqueURL(
        in: outputDir, base: spec.outputName, ext: spec.format.fileExtension)
      try FileManager.default.moveItem(at: workURL, to: final)
      progress(1)
      return ConvertOutput(
        url: final, bytes: Storage.fileSize(final), seconds: Double(emitted) / sampleRate)
    } catch {
      throw EngineError.from(error)
    }
  }
}

/// Fades, gain and a soft limiter on interleaved PCM.
struct Shaper {
  let totalFrames: Int
  let fadeInFrames: Int
  let fadeOutFrames: Int
  let gain: Float
  let channels: Int

  init(totalFrames: Int, fadeInFrames: Int, fadeOutFrames: Int, gainDb: Double, channels: Int) {
    self.totalFrames = totalFrames
    self.fadeInFrames = min(fadeInFrames, totalFrames)
    self.fadeOutFrames = min(fadeOutFrames, totalFrames)
    self.gain = Float(pow(10, gainDb / 20))
    self.channels = channels
  }

  func apply(_ samples: UnsafeMutablePointer<Float>, frames: Int, position: Int) {
    let count = frames * channels
    if gain != 1 {
      var g = gain
      vDSP_vsmul(samples, 1, &g, samples, 1, vDSP_Length(count))
    }
    if gain > 1 {
      limit(samples, count: count)
    }
    applyFadeIn(samples, frames: frames, position: position)
    applyFadeOut(samples, frames: frames, position: position)
  }

  /// Soft knee above 0.9 so boosted peaks never clip.
  private func limit(_ samples: UnsafeMutablePointer<Float>, count: Int) {
    let knee: Float = 0.9
    let headroom: Float = 1 - knee
    for i in 0..<count {
      let x = samples[i]
      let a = abs(x)
      if a > knee {
        let over = (a - knee) / headroom
        let shaped = knee + headroom * (over / (1 + over))
        samples[i] = x < 0 ? -shaped : shaped
      }
    }
  }

  private func applyFadeIn(_ samples: UnsafeMutablePointer<Float>, frames: Int, position: Int) {
    guard fadeInFrames > 0, position < fadeInFrames else { return }
    let n = min(frames, fadeInFrames - position)
    rampChannels(samples, frames: n, from: Float(position) / Float(fadeInFrames),
                 step: 1 / Float(fadeInFrames))
  }

  private func applyFadeOut(_ samples: UnsafeMutablePointer<Float>, frames: Int, position: Int) {
    guard fadeOutFrames > 0 else { return }
    let fadeStart = totalFrames - fadeOutFrames
    let end = position + frames
    guard end > fadeStart else { return }
    let first = max(0, fadeStart - position)
    let n = frames - first
    let startLevel = Float(totalFrames - (position + first)) / Float(fadeOutFrames)
    rampChannels(samples + first * channels, frames: n, from: max(0, startLevel),
                 step: -1 / Float(fadeOutFrames))
  }

  private func rampChannels(
    _ samples: UnsafeMutablePointer<Float>, frames: Int, from start: Float, step: Float
  ) {
    guard frames > 0 else { return }
    for c in 0..<channels {
      var level = start
      var s = step
      vDSP_vrampmul(samples + c, vDSP_Stride(channels), &level, &s,
                    samples + c, vDSP_Stride(channels), vDSP_Length(frames))
    }
    if step < 0 {
      let lastLevel = start + step * Float(frames)
      if lastLevel < 0 {
        let silentFrom = max(0, Int((start / -step).rounded(.up)))
        if silentFrom < frames {
          (samples + silentFrom * channels).update(
            repeating: 0, count: (frames - silentFrom) * channels)
        }
      }
    }
  }
}
