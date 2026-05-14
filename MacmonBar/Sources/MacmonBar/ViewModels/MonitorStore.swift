import Foundation
import Observation

@MainActor
@Observable
final class MonitorStore {
  private let client: MacmonProcessClient
  private let historyLimit = 90
  private let intervalPreferenceKey = "sampleIntervalMilliseconds"
  private let minimumIntervalMilliseconds = 500
  private let minimumMenuBarIntervalMilliseconds = 1_000
  private let maximumIntervalMilliseconds = 10_000
  private let intervalStepMilliseconds = 250
  private let legacyMenuBarStylePreferenceKey = "menuBarDisplayStyle"
  private let menuBarShowsTextPreferenceKey = "menuBarShowsText"
  private let menuBarShowsGraphPreferenceKey = "menuBarShowsGraph"
  private let menuBarTextShowsLabelsPreferenceKey = "menuBarTextShowsLabels"
  private let menuBarMetricsPreferenceKey = "menuBarMetrics"
  private var streamTask: Task<Void, Never>?
  private var snapshotSession: MacmonSnapshotSession?
  private var streamGeneration = 0
  @ObservationIgnored private var historyBuffer: [MetricSnapshot] = []
  @ObservationIgnored private var lastPublishDate = Date.distantPast
  @ObservationIgnored private var isInterfaceVisible = false

  var sampleIntervalMilliseconds: Int
  var showsMenuBarText: Bool {
    didSet {
      UserDefaults.standard.set(showsMenuBarText, forKey: menuBarShowsTextPreferenceKey)
      revision += 1
    }
  }

  var showsMenuBarGraph: Bool {
    didSet {
      UserDefaults.standard.set(showsMenuBarGraph, forKey: menuBarShowsGraphPreferenceKey)
      revision += 1
    }
  }

  var showsMenuBarTextLabels: Bool {
    didSet {
      UserDefaults.standard.set(showsMenuBarTextLabels, forKey: menuBarTextShowsLabelsPreferenceKey)
      revision += 1
    }
  }

  var selectedMenuBarMetrics: [MenuBarMetric] {
    didSet {
      UserDefaults.standard.set(
        selectedMenuBarMetrics.map(\.rawValue),
        forKey: menuBarMetricsPreferenceKey
      )
      revision += 1
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

    return selectedMenuBarMetrics.compactText(for: snapshot, includeLabels: showsMenuBarTextLabels)
  }

  var intervalTitle: String {
    Self.intervalTitle(for: sampleIntervalMilliseconds)
  }

  var activeIntervalTitle: String {
    Self.intervalTitle(for: effectiveIntervalMilliseconds)
  }

  private var effectiveIntervalMilliseconds: Int {
    Self.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: sampleIntervalMilliseconds,
      isInterfaceVisible: isInterfaceVisible,
      minimumMenuBarIntervalMilliseconds: minimumMenuBarIntervalMilliseconds
    )
  }

  private static func intervalTitle(for intervalMilliseconds: Int) -> String {
    let seconds = Double(intervalMilliseconds) / 1_000
    return "\(seconds.formatted(.number.precision(.fractionLength(seconds < 1 ? 2 : 1))))s"
  }

