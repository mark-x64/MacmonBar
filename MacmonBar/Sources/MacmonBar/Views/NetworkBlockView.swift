import SwiftUI

struct NetworkBlockView: View {
  let snapshot: MetricSnapshot
  let history: [MetricSnapshot]

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .firstTextBaseline) {
        Text("Network")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Spacer()

        Text(totalTraffic)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }

      HStack(spacing: 10) {
        throughputColumn("Down", value: snapshot.network.downloadBytesPerSecond, color: .green)
        throughputColumn("Up", value: snapshot.network.uploadBytesPerSecond, color: .orange)
      }

      RealtimeSparklineView(
        series: [
          SparkSeries(color: .green, values: history.map(\.network.downloadBytesPerSecond)),
          SparkSeries(color: .orange, values: history.map(\.network.uploadBytesPerSecond)),
        ],
        maxValue: max(networkUpperBound * 1.2, 1)
      )
      .frame(height: 42)
    }
    .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
    .padding(10)
    .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
  }

  private var totalTraffic: String {
    "\(MetricText.bytes(snapshot.network.receivedBytes)) / \(MetricText.bytes(snapshot.network.transmittedBytes))"
  }

  private var networkUpperBound: Double {
    history
      .flatMap { [$0.network.downloadBytesPerSecond, $0.network.uploadBytesPerSecond] }
      .max() ?? 0
  }

  private func throughputColumn(_ label: String, value: Double, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption2)
        .foregroundStyle(color)
        .fontWeight(.semibold)

      Text(MetricText.bytesPerSecond(value))
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
