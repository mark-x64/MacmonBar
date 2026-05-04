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

      if showsText || showsGraph {
        Image(
          nsImage: MenuBarLabelImageRenderer.image(
            snapshot: snapshot,
            history: history,
            metrics: metrics,
            showsText: showsText,
            showsGraph: showsGraph,
            showsLabels: showsTextLabels
          )
        )
          .interpolation(.high)
          .accessibilityLabel(accessibilityLabel)
      }
    }
    .id(revision)
  }

  private var accessibilityLabel: String {
    guard let snapshot else {
      return "Macmon"
    }

    var parts: [String] = []
    if showsText {
      parts.append(metrics.compactText(for: snapshot, includeLabels: showsTextLabels))
    }
    if showsGraph {
      parts.append("graph")
    }
    return parts.joined(separator: ", ")
  }
}
