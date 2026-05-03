import SwiftUI

struct MenuBarTextPresentationCard: View {
  @Bindable var store: MonitorStore

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: { store.toggleMenuBarPresentation(.text) }) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 6) {
            Image(systemName: store.showsMenuBarText ? "checkmark.circle.fill" : "circle")
              .font(.caption.weight(.semibold))
              .foregroundStyle(store.showsMenuBarText ? .green : .secondary)
              .accessibilityHidden(true)

            Text(MenuBarPresentationKind.text.title)
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)

            Spacer()
          }

          MenuBarTextPreviewView(
            snapshot: store.snapshot,
            metrics: store.selectedMenuBarMetrics,
            showsLabels: store.showsMenuBarTextLabels
          )
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
        }
      }
      .buttonStyle(.plain)

      MenuBarTextLabelToggleView(
        isOn: store.showsMenuBarTextLabels,
        action: { store.showsMenuBarTextLabels.toggle() }
      )
    }
    .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
    .padding(10)
    .background(backgroundStyle, in: .rect(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(borderStyle, lineWidth: store.showsMenuBarText ? 1.2 : 1)
    }
  }

  private var backgroundStyle: Color {
    store.showsMenuBarText ? Color.green.opacity(0.14) : Color.primary.opacity(0.06)
  }

  private var borderStyle: Color {
    store.showsMenuBarText ? Color.green.opacity(0.65) : Color.secondary.opacity(0.16)
  }
}
