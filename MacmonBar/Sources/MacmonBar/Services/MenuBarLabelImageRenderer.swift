import AppKit
import Foundation

enum MenuBarLabelImageRenderer {
  private static let height: CGFloat = 18
  private static let spacing: CGFloat = 5
  private static let graphSize = CGSize(width: 46, height: 16)

  static func image(
    snapshot: MetricSnapshot?,
    history: [MetricSnapshot],
    metrics: [MenuBarMetric],
    showsText: Bool,
    showsGraph: Bool,
    showsLabels: Bool
  ) -> NSImage {
    let textImage = showsText ? textImage(snapshot: snapshot, metrics: metrics, showsLabels: showsLabels) : nil
    let graphImage = showsGraph
      ? MenuBarGraphRenderer.image(snapshot: snapshot, history: history, metrics: metrics, size: graphSize)
      : nil
    let width = ceil(
      (textImage?.size.width ?? 0)
        + (textImage != nil && graphImage != nil ? spacing : 0)
        + (graphImage?.size.width ?? 0)
    )
    let size = CGSize(width: max(width, 1), height: height)

    let image = NSImage(size: size, flipped: true) { _ in
      var x: CGFloat = 0

      if let textImage {
        textImage.draw(in: CGRect(origin: CGPoint(x: x, y: 0), size: textImage.size))
        x += textImage.size.width + (graphImage == nil ? 0 : spacing)
      }

      if let graphImage {
        graphImage.draw(
          in: CGRect(
            x: x,
            y: floor((height - graphSize.height) / 2),
            width: graphSize.width,
            height: graphSize.height
          )
        )
      }

      return true
    }
    image.isTemplate = false
    return image
  }

  private static func textImage(
    snapshot: MetricSnapshot?,
    metrics: [MenuBarMetric],
    showsLabels: Bool
  ) -> NSImage {
    guard let snapshot else {
      return fallbackTextImage("Macmon")
    }

    return MenuBarTextImageRenderer.image(
      snapshot: snapshot,
      metrics: metrics,
      showsLabels: showsLabels,
      height: height,
      spacing: spacing
    )
  }

  private static func fallbackTextImage(_ text: String) -> NSImage {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
      .foregroundColor: NSColor.white,
    ]
    let textSize = text.size(withAttributes: attributes)
    let size = CGSize(width: ceil(textSize.width), height: height)

    let image = NSImage(size: size, flipped: true) { _ in
      text.draw(at: CGPoint(x: 0, y: floor((height - textSize.height) / 2)), withAttributes: attributes)
      return true
    }
    image.isTemplate = false
    return image
  }
}
