import SwiftUI

struct SnapshotContentView: View {
  let snapshot: MetricSnapshot
  let history: [MetricSnapshot]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      LazyVGrid(columns: columns, spacing: 8) {
        RealtimeMetricTileView(
          title: "\(snapshot.soc?.pcpuLabel ?? "P")-CPU",
          value: "\(MetricText.percent(snapshot.pcpuUsage.utilizationRatio)) @ \(snapshot.pcpuUsage.frequencyMHz) MHz",
          detail: "Performance cluster",
          maxValue: 100,
          series: [SparkSeries(color: .blue, values: history.map { $0.pcpuUsage.utilizationRatio * 100 })]
        )

        RealtimeMetricTileView(
          title: "\(snapshot.soc?.ecpuLabel ?? "E")-CPU",
          value: "\(MetricText.percent(snapshot.ecpuUsage.utilizationRatio)) @ \(snapshot.ecpuUsage.frequencyMHz) MHz",
          detail: "Efficiency cluster",
          maxValue: 100,
          series: [SparkSeries(color: .green, values: history.map { $0.ecpuUsage.utilizationRatio * 100 })]
        )

        RealtimeMetricTileView(
          title: "RAM",
          value: "\(MetricText.gigabytes(snapshot.memory.ramUsage)) / \(MetricText.gigabytes(snapshot.memory.ramTotal, precision: 0))",
          detail: "SWAP \(MetricText.gigabytes(snapshot.memory.swapUsage))",
          maxValue: memoryUpperBound,
          series: [
            SparkSeries(color: .orange, values: history.map { Double($0.memory.ramUsage) / 1_073_741_824 }),
            SparkSeries(color: .red, values: history.map { Double($0.memory.swapUsage) / 1_073_741_824 }),
          ]
        )

        RealtimeMetricTileView(
          title: "GPU",
          value: "\(MetricText.percent(snapshot.gpuUsage.utilizationRatio)) @ \(snapshot.gpuUsage.frequencyMHz) MHz",
          detail: "\(snapshot.soc?.gpuCores ?? 0) cores",
          maxValue: 100,
          series: [SparkSeries(color: .purple, values: history.map { $0.gpuUsage.utilizationRatio * 100 })]
        )
      }

      NetworkBlockView(snapshot: snapshot, history: history)

      VStack(spacing: 0) {
        PowerStripView(snapshot: snapshot, history: history)
          .zIndex(1)

        ProcessPowerChartView(processes: snapshot.processPower)
          .padding(.horizontal, 16)
          .padding(.top, -1)
      }
    }
  }

  private let columns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  private var memoryUpperBound: Double {
    max(Double(snapshot.memory.ramTotal) / 1_073_741_824, 1)
  }
}
