import AppKit
import Foundation

enum MenuBarTextImageRenderer {
  static func image(
    snapshot: MetricSnapshot,
    metrics: [MenuBarMetric],
    showsLabels: Bool,
    height: CGFloat = 18,
    spacing: CGFloat = 5
  ) -> NSImage {
    let items = metrics.map { item(for: $0, snapshot: snapshot, showsLabels: showsLabels) }
    let width = ceil(items.map(\.size.width).reduce(0, +) + spacing * CGFloat(max(items.count - 1, 0)))
    let imageSize = NSSize(width: max(width, 1), height: height)

    let image = NSImage(size: imageSize, flipped: true) { _ in
      var x: CGFloat = 0
      for item in items {
        item.draw(atX: x, height: height)
        x += item.size.width + spacing
      }
      return true
    }
    image.isTemplate = false
    return image
  }

  private static func item(
    for metric: MenuBarMetric,
    snapshot: MetricSnapshot,
    showsLabels: Bool
  ) -> RenderItem {
    if metric == .network {
      return .network(
        upload: "↑ \(MetricText.bytesPerSecond(snapshot.network.uploadBytesPerSecond))",
        download: "↓ \(MetricText.bytesPerSecond(snapshot.network.downloadBytesPerSecond))"
      )
    }

    return .singleLine(metric.compactText(for: snapshot, includeLabel: showsLabels))
  }
}

private enum RenderItem {
  case singleLine(String)
  case network(upload: String, download: String)

  private var mainAttributes: [NSAttributedString.Key: Any] {
    [
      .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
      .foregroundColor: NSColor.white,
    ]
  }

  private var networkAttributes: [NSAttributedString.Key: Any] {
    [
      .font: NSFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .medium),
      .foregroundColor: NSColor.white,
    ]
  }

  var size: CGSize {
    switch self {
    case .singleLine(let text):
      text.size(withAttributes: mainAttributes)
    case .network(let upload, let download):
      CGSize(
        width: ceil(max(
          upload.size(withAttributes: networkAttributes).width,
          download.size(withAttributes: networkAttributes).width
        )),
        height: 18
      )
    }
  }

  func draw(atX x: CGFloat, height: CGFloat) {
    switch self {
    case .singleLine(let text):
      let textSize = text.size(withAttributes: mainAttributes)
      text.draw(at: CGPoint(x: x, y: floor((height - textSize.height) / 2)), withAttributes: mainAttributes)
    case .network(let upload, let download):
      upload.draw(at: CGPoint(x: x, y: -1), withAttributes: networkAttributes)
      download.draw(at: CGPoint(x: x, y: 8), withAttributes: networkAttributes)
    }
  }
}
