import SwiftUI

struct MenuBarStylePreviewView: View {
  let snapshot: MetricSnapshot?
  let history: [MetricSnapshot]
  let status: MonitorStatus
  let style: MenuBarDisplayStyle
  let metrics: [MenuBarMetric]
  let isPreview: Bool

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: status.symbolName)
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(status.tint)
        .accessibilityHidden(true)

      if style.showsGraph, let snapshot {
        MiniMenuBarSparklineView(series: series(for: snapshot))
          .frame(width: isPreview ? 74 : 44, height: isPreview ? 20 : 14)
      }

      if style.showsText || snapshot == nil {
        Text(labelText)
          .font(isPreview ? .caption : .body)
          .fontWeight(isPreview ? .semibold : .regular)
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
    .padding(.horizontal, isPreview ? 9 : 0)
    .padding(.vertical, isPreview ? 6 : 0)
    .background(isPreview ? Color.primary.opacity(0.08) : .clear, in: .capsule)
  }

  private var labelText: String {
    guard let snapshot else {
      return "Macmon"
    }

    return metrics.compactText(for: snapshot)
  }

  private func series(for snapshot: MetricSnapshot) -> [SparkSeries] {
    let sourceHistory = history.isEmpty ? [snapshot] : history

    return metrics.map { metric in
      SparkSeries(
        color: metric.color,
        values: metric.normalizedValues(from: sourceHistory)
      )
    }
  }
}

private extension MenuBarMetric {
  var color: Color {
    switch self {
    case .cpuTotal:
      return .cyan
    case .pCPU:
      return .blue
    case .eCPU:
      return .green
    case .gpu:
      return .purple
    case .memory:
      return .orange
    case .power:
      return .primary
    case .cpuPower:
      return .blue
    case .gpuPower:
      return .purple
    }
  }
}
