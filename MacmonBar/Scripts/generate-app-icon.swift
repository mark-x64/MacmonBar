#!/usr/bin/env swift

import AppKit
import Foundation

let scriptURL = URL(fileURLWithPath: #filePath)
let rootURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let resourcesURL = rootURL.appending(path: "Resources", directoryHint: .isDirectory)
let iconsetURL = resourcesURL.appending(path: "AppIcon.iconset", directoryHint: .isDirectory)

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let outputs: [(name: String, size: Int)] = [
  ("icon_16x16.png", 16),
  ("icon_16x16@2x.png", 32),
  ("icon_32x32.png", 32),
  ("icon_32x32@2x.png", 64),
  ("icon_128x128.png", 128),
  ("icon_128x128@2x.png", 256),
  ("icon_256x256.png", 256),
  ("icon_256x256@2x.png", 512),
  ("icon_512x512.png", 512),
  ("icon_512x512@2x.png", 1024),
]

for output in outputs {
  let image = drawIcon(size: output.size)
  let outputURL = iconsetURL.appending(path: output.name)
  try writePNG(image, to: outputURL)
}

try writeICNS(
  to: resourcesURL.appending(path: "AppIcon.icns"),
  entries: [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png"),
    ("ic11", "icon_16x16@2x.png"),
    ("ic12", "icon_32x32@2x.png"),
    ("ic13", "icon_128x128@2x.png"),
    ("ic14", "icon_256x256@2x.png"),
  ]
)

func drawIcon(size: Int) -> NSImage {
  let scale = CGFloat(size) / 1024
  let canvasSize = CGSize(width: size, height: size)
  let image = NSImage(size: canvasSize)

  image.lockFocus()
  defer { image.unlockFocus() }

  NSColor.clear.setFill()
  CGRect(origin: .zero, size: canvasSize).fill()

  func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x * scale, y: y * scale, width: width * scale, height: height * scale)
  }

  let outerRect = rect(96, 96, 832, 832)
  let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: 196 * scale, yRadius: 196 * scale)
  NSColor(red: 0.025, green: 0.027, blue: 0.03, alpha: 1).setFill()
  outerPath.fill()

  let borderPath = NSBezierPath(roundedRect: outerRect.insetBy(dx: 10 * scale, dy: 10 * scale), xRadius: 184 * scale, yRadius: 184 * scale)
  NSColor.white.withAlphaComponent(0.12).setStroke()
  borderPath.lineWidth = max(1, 8 * scale)
  borderPath.stroke()

  let panelRect = rect(176, 236, 672, 552)
  let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 104 * scale, yRadius: 104 * scale)
  NSColor(red: 0.075, green: 0.078, blue: 0.082, alpha: 1).setFill()
  panelPath.fill()

  drawGrid(in: panelRect, scale: scale)
  drawSparkline(
    points: [
      CGPoint(x: 220, y: 552), CGPoint(x: 282, y: 540), CGPoint(x: 334, y: 560),
      CGPoint(x: 382, y: 500), CGPoint(x: 432, y: 622), CGPoint(x: 490, y: 420),
      CGPoint(x: 552, y: 604), CGPoint(x: 618, y: 490), CGPoint(x: 700, y: 532),
      CGPoint(x: 800, y: 492),
    ],
    color: NSColor.systemGreen,
    lineWidth: 34 * scale,
    scale: scale
  )

  drawSparkline(
    points: [
      CGPoint(x: 224, y: 664), CGPoint(x: 312, y: 686), CGPoint(x: 402, y: 672),
      CGPoint(x: 492, y: 698), CGPoint(x: 590, y: 646), CGPoint(x: 704, y: 674),
      CGPoint(x: 798, y: 650),
    ],
    color: NSColor.systemCyan.withAlphaComponent(0.88),
    lineWidth: 20 * scale,
    scale: scale
  )

  drawStatusDots(scale: scale)

  return image
}

func drawGrid(in rect: CGRect, scale: CGFloat) {
  NSColor.white.withAlphaComponent(0.09).setStroke()

  for y in [348, 512, 676] as [CGFloat] {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + 52 * scale, y: y * scale))
    path.line(to: CGPoint(x: rect.maxX - 52 * scale, y: y * scale))
    path.lineWidth = max(1, 5 * scale)
    path.lineCapStyle = .round
    path.stroke()
  }
}

func drawSparkline(points: [CGPoint], color: NSColor, lineWidth: CGFloat, scale: CGFloat) {
  let path = NSBezierPath()
  path.lineCapStyle = .round
  path.lineJoinStyle = .round

  for (index, point) in points.enumerated() {
    let scaledPoint = CGPoint(x: point.x * scale, y: point.y * scale)

    if index == 0 {
      path.move(to: scaledPoint)
    } else {
      path.line(to: scaledPoint)
    }
  }

  color.setStroke()
  path.lineWidth = max(1, lineWidth)
  path.stroke()
}

func drawStatusDots(scale: CGFloat) {
  let dots: [(NSColor, CGRect)] = [
    (.systemGreen, CGRect(x: 256, y: 276, width: 42, height: 42)),
    (.systemPurple, CGRect(x: 330, y: 276, width: 42, height: 42)),
    (.systemBlue, CGRect(x: 404, y: 276, width: 42, height: 42)),
  ]

  for (color, rect) in dots {
    let scaledRect = CGRect(
      x: rect.minX * scale,
      y: rect.minY * scale,
      width: rect.width * scale,
      height: rect.height * scale
    )
    color.withAlphaComponent(0.94).setFill()
    NSBezierPath(ovalIn: scaledRect).fill()
  }
}

func writePNG(_ image: NSImage, to url: URL) throws {
  guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
  else {
    throw CocoaError(.fileWriteUnknown)
  }

  try png.write(to: url)
}

func writeICNS(to url: URL, entries: [(type: String, fileName: String)]) throws {
  var chunks = Data()

  for entry in entries {
    let pngURL = iconsetURL.appending(path: entry.fileName)
    let pngData = try Data(contentsOf: pngURL)

    appendOSType(entry.type, to: &chunks)
    appendUInt32BE(UInt32(pngData.count + 8), to: &chunks)
    chunks.append(pngData)
  }

  var output = Data()
  appendOSType("icns", to: &output)
  appendUInt32BE(UInt32(chunks.count + 8), to: &output)
  output.append(chunks)
  try output.write(to: url)
}

func appendOSType(_ value: String, to data: inout Data) {
  precondition(value.utf8.count == 4)
  data.append(contentsOf: value.utf8)
}

func appendUInt32BE(_ value: UInt32, to data: inout Data) {
  data.append(UInt8((value >> 24) & 0xff))
  data.append(UInt8((value >> 16) & 0xff))
  data.append(UInt8((value >> 8) & 0xff))
  data.append(UInt8(value & 0xff))
}
