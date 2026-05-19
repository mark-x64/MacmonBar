import SwiftUI

struct ProcessPowerChartView: View {
  let processes: [ProcessPowerMetric]

  private let cornerRadius: CGFloat = 8

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      HStack(alignment: .firstTextBaseline) {
        Text("Top process power")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Spacer(minLength: 8)

        Text("estimated")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }

      if processes.isEmpty {
        Text("Collecting process baseline")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
      } else {
        VStack(spacing: 5) {
          ForEach(processes.prefix(5)) { process in
            ProcessPowerRowView(
              process: process,
              maxPower: maxPower
            )
          }
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.top, 8)
    .padding(.bottom, 9)
    .background(.background, in: backgroundShape)
    .overlay {
      ProcessPowerTableBorder(cornerRadius: cornerRadius)
        .stroke(.secondary.opacity(0.12), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
  }

  private var maxPower: Double {
    max(processes.map(\.estimatedPower).max() ?? 0, 0.1)
  }

  private var backgroundShape: UnevenRoundedRectangle {
    UnevenRoundedRectangle(
      topLeadingRadius: 0,
      bottomLeadingRadius: cornerRadius,
      bottomTrailingRadius: cornerRadius,
      topTrailingRadius: 0
    )
  }
}

private struct ProcessPowerTableBorder: Shape {
  let cornerRadius: CGFloat

  func path(in rect: CGRect) -> Path {
    let radius = min(cornerRadius, min(rect.width, rect.height) / 2)

    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
    path.addQuadCurve(
      to: CGPoint(x: rect.minX + radius, y: rect.maxY),
      control: CGPoint(x: rect.minX, y: rect.maxY)
    )
    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
    path.addQuadCurve(
      to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
      control: CGPoint(x: rect.maxX, y: rect.maxY)
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

    return path
  }
}

private struct ProcessPowerRowView: View {
  let process: ProcessPowerMetric
  let maxPower: Double

  var body: some View {
    HStack(spacing: 8) {
      Text(process.name)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(width: 126, alignment: .leading)

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(.secondary.opacity(0.12))

          Capsule()
            .fill(.orange.opacity(0.82))
            .frame(width: barWidth(in: proxy.size.width))
        }
      }
      .frame(height: 6)

      Text(MetricText.watts(process.estimatedPower))
        .font(.system(.caption2, design: .rounded, weight: .semibold))
        .monospacedDigit()
        .lineLimit(1)
        .frame(width: 54, alignment: .trailing)
    }
    .frame(height: 14)
  }

  private func barWidth(in availableWidth: CGFloat) -> CGFloat {
    guard maxPower > 0, process.estimatedPower > 0 else {
      return 0
    }

    return max(4, availableWidth * min(process.estimatedPower / maxPower, 1))
  }
}
