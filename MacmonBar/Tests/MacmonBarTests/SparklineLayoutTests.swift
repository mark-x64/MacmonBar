import CoreGraphics
import Testing
@testable import MacmonBar

@Test
func partialSparklineHistoryUsesTrailingSampleSlots() {
  let width: CGFloat = 89

  #expect(SparklineLayout.xPosition(index: 0, visibleSampleCount: 2, width: width) == 88)
  #expect(SparklineLayout.xPosition(index: 1, visibleSampleCount: 2, width: width) == 89)
}

@Test
func fullSparklineHistorySpansAvailableWidth() {
  let width: CGFloat = 89

  #expect(SparklineLayout.xPosition(index: 0, visibleSampleCount: 90, width: width) == 0)
  #expect(SparklineLayout.xPosition(index: 89, visibleSampleCount: 90, width: width) == 89)
}
