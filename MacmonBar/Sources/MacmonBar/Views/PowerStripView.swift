import SwiftUI

struct PowerStripView: View {
  let snapshot: MetricSnapshot
  let history: [MetricSnapshot]

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .firstTextBaseline) {
        Text("Power")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Spacer()

        Text("Total \(MetricText.watts(snapshot.sysPower))")
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .foregroundStyle(.primary)
          .monospacedDigit()
      }

      HStack(spacing: 10) {
        powerColumn("CPU", value: snapshot.cpuPower, temp: snapshot.temp.cpuAverage, color: .blue)
        powerColumn("GPU", value: snapshot.gpuPower, temp: snapshot.temp.gpuAverage, color: .purple)
        powerColumn("ANE", value: snapshot.anePower, temp: nil, color: .teal)
      }

      RealtimeSparklineView(
        series: [
          SparkSeries(color: .blue, values: history.map(\.cpuPower)),
          SparkSeries(color: .purple, values: history.map(\.gpuPower)),
          SparkSeries(color: .teal, values: history.map(\.anePower)),
          SparkSeries(color: .primary, values: history.map(\.allPower)),
        ],
        maxValue: max(history.map(\.allPower).maximum * 1.2, 1)
      )
      .frame(height: 42)
    }
    .padding(10)
    .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
  }

  private func powerColumn(_ label: String, value: Double, temp: Double?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption2)
        .foregroundStyle(color)
        .fontWeight(.semibold)

      Text(MetricText.watts(value))
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .monospacedDigit()

      Text(temp.map(MetricText.temperature) ?? " ")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private extension Array where Element == Double {
  var maximum: Double {
    self.max() ?? 0
  }
}
