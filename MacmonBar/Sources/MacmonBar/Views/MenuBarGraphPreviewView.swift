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
      return metrics.flatMap { metric in
        if metric == .network {
          return [
            SparkSeries(color: .orange, values: [0.35, 0.35]),
            SparkSeries(color: .green, values: [0.65, 0.65]),
          ]
        }

        return [SparkSeries(color: metric.menuBarColor, values: [0.5, 0.5])]
      }
    }

    let sourceHistory = history.isEmpty ? [snapshot] : history

    return metrics.flatMap { metric in
      if metric == .network {
        let values = metric.normalizedNetworkValues(from: sourceHistory)
        return [
          SparkSeries(color: .orange, values: values.upload),
          SparkSeries(color: .green, values: values.download),
        ]
      }

      return [
        SparkSeries(
          color: metric.menuBarColor,
          values: metric.normalizedValues(from: sourceHistory)
        ),
      ]
    }
  }
}
