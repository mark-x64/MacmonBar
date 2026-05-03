import SwiftUI

struct MenuBarTextPreviewView: View {
  let snapshot: MetricSnapshot?
  let metrics: [MenuBarMetric]
  let showsLabels: Bool

  var body: some View {
    Text(labelText)
      .font(.system(size: 18, weight: .semibold, design: .rounded))
      .monospacedDigit()
      .lineLimit(1)
      .minimumScaleFactor(0.55)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.primary.opacity(0.09), in: .capsule)
  }

  private var labelText: String {
    guard let snapshot else {
      return "Macmon"
    }

    return metrics.compactText(for: snapshot, includeLabels: showsLabels)
  }
}
