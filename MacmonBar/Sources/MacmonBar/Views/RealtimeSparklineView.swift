import SwiftUI

struct RealtimeSparklineView: View {
  let series: [SparkSeries]
  let maxValue: Double

  var body: some View {
    Canvas { context, size in
      drawGrid(in: &context, size: size)

      for item in series {
        draw(values: item.values.suffix(90), color: item.color, in: &context, size: size)
      }
    }
    .accessibilityHidden(true)
  }

  private func drawGrid(in context: inout GraphicsContext, size: CGSize) {
    let color = Color.secondary.opacity(0.14)

    for ratio in [0.0, 0.5, 1.0] {
      let y = size.height * ratio
      var path = Path()
      path.move(to: CGPoint(x: 0, y: y))
      path.addLine(to: CGPoint(x: size.width, y: y))
      context.stroke(path, with: .color(color), lineWidth: 1)
    }
  }

  private func draw(
    values: ArraySlice<Double>,
    color: Color,
    in context: inout GraphicsContext,
    size: CGSize
  ) {
    guard values.count > 1, maxValue > 0 else {
      return
    }

    let values = Array(values)
    var path = Path()

    for (index, value) in values.enumerated() {
      let x = size.width * Double(index) / Double(values.count - 1)
      let yRatio = 1 - min(max(value / maxValue, 0), 1)
      let point = CGPoint(x: x, y: size.height * yRatio)

      if index == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }

    context.stroke(
      path,
      with: .color(color),
      style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
    )
  }
}
