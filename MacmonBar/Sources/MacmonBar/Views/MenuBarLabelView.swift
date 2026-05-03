import SwiftUI

struct MenuBarLabelView: View {
  let snapshot: MetricSnapshot?
  let history: [MetricSnapshot]
  let status: MonitorStatus
  let style: MenuBarDisplayStyle
  let metrics: [MenuBarMetric]
  let revision: Int

  var body: some View {
    MenuBarStylePreviewView(
      snapshot: snapshot,
      history: history,
      status: status,
      style: style,
      metrics: metrics,
      isPreview: false
    )
    .id(revision)
  }
}