  nonisolated static func resolvedIntervalMilliseconds(
    sampleIntervalMilliseconds: Int,
    isInterfaceVisible: Bool,
    minimumMenuBarIntervalMilliseconds: Int
  ) -> Int {
    if isInterfaceVisible {
      return sampleIntervalMilliseconds
    }

    return max(sampleIntervalMilliseconds, minimumMenuBarIntervalMilliseconds)
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
    let presentation = Self.loadMenuBarPresentation(
      textKey: menuBarShowsTextPreferenceKey,
      graphKey: menuBarShowsGraphPreferenceKey,
      legacyStyleKey: legacyMenuBarStylePreferenceKey
    )
    self.showsMenuBarText = presentation.showsText
    self.showsMenuBarGraph = presentation.showsGraph
    self.showsMenuBarTextLabels = Self.loadMenuBarTextShowsLabels(key: menuBarTextShowsLabelsPreferenceKey)
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
    snapshotSession?.cancel()
    snapshotSession = nil
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

  func interfaceDidOpen() {
    guard !isInterfaceVisible else {
      return
    }

    isInterfaceVisible = true
    restart()
  }

  func interfaceDidClose() {
    guard isInterfaceVisible else {
      return
    }

    isInterfaceVisible = false
    restart()
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

  func toggleMenuBarPresentation(_ presentation: MenuBarPresentationKind) {
    switch presentation {
    case .text:
      showsMenuBarText.toggle()
    case .graph:
      showsMenuBarGraph.toggle()
    }
  }

  func isMenuBarPresentationSelected(_ presentation: MenuBarPresentationKind) -> Bool {
    switch presentation {
    case .text:
      return showsMenuBarText
    case .graph:
      return showsMenuBarGraph
    }
  }

  private func updateInterval(_ intervalMilliseconds: Int) {
    let nextInterval = intervalMilliseconds.clamped(
      to: minimumIntervalMilliseconds...maximumIntervalMilliseconds
    )

    guard nextInterval != sampleIntervalMilliseconds else {
      return
    }

    let previousEffectiveInterval = effectiveIntervalMilliseconds
    sampleIntervalMilliseconds = nextInterval
    UserDefaults.standard.set(nextInterval, forKey: intervalPreferenceKey)

    if effectiveIntervalMilliseconds != previousEffectiveInterval {
      restartImmediately()
    }
  }

  private func consumeSnapshots(generation: Int) async {
    let intervalMilliseconds = effectiveIntervalMilliseconds
    let session = client.startSnapshots(
      intervalMilliseconds: intervalMilliseconds,
      includesProcessPower: isInterfaceVisible
    )
    snapshotSession = session

    do {
      for try await nextSnapshot in session.stream {
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
      snapshotSession = nil
      streamTask = nil
    }
  }

  private func restartImmediately() {
    stop()
    lastPublishDate = .distantPast
    start()
  }

  private func apply(_ nextSnapshot: MetricSnapshot) {
    historyBuffer.append(nextSnapshot)

    if historyBuffer.count > historyLimit {
      historyBuffer.removeFirst(historyBuffer.count - historyLimit)
    }

    let now = Date.now
    let minimumPublishInterval = isInterfaceVisible
      ? 0
      : TimeInterval(minimumMenuBarIntervalMilliseconds) / 1_000
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

  private static func loadMenuBarPresentation(
    textKey: String,
    graphKey: String,
    legacyStyleKey: String
  ) -> MenuBarPresentationSelection {
    let defaults = UserDefaults.standard
    let legacy = legacyMenuBarPresentation(key: legacyStyleKey)
    let hasTextPreference = defaults.object(forKey: textKey) != nil
    let hasGraphPreference = defaults.object(forKey: graphKey) != nil

    return MenuBarPresentationSelection(
      showsText: hasTextPreference ? defaults.bool(forKey: textKey) : legacy.showsText,
      showsGraph: hasGraphPreference ? defaults.bool(forKey: graphKey) : legacy.showsGraph
    )
  }

  private static func legacyMenuBarPresentation(key: String) -> MenuBarPresentationSelection {
    switch UserDefaults.standard.string(forKey: key) {
    case "text":
      return MenuBarPresentationSelection(showsText: true, showsGraph: false)
    case "graph":
      return MenuBarPresentationSelection(showsText: false, showsGraph: true)
    case "combined":
      return MenuBarPresentationSelection(showsText: true, showsGraph: true)
    default:
      return MenuBarPresentationSelection(showsText: true, showsGraph: true)
    }
  }

  private static func loadMenuBarMetrics(key: String) -> [MenuBarMetric] {
    guard let rawValues = UserDefaults.standard.stringArray(forKey: key) else {
      return [.power, .cpuTotal]
    }

    let metrics = rawValues.reduce(into: [MenuBarMetric]()) { result, rawValue in
      let migratedMetrics: [MenuBarMetric]
      if rawValue == "networkUpload" || rawValue == "networkDownload" {
        migratedMetrics = [.network]
      } else if let metric = MenuBarMetric(rawValue: rawValue) {
        migratedMetrics = [metric]
      } else {
        migratedMetrics = []
      }

      for metric in migratedMetrics where !result.contains(metric) {
        result.append(metric)
      }
    }

    return metrics.isEmpty ? [.power, .cpuTotal] : metrics
  }

  private static func loadMenuBarTextShowsLabels(key: String) -> Bool {
    guard UserDefaults.standard.object(forKey: key) != nil else {
      return true
    }

    return UserDefaults.standard.bool(forKey: key)
  }
}

private extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    min(max(self, limits.lowerBound), limits.upperBound)
  }
}
