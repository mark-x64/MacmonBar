import AppKit
import SwiftUI

struct IntervalStepButton: View {
  let systemName: String
  let isEnabled: Bool
  let help: String
  let action: () -> Void

  @State private var isPulsing = false
  @State private var pulseToken = 0

  var body: some View {
    Button(action: trigger) {
      Image(systemName: systemName)
        .font(.caption.weight(.semibold))
        .foregroundStyle(isPulsing ? .white : .primary)
        .frame(width: 28, height: 28)
        .background(backgroundStyle, in: .circle)
        .scaleEffect(isPulsing ? 0.88 : 1)
        .contentShape(.circle)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1 : 0.35)
    .help(help)
    .animation(.snappy(duration: 0.12), value: isPulsing)
  }

  private var backgroundStyle: Color {
    isPulsing ? .accentColor : Color.primary.opacity(isEnabled ? 0.08 : 0)
  }

  private func trigger() {
    guard isEnabled else {
      return
    }

    pulse()
    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    action()
  }

  private func pulse() {
    pulseToken += 1
    let token = pulseToken

    withAnimation(.snappy(duration: 0.08)) {
      isPulsing = true
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(140))

      guard pulseToken == token else {
        return
      }

      withAnimation(.snappy(duration: 0.16)) {
        isPulsing = false
      }
    }
  }
}
