import Foundation

/// Paths from `05` §8: library copies in `Documents/Library/`, scratch files in `tmp/Tunely/`.
enum Storage {
  static var tempRoot: URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("Tunely", isDirectory: true)
  }

  static var libraryDir: URL {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return docs.appendingPathComponent("Library", isDirectory: true)
  }

  static var cacheDir: URL {
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return caches.appendingPathComponent("Tunely", isDirectory: true)
  }

  static func ensureDir(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }

  static func freshTempDir(_ name: String) throws -> URL {
    let dir = tempRoot
      .appendingPathComponent(name, isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try ensureDir(dir)
    return dir
  }

  /// Removes characters that can't appear in a file name.
  static func sanitize(_ name: String) -> String {
    let banned = CharacterSet(charactersIn: "/:\\\0")
    let cleaned = name.components(separatedBy: banned).joined(separator: " ")
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return cleaned.isEmpty ? "Tunely" : cleaned
  }

  /// `name.ext`, then `name 2.ext`, `name 3.ext`.
  static func uniqueURL(in dir: URL, base: String, ext: String) -> URL {
    let fm = FileManager.default
    let clean = sanitize(base)
    var candidate = dir.appendingPathComponent("\(clean).\(ext)")
    var n = 2
    while fm.fileExists(atPath: candidate.path) {
      candidate = dir.appendingPathComponent("\(clean) \(n).\(ext)")
      n += 1
    }
    return candidate
  }

  static func fileSize(_ url: URL) -> Int64 {
    let values = try? url.resourceValues(forKeys: [.fileSizeKey])
    return Int64(values?.fileSize ?? 0)
  }

  static func freeBytes() -> Int64 {
    let home = URL(fileURLWithPath: NSHomeDirectory())
    let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    return values?.volumeAvailableCapacityForImportantUsage ?? 0
  }

  /// Deletes temp entries older than `hours`. Zero removes everything.
  static func cleanTemp(olderThanHours hours: Int) {
    let fm = FileManager.default
    let cutoff = Date().addingTimeInterval(-Double(hours) * 3600)
    guard
      let entries = try? fm.contentsOfDirectory(
        at: tempRoot, includingPropertiesForKeys: [.contentModificationDateKey])
    else {
      return
    }
    for group in entries {
      let children =
        (try? fm.contentsOfDirectory(
          at: group, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [group]
      for child in children {
        let modified =
          (try? child.resourceValues(forKeys: [.contentModificationDateKey]))?
          .contentModificationDate ?? .distantPast
        if hours == 0 || modified < cutoff {
          try? fm.removeItem(at: child)
        }
      }
    }
  }
}
