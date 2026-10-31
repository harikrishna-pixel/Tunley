import UIKit
import UniformTypeIdentifiers

/// The user's Tunely folder (`05` §8): picked once, kept as a security-scoped bookmark.
final class Bookmarks: NSObject, UIDocumentPickerDelegate {
  private static let defaultsKey = "tunely_engine.bookmarks"
  private var completion: ((Result<String?, EngineError>) -> Void)?

  func pickFolder(completion: @escaping (Result<String?, EngineError>) -> Void) {
    guard let host = Presenter.top() else {
      completion(.failure(.io("Nothing to present the folder picker from.")))
      return
    }
    self.completion = completion
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    // TODO(question #4): suggest iCloud Drive › Tunely once the iCloud container entitlement exists.
    host.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let completion, let url = urls.first else { return }
    self.completion = nil
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
    do {
      let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      let id = UUID().uuidString
      var all = Self.stored()
      all[id] = data
      UserDefaults.standard.set(all, forKey: Self.defaultsKey)
      completion(.success(id))
    } catch {
      completion(.failure(EngineError.from(error)))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completion?(.success(nil))
    completion = nil
  }

  func folderName(_ id: String) -> String? {
    try? resolve(id).lastPathComponent
  }

  /// iCloud Drive folders are ubiquitous items (or live under Mobile Documents).
  func isICloud(_ id: String) -> Bool {
    guard let folder = try? resolve(id) else { return false }
    let accessing = folder.startAccessingSecurityScopedResource()
    defer { if accessing { folder.stopAccessingSecurityScopedResource() } }
    let ubiquitous = (try? folder.resourceValues(forKeys: [.isUbiquitousItemKey]))?.isUbiquitousItem
    return ubiquitous ?? folder.path.contains("/Mobile Documents/")
  }

  /// Copies `source` into the folder. Duplicate names get " 2", " 3".
  func copy(_ source: URL, toFolder id: String) throws -> String {
    let folder = try resolve(id)
    guard folder.startAccessingSecurityScopedResource() else {
      throw EngineError.staleBookmark
    }
    defer { folder.stopAccessingSecurityScopedResource() }
    guard FileManager.default.fileExists(atPath: folder.path) else {
      throw EngineError.staleBookmark
    }

    let base = source.deletingPathExtension().lastPathComponent
    let target = Storage.uniqueURL(in: folder, base: base, ext: source.pathExtension)
    var coordinationError: NSError?
    var copyError: Error?
    NSFileCoordinator().coordinate(writingItemAt: target, options: .forReplacing, error: &coordinationError) { url in
      do {
        try FileManager.default.copyItem(at: source, to: url)
      } catch {
        copyError = error
      }
    }
    if let error = coordinationError ?? copyError {
      throw EngineError.from(error)
    }
    return target.lastPathComponent
  }

  private func resolve(_ id: String) throws -> URL {
    guard let data = Self.stored()[id] else {
      throw EngineError.staleBookmark
    }
    var stale = false
    guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
    else {
      throw EngineError.staleBookmark
    }
    if stale {
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      guard let fresh = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      else {
        throw EngineError.staleBookmark
      }
      var all = Self.stored()
      all[id] = fresh
      UserDefaults.standard.set(all, forKey: Self.defaultsKey)
    }
    return url
  }

  private static func stored() -> [String: Data] {
    UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Data] ?? [:]
  }
}
