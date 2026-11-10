import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// PHPicker for videos. Needs no Photos permission; each pick is copied into
/// `Documents/Picked/` so the grid still shows them after a relaunch.
final class VideoPicker: NSObject, PHPickerViewControllerDelegate {
  private var completion: ((Result<[URL], EngineError>) -> Void)?

  func present(maxCount: Int, completion: @escaping (Result<[URL], EngineError>) -> Void) {
    guard let host = Presenter.top() else {
      completion(.failure(.io("Nothing to present the picker from.")))
      return
    }
    self.completion = completion
    var config = PHPickerConfiguration()
    config.filter = .videos
    config.selectionLimit = max(0, maxCount)
    config.preferredAssetRepresentationMode = .current
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    host.present(picker, animated: true)
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let completion else { return }
    self.completion = nil
    if results.isEmpty {
      completion(.success([]))
      return
    }

    let dir: URL
    do {
      try Storage.ensureDir(Storage.pickedDir)
      dir = Storage.pickedDir
    } catch {
      completion(.failure(EngineError.from(error)))
      return
    }

    let group = DispatchGroup()
    let lock = NSLock()
    var copies = [URL?](repeating: nil, count: results.count)
    var failure: EngineError?
    for (index, result) in results.enumerated() {
      let provider = result.itemProvider
      guard let type = provider.registeredTypeIdentifiers.first(where: {
        UTType($0)?.conforms(to: .movie) == true
      }) ?? (provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
        ? UTType.movie.identifier : nil)
      else {
        lock.lock(); failure = failure ?? .unreadable(); lock.unlock()
        continue
      }
      group.enter()
      provider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
        defer { group.leave() }
        guard let url else {
          let code: EngineError = (error as NSError?)?.domain == NSCocoaErrorDomain ? .icloud : .unreadable()
          lock.lock(); failure = failure ?? code; lock.unlock()
          return
        }
        let name = Storage.sanitize(provider.suggestedName ?? url.deletingPathExtension().lastPathComponent)
        let target = Storage.uniqueURL(in: dir, base: name, ext: url.pathExtension.lowercased())
        do {
          try FileManager.default.copyItem(at: url, to: target)
          lock.lock(); copies[index] = target; lock.unlock()
        } catch {
          lock.lock(); failure = failure ?? EngineError.from(error); lock.unlock()
        }
      }
    }
    group.notify(queue: .main) {
      let picked = copies.compactMap { $0 }
      if picked.isEmpty, let failure {
        completion(.failure(failure))
      } else {
        completion(.success(picked))
      }
    }
  }
}

enum Presenter {
  static func top() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? scenes.first?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
