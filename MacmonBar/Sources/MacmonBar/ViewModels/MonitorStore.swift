import Foundation
import Observation

@MainActor
@Observable
final class MonitorStore {
  private let client: MacmonProcessClient
  private let historyLimit = 90
  private let intervalPreferenceKey = "sampleIntervalMilliseconds"
  private let minimumIntervalMilliseconds = 500
  private let maximumIntervalMilliseconds = 10_000
  private let intervalStepMilliseconds = 250
  private let menuBarStylePreferenceKey = "menuBarDisplayStyle"
  private let menuBarMetricsPreferenceKey = "menuBarMetrics"
  private let minimumPublishInterval: TimeInterval = 1
  private var streamTask: Task<Void, Never>?
  private var streamGeneration = 0
  @ObservationIgnored private var historyBuffer: [MetricSnapshot] = []
  @ObservationIgnored private var lastPublishDate = Date.distantPast

  var sampleIntervalMilliseconds: Int
  var menuBarDisplayStyle: MenuBarDisplayStyle {
    didSet {
      UserDefaults.standard.set(menuBarDisplayStyle.rawValue, forKey: menuBarStylePreferenceKey)
    }
  }

  var selectedMenuBarMetrics: [MenuBarMetric] {
    didSet {
      UserDefaults.standard.set(
        selectedMenuBarMetrics.map(\.rawValue),
        forKey: menuBarMetricsPreferenceKey
      )
    }
  }

  var snapshot: MetricSnapshot?
  var history: [MetricSnapshot] = []
  var status: MonitorStatus = .starting
  var lastUpdated: Date?
  var revision = 0

  var menuBarTitle: String {
    guard let snapshot else {
      return "Macmon"
    }

    return selectedMenuBarMetrics.compactText(for: snapshot)
  }

  var intervalTitle: String {
    let seconds = Double(sampleIntervalMilliseconds) / 1_000
    return "\(seconds.formatted(.number.precision(.fractionLength(seconds < 1 ? 2 : 1))))s"
  }

  var canDecreaseInterval: Bool {
    sampleIntervalMilliseconds > minimumIntervalMilliseconds
  }

  var canIncreaseInterval: Bool {
    sampleIntervalMilliseconds < maximumIntervalMilliseconds
  }

  init(client: MacmonProcessClient = MacmonProcessClient()) {
    self.client = client
    self.sampleIntervalMilliseconds = Self.loadInterval(
      key: intervalPreferenceKey,
      minimum: minimumIntervalMilliseconds,
      maximum: maximumIntervalMilliseconds
    )
    self.menuBarDisplayStyle = Self.loadMenuBarDisplayStyle(key: menuBarStylePreferenceKey)
    self.selectedMenuBarMetrics = Self.loadMenuBarMetrics(key: menuBarMetricsPreferenceKey)
  }

  func start() {
    guard streamTask == nil else {
      return
    }

    streamGeneration += 1
    let generation = streamGeneration
    status = .starting
    streamTask = Task {
      await consumeSnapshots(generation: generation)
    }
  }

  func restart() {
    stop()
    start()
  }

  func stop() {
    streamGeneration += 1
    streamTask?.cancel()
    streamTask = nil
    status = .stopped
  }

  func decreaseInterval() {
    updateInterval(sampleIntervalMilliseconds - intervalStepMilliseconds)
  }

  func increaseInterval() {
    updateInterval(sampleIntervalMilliseconds + intervalStepMilliseconds)
  }

  func toggleMenuBarMetric(_ metric: MenuBarMetric) {
    if let index = selectedMenuBarMetrics.firstIndex(of: metric) {
      guard selectedMenuBarMetrics.count > 1 else {
        return
      }

      selectedMenuBarMetrics.remove(at: index)
    } else {
      selectedMenuBarMetrics.append(metric)
    }
  }

  func isMenuBarMetricSelected(_ metric: MenuBarMetric) -> Bool {
    selectedMenuBarMetrics.contains(metric)
  }

  private func updateInterval(_ intervalMilliseconds: Int) {
    let nextInterval = intervalMilliseconds.clamped(
      to: minimumIntervalMilliseconds...maximumIntervalMilliseconds
    )

    guard nextInterval != sampleIntervalMilliseconds else {
      return
    }

    sampleIntervalMilliseconds = nextInterval
    UserDefaults.standard.set(nextInterval, forKey: intervalPreferenceKey)
    restart()
  }

  private func consumeSnapshots(generation: Int) async {
    do {
      for try await nextSnapshot in client.snapshots(intervalMilliseconds: sampleIntervalMilliseconds) {
        apply(nextSnapshot)
      }

      if !Task.isCancelled {
        status = .stopped
      }
    } catch {
      if !Task.isCancelled {
        status = .unavailable(error.localizedDescription)
      }
    }

    if streamGeneration == generation {
      streamTask = nil
    }
  }

  private func apply(_ nextSnapshot: MetricSnapshot) {
    historyBuffer.append(nextSnapshot)

    if historyBuffer.count > historyLimit {
      historyBuffer.removeFirst(historyBuffer.count - historyLimit)
    }

    let now = Date.now
    let shouldPublish = snapshot == nil || now.timeIntervalSince(lastPublishDate) >= minimumPublishInterval

    guard shouldPublish else {
      return
    }

    snapshot = nextSnapshot
    history = historyBuffer
    lastUpdated = now
    lastPublishDate = now
    status = .live
    revision += 1
  }

  private static func loadInterval(key: String, minimum: Int, maximum: Int) -> Int {
    let savedInterval = UserDefaults.standard.integer(forKey: key)
    let interval = savedInterval == 0 ? 1_000 : savedInterval

    return interval.clamped(to: minimum...maximum)
  }

  private static func loadMenuBarDisplayStyle(key: String) -> MenuBarDisplayStyle {
    guard
      let rawValue = UserDefaults.standard.string(forKey: key),
      let style = MenuBarDisplayStyle(rawValue: rawValue)
    else {
      return .combined
    }

    return style
  }

  private static func loadMenuBarMetrics(key: String) -> [MenuBarMetric] {
    guard let rawValues = UserDefaults.standard.stringArray(forKey: key) else {
      return [.power, .cpuTotal]
    }

    let metrics = rawValues.compactMap(MenuBarMetric.init(rawValue:))
    return metrics.isEmpty ? [.power, .cpuTotal] : metrics
  }
}

private extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}
