import Foundation

/// Typed engine failure. `code` is one of the codes listed in `pigeons/engine.dart`.
struct EngineError: Error {
  let code: String
  let message: String

  static func unreadable(_ message: String = "The file can't be opened.") -> EngineError {
    EngineError(code: "unreadable", message: message)
  }

  static let noAudio = EngineError(code: "no_audio", message: "This file has no sound.")
  static let protected = EngineError(code: "protected", message: "This file is copy-protected.")
  static let icloud = EngineError(code: "icloud", message: "The file couldn't be downloaded.")
  static let noSpace = EngineError(code: "no_space", message: "Not enough free space.")
  static let interrupted = EngineError(code: "interrupted", message: "The job was interrupted.")
  static let cancelled = EngineError(code: "cancelled", message: "The job was cancelled.")
  static let staleBookmark = EngineError(
    code: "stale_bookmark", message: "The saved folder can't be found.")

  static func decode(_ message: String) -> EngineError {
    EngineError(code: "decode", message: message)
  }

  static func encode(_ message: String) -> EngineError {
    EngineError(code: "encode", message: message)
  }

  static func io(_ message: String) -> EngineError {
    EngineError(code: "io", message: message)
  }

  static func unavailable(_ message: String) -> EngineError {
    EngineError(code: "unavailable", message: message)
  }

  /// Maps file-system errors to `no_space` or `io`.
  static func from(_ error: Error) -> EngineError {
    if let engine = error as? EngineError {
      return engine
    }
    let ns = error as NSError
    let outOfSpace =
      (ns.domain == NSCocoaErrorDomain && ns.code == NSFileWriteOutOfSpaceError)
      || (ns.domain == NSPOSIXErrorDomain && ns.code == Int(ENOSPC))
    if outOfSpace {
      return .noSpace
    }
    return .io(ns.localizedDescription)
  }
}

enum EngineFormat: String, CaseIterable {
  case mp3, m4a, wav, m4r, flac, aac, ogg

  var fileExtension: String { rawValue }
}

struct ConvertSpec {
  var inputs: [URL]
  var format: EngineFormat
  var bitrateKbps: Int
  var sampleRate: Int?
  var startSec: Double
  var endSec: Double
  var fadeInSec: Double
  var fadeOutSec: Double
  var gainDb: Double
  var crossfadeSec: Double
  var outputName: String
  var compatibilityMode = false
}

struct ConvertOutput {
  let url: URL
  let bytes: Int64
  let seconds: Double
}

/// Thread-safe cancel flag checked between PCM chunks.
final class CancelToken: @unchecked Sendable {
  private let lock = NSLock()
  private var error: EngineError?

  func cancel(_ reason: EngineError) {
    lock.lock()
    if error == nil {
      error = reason
    }
    lock.unlock()
  }

  func check() throws {
    lock.lock()
    let current = error
    lock.unlock()
    if let current {
      throw current
    }
  }
}
