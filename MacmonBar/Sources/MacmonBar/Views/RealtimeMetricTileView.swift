import SwiftUI

struct RealtimeMetricTileView: View {
  let title: String
  let value: String
  let detail: String
  let maxValue: Double
  let series: [SparkSeries]

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .firstTextBaseline) {
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer(minLength: 8)

        Text(detail)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }

      Text(value)
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)

      RealtimeSparklineView(series: series, maxValue: maxValue)
        .frame(height: 48)
    }
    .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
    .padding(10)
    .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
  }
}
