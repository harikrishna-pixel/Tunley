import BackgroundTasks
import Foundation

/// iOS 26 `BGContinuedProcessingTask` for batches and long merges (`05` §9).
/// The system shows its own progress UI and may still stop the task.
@available(iOS 26.0, *)
final class ContinuedBatch {
  static let shared = ContinuedBatch()

  private let lock = NSLock()
  private var task: BGContinuedProcessingTask?
  private var registered = false
  private var completed: Int64 = 0
  private var total: Int64 = 1
  private var subtitle = ""

  private var prefix: String { (Bundle.main.bundleIdentifier ?? "tunely") + ".batch" }

  func start(title: String) -> Bool {
    if !registered {
      registered = BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "\(prefix).*", using: nil
      ) { [weak self] task in
        guard let self, let continued = task as? BGContinuedProcessingTask else {
          task.setTaskCompleted(success: false)
          return
        }
        self.lock.lock()
        self.task = continued
        continued.progress.totalUnitCount = self.total
        continued.progress.completedUnitCount = self.completed
        self.lock.unlock()
        continued.expirationHandler = { [weak self] in self?.finish(success: false) }
      }
    }
    let request = BGContinuedProcessingTaskRequest(
      identifier: "\(prefix).\(UUID().uuidString)", title: title, subtitle: subtitle)
    request.strategy = .fail
    do {
      try BGTaskScheduler.shared.submit(request)
      return true
    } catch {
      return false
    }
  }

  func update(completed: Int, total: Int, subtitle: String) {
    lock.lock(); defer { lock.unlock() }
    self.completed = Int64(completed)
    self.total = Int64(max(1, total))
    self.subtitle = subtitle
    guard let task else { return }
    task.progress.totalUnitCount = self.total
    task.progress.completedUnitCount = self.completed
    task.updateTitle(task.title, subtitle: subtitle)
  }

  func finish(success: Bool) {
    lock.lock()
    let current = task
    task = nil
    lock.unlock()
    current?.setTaskCompleted(success: success)
  }
}
