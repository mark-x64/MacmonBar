import AppKit
import Foundation

enum MenuBarGraphRenderer {
  static func image(
    snapshot: MetricSnapshot?,
    history: [MetricSnapshot],
    metrics: [MenuBarMetric],
    size: CGSize = CGSize(width: 46, height: 16)
  ) -> NSImage {
    let sourceHistory = snapshot.map { history.isEmpty ? [$0] : history } ?? []

    let image = NSImage(size: size, flipped: true) { rect in
      NSColor.clear.setFill()
      rect.fill()

      guard !sourceHistory.isEmpty else {
        drawPlaceholder(in: rect)
        return true
      }

      for metric in metrics {
        if metric == .network {
          let values = metric.normalizedNetworkValues(from: sourceHistory)
          draw(
            values: values.upload.suffix(SparklineLayout.visibleSampleCapacity),
            color: .systemOrange,
            in: rect
          )
          draw(
            values: values.download.suffix(SparklineLayout.visibleSampleCapacity),
            color: .systemGreen,
            in: rect
          )
        } else {
          draw(
            values: metric.normalizedValues(from: sourceHistory)
              .suffix(SparklineLayout.visibleSampleCapacity),
            color: metric.menuBarNSColor,
            in: rect
          )
        }
      }

      return true
    }

    image.isTemplate = false
    return image
  }

  private static func drawPlaceholder(in rect: CGRect) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.line(to: CGPoint(x: rect.maxX, y: rect.midY))
    NSColor.secondaryLabelColor.withAlphaComponent(0.55).setStroke()
    path.lineWidth = 1.4
    path.stroke()
  }

  private static func draw(values: ArraySlice<Double>, color: NSColor, in rect: CGRect) {
    guard !values.isEmpty else {
      return
    }

    let values = Array(values)
    let drawingRect = rect.insetBy(dx: 1, dy: 1)

    if values.count == 1 {
      drawDot(value: values[0], color: color, in: drawingRect)
      return
    }

    let path = NSBezierPath()
    path.lineJoinStyle = .round
    path.lineCapStyle = .round

    for (index, value) in values.enumerated() {
      let clampedValue = min(max(value, 0), 1)
      let x = drawingRect.minX + SparklineLayout.xPosition(
        index: index,
        visibleSampleCount: values.count,
        width: drawingRect.width
      )
      let y = drawingRect.maxY - drawingRect.height * clampedValue
      let point = CGPoint(x: x, y: y)

      if index == 0 {
        path.move(to: point)
      } else {
        path.line(to: point)
      }
    }

    color.withAlphaComponent(0.95).setStroke()
    path.lineWidth = 1.6
    path.stroke()
  }

  private static func drawDot(value: Double, color: NSColor, in rect: CGRect) {
    let clampedValue = min(max(value, 0), 1)
    let point = CGPoint(x: rect.maxX, y: rect.maxY - rect.height * clampedValue)
    let dotRect = CGRect(x: point.x - 1.6, y: point.y - 1.6, width: 3.2, height: 3.2)

    color.withAlphaComponent(0.95).setFill()
    NSBezierPath(ovalIn: dotRect).fill()
  }
}
