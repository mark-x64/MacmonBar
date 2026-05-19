import SwiftUI

struct MenuBarLabelView: View {
  let snapshot: MetricSnapshot?
  let history: [MetricSnapshot]
  let status: MonitorStatus
  let showsText: Bool
  let showsGraph: Bool
  let showsTextLabels: Bool
  let metrics: [MenuBarMetric]
  let isPanelOpen: Bool

  @State private var reservedImageWidth: CGFloat?

  private let openPanelWidthBuffer: CGFloat = 18

  var body: some View {
    HStack(spacing: 5) {
      if !showsText && !showsGraph {
        Image(systemName: status.symbolName)
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(status.tint)
          .accessibilityHidden(true)
      }

      if showsText || showsGraph {
        let image = MenuBarLabelImageRenderer.image(
          snapshot: snapshot,
          history: history,
          metrics: metrics,
          showsText: showsText,
          showsGraph: showsGraph,
          showsLabels: showsTextLabels
        )

        Image(
          nsImage: image
        )
          .interpolation(.high)
          .frame(width: frameWidth(for: image.size.width), height: image.size.height)
          .accessibilityLabel(accessibilityLabel)
          .onAppear {
            updateReservedWidth(currentWidth: image.size.width)
          }
          .onChange(of: image.size.width) { _, width in
            updateReservedWidth(currentWidth: width)
          }
          .onChange(of: isPanelOpen) { _, _ in
            updateReservedWidth(currentWidth: image.size.width)
          }
      }
    }
  }

  private var accessibilityLabel: String {
    guard let snapshot else {
      return "Macmon"
    }

    var parts: [String] = []
    if showsText {
      parts.append(metrics.compactText(for: snapshot, includeLabels: showsTextLabels))
    }
    if showsGraph {
      parts.append("graph")
    }
    return parts.joined(separator: ", ")
  }

  private func frameWidth(for currentWidth: CGFloat) -> CGFloat? {
    guard isPanelOpen else {
      return nil
    }

    return max(reservedImageWidth ?? 0, ceil(currentWidth + openPanelWidthBuffer))
  }

  private func updateReservedWidth(currentWidth: CGFloat) {
    guard isPanelOpen else {
      reservedImageWidth = nil
      return
    }

    reservedImageWidth = max(reservedImageWidth ?? 0, ceil(currentWidth + openPanelWidthBuffer))
  }
}
