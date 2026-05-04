import CoreGraphics

enum SparklineLayout {
  static let visibleSampleCapacity = 90

  static func xPosition(index: Int, visibleSampleCount: Int, width: CGFloat) -> CGFloat {
    guard visibleSampleCount > 0 else {
      return width
    }

    guard visibleSampleCapacity > 1 else {
      return width
    }

    let sampleCount = min(visibleSampleCount, visibleSampleCapacity)
    let step = width / CGFloat(visibleSampleCapacity - 1)
    let leadingEmptySlots = visibleSampleCapacity - sampleCount

    return step * CGFloat(leadingEmptySlots + index)
  }
}
