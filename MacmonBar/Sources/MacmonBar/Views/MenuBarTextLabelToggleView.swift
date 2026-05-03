import SwiftUI

struct MenuBarTextLabelToggleView: View {
  let isOn: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 7) {
        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
          .font(.caption.weight(.semibold))
          .foregroundStyle(foregroundStyle)
          .accessibilityHidden(true)

        Text("Show metric labels")
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundStyle(foregroundStyle)

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
      .padding(.horizontal, 9)
      .background(backgroundStyle, in: .rect(cornerRadius: 7))
    }
    .buttonStyle(.plain)
    .help("Show labels such as PWR, P, and E")
  }

  private var backgroundStyle: Color {
    isOn ? Color.green : Color.secondary.opacity(0.14)
  }

  private var foregroundStyle: Color {
    isOn ? .white : .secondary
  }
}
