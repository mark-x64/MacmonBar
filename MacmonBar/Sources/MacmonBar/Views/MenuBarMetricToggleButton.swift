import SwiftUI

struct MenuBarMetricToggleButton: View {
  let metric: MenuBarMetric
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        .font(.caption2)
        .foregroundStyle(isSelected ? .green : .secondary)
        .accessibilityHidden(true)

      Text(metric.title)
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.75)

      Spacer(minLength: 4)

      reorderIndicator
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 5)
    .padding(.horizontal, 6)
    .background(isSelected ? Color.green.opacity(0.16) : Color.primary.opacity(0.06), in: .capsule)
    .contentShape(.capsule)
    .onTapGesture(perform: action)
    .help(metric.title)
  }

  private var reorderIndicator: some View {
    VStack(alignment: .trailing, spacing: 2) {
      ForEach(0..<3, id: \.self) { index in
        Capsule()
          .fill(Color.primary.opacity(0.18 - Double(index) * 0.025))
          .frame(width: 10, height: 1.4)
      }
    }
    .frame(width: 12)
    .accessibilityHidden(true)
  }
}
