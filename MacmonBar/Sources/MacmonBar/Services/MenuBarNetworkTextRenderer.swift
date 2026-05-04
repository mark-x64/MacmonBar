import AppKit
import Foundation

enum MenuBarNetworkTextRenderer {
  static func image(
    uploadBytesPerSecond: Double,
    downloadBytesPerSecond: Double,
    fontSize: CGFloat = 8.5
  ) -> NSImage {
    let uploadText = "↑ \(MetricText.bytesPerSecond(uploadBytesPerSecond))"
    let downloadText = "↓ \(MetricText.bytesPerSecond(downloadBytesPerSecond))"
    let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: NSColor.white,
    ]
    let uploadSize = uploadText.size(withAttributes: attributes)
    let downloadSize = downloadText.size(withAttributes: attributes)
    let width = ceil(max(uploadSize.width, downloadSize.width))
    let height: CGFloat = 18
    let size = NSSize(width: width, height: height)

    let image = NSImage(size: size, flipped: true) { _ in
      uploadText.draw(at: CGPoint(x: 0, y: -1), withAttributes: attributes)
      downloadText.draw(at: CGPoint(x: 0, y: 8), withAttributes: attributes)
      return true
    }
    image.isTemplate = false
    return image
  }
}
