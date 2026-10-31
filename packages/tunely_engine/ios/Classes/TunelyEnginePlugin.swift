import DeviceCheck
import Flutter
import UIKit

/// Implements the Pigeon `EngineApi`. Business rules stay in Dart; this only runs jobs.
public final class TunelyEnginePlugin: NSObject, FlutterPlugin, EngineApi {
  private let picker = VideoPicker()
  private let bookmarks = Bookmarks()
  private let progress = ProgressStream()
  private let jobsLock = NSLock()
  private var jobs: [String: CancelToken] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = TunelyEnginePlugin()
    EngineApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    ProgressStreamHandler.register(with: registrar.messenger(), streamHandler: instance.progress)
  }

  func pickVideos(maxCount: Int64, completion: @escaping (Result<[String], Error>) -> Void) {
    DispatchQueue.main.async {
      self.picker.present(maxCount: Int(maxCount)) { result in
        completion(result.map { $0.map(\.path) }.mapError { $0.pigeon })
      }
    }
  }

  func inspect(path: String, completion: @escaping (Result<MediaInfo, Error>) -> Void) {
    run(completion) {
      let info = try await MediaInspector.inspect(URL(fileURLWithPath: path))
      return MediaInfo(
        path: info.path, bytes: info.bytes, durationSec: info.durationSec, hasAudio: info.hasAudio,
        hasVideo: info.hasVideo, isProtected: info.isProtected, isLocal: info.isLocal,
        sourceBitrate: info.sourceBitrateKbps.map(Int64.init), sampleRate: Int64(info.sampleRate),
        channels: Int64(info.channels), container: info.container,
        variableFrameRate: info.variableFrameRate)
    }
  }

  func waveform(path: String, buckets: Int64, completion: @escaping (Result<[Double], Error>) -> Void) {
    run(completion) {
      try await Waveform.peaks(URL(fileURLWithPath: path), buckets: Int(buckets))
    }
  }

  func thumbnail(path: String, maxPixels: Int64, completion: @escaping (Result<String?, Error>) -> Void) {
    run(completion) {
      try await Thumbnail.jpeg(URL(fileURLWithPath: path), maxPixels: Int(maxPixels))?.path
    }
  }

  func convert(jobId: String, request: ConvertRequest, completion: @escaping (Result<ConvertResult, Error>) -> Void) {
    let token = CancelToken()
    jobsLock.lock(); jobs[jobId] = token; jobsLock.unlock()

    var background = UIBackgroundTaskIdentifier.invalid
    DispatchQueue.main.async {
      background = UIApplication.shared.beginBackgroundTask(withName: "tunely.convert") {
        token.cancel(.interrupted)
      }
    }
    let spec = ConvertSpec(
      inputs: request.inputs.map { URL(fileURLWithPath: $0) },
      format: EngineFormat(request.format),
      bitrateKbps: Int(request.bitrateKbps),
      sampleRate: request.sampleRate.map(Int.init),
      startSec: request.startSec, endSec: request.endSec,
      fadeInSec: request.fadeInSec, fadeOutSec: request.fadeOutSec,
      gainDb: request.gainDb, crossfadeSec: request.crossfadeSec,
      outputName: request.outputName,
      compatibilityMode: request.compatibilityMode ?? false)
    let throttle = Throttle(interval: 0.1)

    run({ result in
      self.jobsLock.lock(); self.jobs[jobId] = nil; self.jobsLock.unlock()
      DispatchQueue.main.async {
        if background != .invalid {
          UIApplication.shared.endBackgroundTask(background)
        }
      }
      completion(result)
    }) {
      let output = try await Converter.run(spec, outputDir: Storage.libraryDir, token: token) { fraction in
        if fraction >= 1 || throttle.ready() {
          self.progress.send(ProgressEvent(jobId: jobId, fraction: fraction))
        }
      }
      return ConvertResult(
        jobId: jobId, outputPath: output.url.path, outputBytes: output.bytes, seconds: output.seconds)
    }
  }

  func cancel(jobId: String) throws {
    jobsLock.lock(); let token = jobs[jobId]; jobsLock.unlock()
    token?.cancel(.cancelled)
  }

  func availableFormats() throws -> [OutFormat] {
    OutFormat.allFormats.filter { Encoders.isAvailable(EngineFormat($0)) }
  }

  func pickFolder(completion: @escaping (Result<String?, Error>) -> Void) {
    DispatchQueue.main.async {
      self.bookmarks.pickFolder { result in
        completion(result.mapError { $0.pigeon })
      }
    }
  }

  func bookmarkedFolderName(bookmarkId: String) throws -> String? {
    bookmarks.folderName(bookmarkId)
  }

  func bookmarkedFolderIsICloud(bookmarkId: String) throws -> Bool {
    bookmarks.isICloud(bookmarkId)
  }

  func copyToBookmarkedFolder(path: String, bookmarkId: String, completion: @escaping (Result<String, Error>) -> Void) {
    run(completion) {
      try self.bookmarks.copy(URL(fileURLWithPath: path), toFolder: bookmarkId)
    }
  }

  func freeBytes() throws -> Int64 {
    Storage.freeBytes()
  }

  func cleanTemp(olderThanHours: Int64) throws {
    Storage.cleanTemp(olderThanHours: Int(olderThanHours))
  }

  func startContinuedBatch(title: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    guard #available(iOS 26.0, *) else {
      completion(.success(false))
      return
    }
    DispatchQueue.main.async {
      completion(.success(ContinuedBatch.shared.start(title: title)))
    }
  }

  func updateContinuedBatch(completed: Int64, total: Int64, subtitle: String) throws {
    if #available(iOS 26.0, *) {
      ContinuedBatch.shared.update(completed: Int(completed), total: Int(total), subtitle: subtitle)
    }
  }

  func finishContinuedBatch(success: Bool) throws {
    if #available(iOS 26.0, *) {
      ContinuedBatch.shared.finish(success: success)
    }
  }

  func openUrl(url: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    let target = url == "app-settings:" ? UIApplication.openSettingsURLString : url
    guard let link = URL(string: target) else {
      completion(.success(false))
      return
    }
    DispatchQueue.main.async {
      UIApplication.shared.open(link, options: [:]) { opened in
        completion(.success(opened))
      }
    }
  }

  func appInfo() throws -> AppInfo {
    let bundle = Bundle.main.infoDictionary ?? [:]
    return AppInfo(
      version: bundle["CFBundleShortVersionString"] as? String ?? "",
      build: bundle["CFBundleVersion"] as? String ?? "",
      osVersion: UIDevice.current.systemVersion)
  }

  func trackingStatus() throws -> String { Tracking.status() }

  func requestTracking(completion: @escaping (Result<String, Error>) -> Void) {
    Tracking.request { completion(.success($0)) }
  }

  func deviceCheckToken(completion: @escaping (Result<String?, Error>) -> Void) {
    guard DCDevice.current.isSupported else {
      completion(.success(nil))
      return
    }
    DCDevice.current.generateToken { data, _ in
      completion(.success(data?.base64EncodedString()))
    }
  }

  func openAppStorePage(appStoreId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    StorePage.shared.open(appStoreId: appStoreId) { completion(.success($0)) }
  }

  /// Runs async work off the main thread and replies on the main thread.
  private func run<T>(_ completion: @escaping (Result<T, Error>) -> Void, _ work: @escaping () async throws -> T) {
    Task.detached(priority: .userInitiated) {
      let result: Result<T, Error>
      do {
        result = .success(try await work())
      } catch {
        result = .failure(EngineError.from(error).pigeon)
      }
      DispatchQueue.main.async { completion(result) }
    }
  }
}

