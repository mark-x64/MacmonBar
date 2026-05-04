import SwiftUI

struct MiniMenuBarSparklineView: View {
  let series: [SparkSeries]

  var body: some View {
    Canvas { context, size in
      for item in series {
        draw(
          values: item.values.suffix(SparklineLayout.visibleSampleCapacity),
          color: item.color,
          in: &context,
          size: size
        )
      }
    }
    .accessibilityHidden(true)
  }

  private func draw(
    values: ArraySlice<Double>,
    color: Color,
    in context: inout GraphicsContext,
    size: CGSize
  ) {
    guard !values.isEmpty else {
      return
    }

    let values = Array(values)

    if values.count == 1 {
      let point = CGPoint(x: size.width, y: size.height * (1 - min(max(values[0], 0), 1)))
      context.fill(Path(ellipseIn: CGRect(x: point.x - 1.5, y: point.y - 1.5, width: 3, height: 3)), with: .color(color))
      return
    }

    var path = Path()

    for (index, value) in values.enumerated() {
      let x = SparklineLayout.xPosition(
        index: index,
        visibleSampleCount: values.count,
        width: size.width
      )
      let yRatio = 1 - min(max(value, 0), 1)
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
      style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
    )
  }
}
