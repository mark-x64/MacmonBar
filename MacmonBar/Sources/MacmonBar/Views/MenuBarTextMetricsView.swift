import AppKit
import SwiftUI

struct MenuBarTextMetricsView: View {
  let snapshot: MetricSnapshot?
  let metrics: [MenuBarMetric]
  let showsLabels: Bool
  var font: Font = .body
  var networkFont: Font = .caption2
  var spacing: CGFloat = 5
  var rendersNetworkAsImage = false

  var body: some View {
    HStack(alignment: .center, spacing: spacing) {
      if let snapshot {
        ForEach(metrics) { metric in
          metricView(metric, snapshot: snapshot)
        }
      } else {
        Text("Macmon")
          .font(font)
      }
    }
    .monospacedDigit()
    .fixedSize(horizontal: true, vertical: true)
  }

  @ViewBuilder
  private func metricView(_ metric: MenuBarMetric, snapshot: MetricSnapshot) -> some View {
    switch metric {
    case .network:
      if rendersNetworkAsImage {
        Image(
          nsImage: MenuBarNetworkTextRenderer.image(
            uploadBytesPerSecond: snapshot.network.uploadBytesPerSecond,
            downloadBytesPerSecond: snapshot.network.downloadBytesPerSecond
          )
        )
        .interpolation(.high)
        .accessibilityLabel(
          "Network upload \(MetricText.bytesPerSecond(snapshot.network.uploadBytesPerSecond)), download \(MetricText.bytesPerSecond(snapshot.network.downloadBytesPerSecond))"
        )
      } else {
        VStack(alignment: .leading, spacing: 0) {
          networkRateView(symbol: "↑", value: snapshot.network.uploadBytesPerSecond)
          networkRateView(symbol: "↓", value: snapshot.network.downloadBytesPerSecond)
        }
        .fixedSize(horizontal: true, vertical: true)
      }
    default:
      Text(metric.compactText(for: snapshot, includeLabel: showsLabels))
        .font(font)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }
  }

  private func networkRateView(symbol: String, value: Double) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 2) {
      Text(symbol)
        .font(networkFont.weight(.semibold))

      Text(MetricText.bytesPerSecond(value))
        .font(networkFont)
        .lineLimit(1)
    }
    .lineLimit(1)
    .fixedSize(horizontal: true, vertical: true)
  }
}
