import SwiftUI

struct MenuBarSettingsView: View {
  @Bindable var store: MonitorStore

  private let metricColumns = [
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
  ]

  private let previewColumns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Menu Bar")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: previewColumns, spacing: 8) {
          MenuBarPresentationPreviewCard(
            title: MenuBarPresentationKind.text.title,
            isSelected: store.isMenuBarPresentationSelected(.text),
            action: { store.toggleMenuBarPresentation(.text) }
          ) {
            MenuBarTextPreviewView(
              snapshot: store.snapshot,
              metrics: store.selectedMenuBarMetrics
            )
          }

          MenuBarPresentationPreviewCard(
            title: MenuBarPresentationKind.graph.title,
            isSelected: store.isMenuBarPresentationSelected(.graph),
            action: { store.toggleMenuBarPresentation(.graph) }
          ) {
            MenuBarGraphPreviewView(
              snapshot: store.snapshot,
              history: store.history,
              metrics: store.selectedMenuBarMetrics
            )
          }
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Data")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: metricColumns, spacing: 6) {
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
}
