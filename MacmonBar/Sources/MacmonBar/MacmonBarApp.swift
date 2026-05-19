import SwiftUI

@main
@MainActor
struct MacmonBarApp: App {
  @State private var monitor: MonitorStore

  init() {
    let monitor = MonitorStore()
    _monitor = State(initialValue: monitor)
    monitor.start()
  }

  var body: some Scene {
    MenuBarExtra {
      MonitorPopoverView(store: monitor)
    } label: {
      MenuBarLabelView(
        snapshot: monitor.snapshot,
        history: monitor.history,
        status: monitor.status,
        showsText: monitor.showsMenuBarText,
        showsGraph: monitor.showsMenuBarGraph,
        showsTextLabels: monitor.showsMenuBarTextLabels,
        metrics: monitor.selectedMenuBarMetrics,
        isPanelOpen: monitor.isInterfaceVisible
      )
    }
    .menuBarExtraStyle(.window)
  }
}
