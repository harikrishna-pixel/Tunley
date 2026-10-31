import StoreKit
import UIKit

/// Marberx app pages (45, 09d, 38) without leaving Tunely.
final class StorePage: NSObject, SKStoreProductViewControllerDelegate {
  static let shared = StorePage()

  func open(appStoreId: String, completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
      guard let presenter = Presenter.top() else {
        completion(false)
        return
      }
      let store = SKStoreProductViewController()
      store.delegate = self
      store.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appStoreId]) { loaded, _ in
        DispatchQueue.main.async {
          if !loaded {
            completion(false)
            return
          }
          presenter.present(store, animated: true)
          completion(true)
        }
      }
    }
  }

  func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
    viewController.dismiss(animated: true)
  }
}
