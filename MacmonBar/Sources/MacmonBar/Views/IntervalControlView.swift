import SwiftUI

struct IntervalControlView: View {
  let intervalTitle: String
  let canDecrease: Bool
  let canIncrease: Bool
  let decreaseAction: () -> Void
  let increaseAction: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      Button(action: decreaseAction) {
        Label("Decrease sampling interval", systemImage: "minus")
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.borderless)
      .disabled(!canDecrease)
      .help("Sample more often")

      Text(intervalTitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .frame(width: 36)

      Button(action: increaseAction) {
        Label("Increase sampling interval", systemImage: "plus")
          .labelStyle(.iconOnly)
      }
      .buttonStyle(.borderless)
      .disabled(!canIncrease)
      .help("Sample less often")
    }
    .padding(.horizontal, 6)
    .padding(.vertical, 4)
    .background(.quaternary.opacity(0.45), in: .capsule)
  }
}