final class ProgressStream: ProgressStreamHandler {
  private var sink: PigeonEventSink<ProgressEvent>?

  override func onListen(withArguments arguments: Any?, sink: PigeonEventSink<ProgressEvent>) {
    self.sink = sink
  }

  override func onCancel(withArguments arguments: Any?) {
    sink = nil
  }

  func send(_ event: ProgressEvent) {
    DispatchQueue.main.async { self.sink?.success(event) }
  }
}

/// Lets through at most one call per `interval` seconds (progress max 10/s).
final class Throttle: @unchecked Sendable {
  private let interval: TimeInterval
  private let lock = NSLock()
  private var last: TimeInterval = 0

  init(interval: TimeInterval) {
    self.interval = interval
  }

  func ready() -> Bool {
    lock.lock(); defer { lock.unlock() }
    let now = ProcessInfo.processInfo.systemUptime
    guard now - last >= interval else { return false }
    last = now
    return true
  }
}

extension EngineError {
  var pigeon: PigeonError {
    PigeonError(code: code, message: message, details: nil)
  }
}

extension EngineFormat {
  init(_ format: OutFormat) {
    switch format {
    case .mp3: self = .mp3
    case .m4a: self = .m4a
    case .wav: self = .wav
    case .m4r: self = .m4r
    case .flac: self = .flac
    case .aac: self = .aac
    case .ogg: self = .ogg
    }
  }
}

extension OutFormat {
  static let allFormats: [OutFormat] = [.mp3, .m4a, .wav, .m4r, .flac, .aac, .ogg]
}
