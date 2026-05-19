import SwiftUI

struct MenuBarTextPreviewView: View {
  let snapshot: MetricSnapshot?
  let metrics: [MenuBarMetric]
  let showsLabels: Bool

  var body: some View {
    previewContent
      .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.primary.opacity(0.09), in: .capsule)
  }

  @ViewBuilder
  private var previewContent: some View {
    if let snapshot {
      Image(
        nsImage: MenuBarTextImageRenderer.image(
          snapshot: snapshot,
          metrics: metrics,
          showsLabels: showsLabels,
          height: 18,
          spacing: 5
        )
      )
      .resizable()
      .interpolation(.high)
      .scaledToFit()
      .accessibilityLabel(metrics.compactText(for: snapshot, includeLabels: showsLabels))
    } else {
      Text("Macmon")
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
  }
}
