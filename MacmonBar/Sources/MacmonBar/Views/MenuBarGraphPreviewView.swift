import SwiftUI

struct MenuBarGraphPreviewView: View {
  let snapshot: MetricSnapshot?
  let history: [MetricSnapshot]
  let metrics: [MenuBarMetric]

  var body: some View {
    MiniMenuBarSparklineView(series: series)
      .frame(width: 140, height: 36)
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(Color.primary.opacity(0.09), in: .capsule)
  }

  private var series: [SparkSeries] {
    guard let snapshot else {
      return metrics.map { SparkSeries(color: $0.menuBarColor, values: [0.5, 0.5]) }
    }

    let sourceHistory = history.isEmpty ? [snapshot] : history

    return metrics.map { metric in
      SparkSeries(
        color: metric.menuBarColor,
        values: metric.normalizedValues(from: sourceHistory)
      )
    }
  }
}
