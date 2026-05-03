import SwiftUI

struct MenuBarSettingsBlockView: View {
  @Bindable var store: MonitorStore

  private let columns = [
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline) {
        Text("Menu Bar")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Spacer()

        Picker("Style", selection: $store.menuBarDisplayStyle) {
          ForEach(MenuBarDisplayStyle.allCases) { style in
            Text(style.title).tag(style)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 210)
      }

      HStack {
        MenuBarStylePreviewView(
          snapshot: store.snapshot,
          history: store.history,
          status: store.status,
          style: store.menuBarDisplayStyle,
          metrics: store.selectedMenuBarMetrics,
          isPreview: true
        )

        Spacer(minLength: 10)
      }

      LazyVGrid(columns: columns, spacing: 6) {
        ForEach(MenuBarMetric.allCases) { metric in
          MenuBarMetricToggleButton(
            metric: metric,
            isSelected: store.isMenuBarMetricSelected(metric),
            action: { store.toggleMenuBarMetric(metric) }
          )
        }
      }
    }
    .padding(10)
    .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
  }
}
