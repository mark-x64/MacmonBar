import SwiftUI

struct MonitorPopoverView: View {
  let store: MonitorStore

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

      if let snapshot = store.snapshot {
        SnapshotContentView(snapshot: snapshot, history: store.history)
      } else {
        EmptyMonitorView(status: store.status)
      }

      MenuBarSettingsBlockView(store: store)

      Divider()

      footer
    }
    .padding(12)
    .frame(width: 520)
  }

  private var header: some View {
    HStack(spacing: 10) {
      Image(systemName: store.status.symbolName)
        .foregroundStyle(store.status.tint)
        .symbolRenderingMode(.hierarchical)
        .font(.headline)
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(store.snapshot.map(MetricText.chipLine) ?? "Macmon")
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .lineLimit(1)

        Text(headerSubtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer(minLength: 8)

      IntervalControlView(
        intervalTitle: store.intervalTitle,
        canDecrease: store.canDecreaseInterval,
        canIncrease: store.canIncreaseInterval,
        decreaseAction: store.decreaseInterval,
        increaseAction: store.increaseInterval
      )

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

      Text("macmon")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var headerSubtitle: String {
    store.status == .live ? "Sampling every \(store.activeIntervalTitle)" : store.status.message
  }
}
