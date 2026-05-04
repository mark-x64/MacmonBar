import SwiftUI

struct MenuBarTextPreviewView: View {
  let snapshot: MetricSnapshot?
  let metrics: [MenuBarMetric]
  let showsLabels: Bool

  var body: some View {
    MenuBarTextMetricsView(
      snapshot: snapshot,
      metrics: metrics,
      showsLabels: showsLabels,
      font: .system(size: 18, weight: .semibold, design: .rounded),
      networkFont: .system(size: 11, weight: .semibold, design: .rounded),
      spacing: 7
    )
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.primary.opacity(0.09), in: .capsule)
  }
}
