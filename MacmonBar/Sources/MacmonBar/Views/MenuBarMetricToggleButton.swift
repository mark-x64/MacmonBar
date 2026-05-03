import SwiftUI

struct MenuBarMetricToggleButton: View {
  let metric: MenuBarMetric
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.caption2)
          .foregroundStyle(isSelected ? .green : .secondary)
          .accessibilityHidden(true)

        Text(metric.title)
          .font(.caption2)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 5)
      .padding(.horizontal, 6)
      .background(isSelected ? Color.green.opacity(0.16) : Color.primary.opacity(0.06), in: .capsule)
    }
    .buttonStyle(.plain)
    .help(metric.title)
  }
}
