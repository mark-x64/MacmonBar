import SwiftUI

struct MenuBarPresentationPreviewCard<Preview: View>: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  private let preview: Preview

  init(
    title: String,
    isSelected: Bool,
    action: @escaping () -> Void,
    @ViewBuilder preview: () -> Preview
  ) {
    self.title = title
    self.isSelected = isSelected
    self.action = action
    self.preview = preview()
  }

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .green : .secondary)
            .accessibilityHidden(true)

          Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)

          Spacer()
        }

        Spacer(minLength: 0)

        MenuBarPreviewFitView {
          preview
        }
          .frame(maxWidth: .infinity, alignment: .center)

        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
      .padding(10)
      .background(backgroundStyle, in: .rect(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(borderStyle, lineWidth: isSelected ? 1.2 : 1)
      }
    }
    .buttonStyle(.plain)
    .help(title)
  }

  private var backgroundStyle: Color {
    isSelected ? Color.green.opacity(0.14) : Color.primary.opacity(0.06)
  }

  private var borderStyle: Color {
    isSelected ? Color.green.opacity(0.65) : Color.secondary.opacity(0.16)
  }
}
