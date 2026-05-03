import SwiftUI

struct MenuBarLabelView: View {
  let snapshot: MetricSnapshot?
  let history: [MetricSnapshot]
  let status: MonitorStatus
  let showsText: Bool
  let showsGraph: Bool
  let showsTextLabels: Bool
  let metrics: [MenuBarMetric]
  let revision: Int

  var body: some View {
    HStack(spacing: 5) {
      if !showsText && !showsGraph {
        Image(systemName: status.symbolName)
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(status.tint)
          .accessibilityHidden(true)
      }

      if showsText {
        Text(labelText)
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }

      if showsGraph {
        Image(nsImage: MenuBarGraphRenderer.image(snapshot: snapshot, history: history, metrics: metrics))
          .interpolation(.high)
          .frame(width: 46, height: 16)
          .accessibilityHidden(true)
      }
    }
    .id(revision)
  }

  private var labelText: String {
    guard let snapshot else {
      return "Macmon"
    }

    return metrics.compactText(for: snapshot, includeLabels: showsTextLabels)
  }
}
