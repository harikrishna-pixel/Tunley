// macOS check for the platform-independent engine core.
// Run: packages/tunely_engine/tool/engine_check/run.sh
import AVFoundation
import Foundation

@main
struct EngineCheck {
  static func main() async {
    let args = CommandLine.arguments
    guard args.count >= 3 else {
      print("usage: engine_check <input> <outdir>")
      exit(2)
    }
    let input = URL(fileURLWithPath: args[1])
    let outDir = URL(fileURLWithPath: args[2], isDirectory: true)
    var failures = 0

    do {
      #if LONG_CHECK
        // long.sh: full-length MP3 and M4A of a long input; memory is
        // measured outside by /usr/bin/time -l.
        let long = try await MediaInspector.inspect(input)
        print("input: \(String(format: "%.0f", long.durationSec / 60)) min")
        for format in [EngineFormat.mp3, .m4a] where Encoders.isAvailable(format) {
          let spec = ConvertSpec(
            inputs: [input], format: format, bitrateKbps: 256, sampleRate: nil,
            startSec: 0, endSec: 0, fadeInSec: 0, fadeOutSec: 0, gainDb: 0,
            crossfadeSec: 0, outputName: "long_\(format.rawValue)")
          let started = Date()
          let out = try await Converter.run(
            spec, outputDir: outDir, token: CancelToken(), progress: { _ in })
          print("\(format.rawValue): \(out.bytes / 1_048_576) MB, "
            + "\(String(format: "%.0f", out.seconds / 60)) min of audio in "
            + "\(String(format: "%.1f", Date().timeIntervalSince(started))) s")
        }
        return
      #endif
      let info = try await MediaInspector.inspect(input)
      print("inspect: \(String(format: "%.2f", info.durationSec)) s, audio \(info.hasAudio), "
        + "\(info.sampleRate) Hz, \(info.channels) ch, \(info.sourceBitrateKbps ?? -1) kbps")
      let peaks = try await Waveform.peaks(input, buckets: 48)
      print("waveform: \(peaks.count) peaks, max \(peaks.max() ?? 0)")

      for format in EngineFormat.allCases {
        guard Encoders.isAvailable(format) else {
          print("\(format.rawValue): not bundled")
          continue
        }
        let spec = ConvertSpec(
          inputs: [input], format: format,
          bitrateKbps: format == .m4r ? 128 : 256,
          sampleRate: nil, startSec: 1, endSec: 0, fadeInSec: 2, fadeOutSec: 2,
          gainDb: format == .wav ? 6 : 0, crossfadeSec: 0, outputName: "check")
        let started = Date()
        let out = try await Converter.run(
          spec, outputDir: outDir, token: CancelToken(), progress: { _ in })
        let check = try await MediaInspector.inspect(out.url)
        // ADTS has no index, so AVFoundation only estimates its duration.
        let tolerance = format == .aac ? 1.5 : 0.2
        let ok = check.hasAudio && abs(check.durationSec - out.seconds) < tolerance
        if !ok { failures += 1 }
        print("\(format.rawValue): \(out.url.lastPathComponent) \(out.bytes) B, "
          + "\(String(format: "%.2f", out.seconds)) s, reread \(String(format: "%.2f", check.durationSec)) s, "
          + "\(String(format: "%.2f", Date().timeIntervalSince(started))) s \(ok ? "OK" : "FAIL")")
      }

      let merge = ConvertSpec(
        inputs: [input, input], format: .m4a, bitrateKbps: 128, sampleRate: nil,
        startSec: 0, endSec: 0, fadeInSec: 0, fadeOutSec: 0, gainDb: 0, crossfadeSec: 1,
        outputName: "merge")
      let merged = try await Converter.run(
        merge, outputDir: outDir, token: CancelToken(), progress: { _ in })
      let expected = 2 * info.durationSec - 1
      let mergeOk = abs(merged.seconds - expected) < 0.2
      if !mergeOk { failures += 1 }
      print("merge: \(String(format: "%.2f", merged.seconds)) s (expected \(String(format: "%.2f", expected))) \(mergeOk ? "OK" : "FAIL")")

      var compat = ConvertSpec(
        inputs: [input], format: .mp3, bitrateKbps: 256, sampleRate: nil,
        startSec: 1, endSec: 6, fadeInSec: 0, fadeOutSec: 1, gainDb: 0, crossfadeSec: 0,
        outputName: "compat")
      compat.compatibilityMode = true
      if Encoders.isAvailable(.mp3) {
        let out = try await Converter.run(
          compat, outputDir: outDir, token: CancelToken(), progress: { _ in })
        let ok = abs(out.seconds - 5) < 0.2
        if !ok { failures += 1 }
        print("compatibility: \(String(format: "%.2f", out.seconds)) s (expected 5.00) \(ok ? "OK" : "FAIL")")
      }

      let token = CancelToken()
      token.cancel(.cancelled)
      do {
        _ = try await Converter.run(
          ConvertSpec(
            inputs: [input], format: .wav, bitrateKbps: 0, sampleRate: nil, startSec: 0,
            endSec: 0, fadeInSec: 0, fadeOutSec: 0, gainDb: 0, crossfadeSec: 0,
            outputName: "cancelled"),
          outputDir: outDir, token: token, progress: { _ in })
        failures += 1
        print("cancel: FAIL (finished)")
      } catch let error as EngineError {
        let leftover = FileManager.default.fileExists(
          atPath: outDir.appendingPathComponent("cancelled.wav").path)
        if error.code != "cancelled" || leftover { failures += 1 }
        print("cancel: \(error.code), leftover \(leftover)")
      }

      do {
        _ = try await MediaInspector.inspect(URL(fileURLWithPath: "/nope.mp4"))
        failures += 1
      } catch let error as EngineError {
        print("missing file: \(error.code)")
        if error.code != "unreadable" { failures += 1 }
      }
    } catch {
      print("error: \(error)")
      exit(1)
    }
    print(failures == 0 ? "ALL OK" : "\(failures) FAILED")
    exit(failures == 0 ? 0 : 1)
  }
}
