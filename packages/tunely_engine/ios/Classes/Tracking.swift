import AppTrackingTransparency
import Foundation

/// App Tracking Transparency (44). Denied = non-personalised ads; the app
/// works the same either way.
enum Tracking {
  static func status() -> String {
    name(ATTrackingManager.trackingAuthorizationStatus)
  }

  static func request(_ completion: @escaping (String) -> Void) {
    DispatchQueue.main.async {
      ATTrackingManager.requestTrackingAuthorization { status in
        DispatchQueue.main.async { completion(name(status)) }
      }
    }
  }

  private static func name(_ status: ATTrackingManager.AuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "notDetermined"
    }
  }
}
