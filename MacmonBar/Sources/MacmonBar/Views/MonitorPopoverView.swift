import SwiftUI

struct MonitorPopoverView: View {
  let store: MonitorStore
  @State private var page: MonitorPopoverPage = .dashboard
  private let appVersion = AppVersion.current

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { _ in
      content
    }
    .onAppear {
      store.interfaceDidOpen()
    }
    .onDisappear {
      store.interfaceDidClose()
    }
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 10) {
      header

      Group {
        switch page {
        case .dashboard:
          dashboard
        case .settings:
          MenuBarSettingsView(store: store)
        }
      }

      Divider()

      footer
    }
    .padding(12)
    .frame(width: 520)
  }

  @ViewBuilder
  private var dashboard: some View {
    if let snapshot = store.snapshot {
      SnapshotContentView(snapshot: snapshot, history: store.history)
    } else {
      EmptyMonitorView(status: store.status)
    }
  }

  private var header: some View {
    HStack(spacing: 10) {
      if page == .settings {
        Button(action: showDashboard) {
          Label("Back", systemImage: "chevron.left")
            .labelStyle(.iconOnly)
            .frame(width: 22, height: 22)
        }
        .buttonStyle(.borderless)
        .help("Back")
      } else {
        Image(systemName: store.status.symbolName)
          .foregroundStyle(store.status.tint)
          .symbolRenderingMode(.hierarchical)
          .font(.headline)
          .frame(width: 22, height: 22)
          .accessibilityHidden(true)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(headerTitle)
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .lineLimit(1)

        Text(headerSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      if page == .dashboard {
        IntervalControlView(
          intervalTitle: store.intervalTitle,
          canDecrease: store.canDecreaseInterval,
          canIncrease: store.canIncreaseInterval,
          decreaseAction: store.decreaseInterval,
          increaseAction: store.increaseInterval
        )

        Button(action: showSettings) {
          Label("Settings", systemImage: "gearshape")
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.borderless)
        .help("Settings")
      }

      Button {
        NSApplication.shared.terminate(nil)
      } label: {
        Label("Quit MacmonBar", systemImage: "power")
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.borderless)
      .help("Quit MacmonBar")
    }
  }

  private var footer: some View {
    HStack {
      Text(store.lastUpdated ?? .now, style: .time)
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()

      Text("·")
        .font(.caption)
        .foregroundStyle(.tertiary)

      Text("\(store.history.count) samples")
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()

      Spacer()

      Text(appVersion.displayText)
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }

  private var headerSubtitle: String {
    switch page {
    case .dashboard:
      return store.status == .live ? "Sampling every \(store.activeIntervalTitle)" : store.status.message
    case .settings:
      return "Menu bar display"
    }
  }

  private var headerTitle: String {
    switch page {
    case .dashboard:
      return store.snapshot.map(MetricText.chipLine) ?? "Macmon"
    case .settings:
      return "Settings"
    }
  }

  private func showSettings() {
    withAnimation(.snappy(duration: 0.18)) {
      page = .settings
    }
  }

  private func showDashboard() {
    withAnimation(.snappy(duration: 0.18)) {
      page = .dashboard
    }
  }
}
