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
        Image(systemName: "minus")
          .font(.caption.weight(.semibold))
          .frame(width: 28, height: 28)
          .contentShape(.circle)
      }
      .buttonStyle(.plain)
      .disabled(!canDecrease)
      .opacity(canDecrease ? 1 : 0.35)
      .help("Sample more often")

      Text(intervalTitle)
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .frame(width: 36)

      Button(action: increaseAction) {
        Image(systemName: "plus")
          .font(.caption.weight(.semibold))
          .frame(width: 28, height: 28)
          .contentShape(.circle)
      }
      .buttonStyle(.plain)
      .disabled(!canIncrease)
      .opacity(canIncrease ? 1 : 0.35)
      .help("Sample less often")
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
    .background(.quaternary.opacity(0.45), in: .capsule)
  }
}
