import SwiftUI

struct IntervalControlView: View {
  let intervalTitle: String
  let canDecrease: Bool
  let canIncrease: Bool
  let decreaseAction: () -> Void
  let increaseAction: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      IntervalStepButton(
        systemName: "minus",
        isEnabled: canDecrease,
        help: "Sample more often",
        action: decreaseAction
      )

      Text(intervalTitle)
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(width: 42)
        .animation(.snappy(duration: 0.18), value: intervalTitle)

      IntervalStepButton(
        systemName: "plus",
        isEnabled: canIncrease,
        help: "Sample less often",
        action: increaseAction
      )
    }
    .padding(.horizontal, 4)
    .padding(.vertical, 2)
    .background(.quaternary.opacity(0.45), in: .capsule)
  }
}
