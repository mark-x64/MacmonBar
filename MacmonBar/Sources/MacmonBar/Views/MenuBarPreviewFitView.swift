import SwiftUI

enum MenuBarPreviewLayout {
  static let maxWidth = CGFloat.greatestFiniteMagnitude
  static let minimumHeight: CGFloat = 34
}

struct MenuBarPreviewFitView<Content: View>: View {
  let maxWidth: CGFloat
  private let content: Content
  @State private var contentSize: CGSize = .zero

  init(
    maxWidth: CGFloat = MenuBarPreviewLayout.maxWidth,
    @ViewBuilder content: () -> Content
  ) {
    self.maxWidth = maxWidth
    self.content = content()
  }

  var body: some View {
    GeometryReader { proxy in
      let targetWidth = min(maxWidth, proxy.size.width)
      let scale = scale(for: targetWidth)

      ZStack {
        content
          .fixedSize()
          .hidden()
          .background(MenuBarPreviewSizeReader())

        content
          .fixedSize()
          .scaleEffect(scale, anchor: .center)
          .frame(width: measuredWidth * scale, height: measuredHeight * scale)
      }
      .frame(width: targetWidth, height: previewHeight(for: targetWidth), alignment: .center)
      .clipped()
      .frame(maxWidth: .infinity, alignment: .center)
    }
    .frame(height: previewHeight(for: maxWidth))
    .frame(maxWidth: maxWidth)
    .clipped()
    .onPreferenceChange(MenuBarPreviewSizePreferenceKey.self) { size in
      guard size != contentSize else {
        return
      }

      contentSize = size
    }
  }

  private var measuredWidth: CGFloat {
    max(contentSize.width, 1)
  }

  private var measuredHeight: CGFloat {
    max(contentSize.height, MenuBarPreviewLayout.minimumHeight)
  }

  private func scale(for targetWidth: CGFloat) -> CGFloat {
    guard contentSize.width > 0 else {
      return 1
    }

    return min(1, targetWidth / contentSize.width)
  }

  private func previewHeight(for targetWidth: CGFloat) -> CGFloat {
    max(
      MenuBarPreviewLayout.minimumHeight,
      measuredHeight * scale(for: targetWidth)
    )
  }
}

private struct MenuBarPreviewSizeReader: View {
  var body: some View {
    GeometryReader { proxy in
      Color.clear.preference(
        key: MenuBarPreviewSizePreferenceKey.self,
        value: proxy.size
      )
    }
  }
}

private struct MenuBarPreviewSizePreferenceKey: PreferenceKey {
  static let defaultValue: CGSize = .zero

  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    value = nextValue()
  }
}

#Preview("Fits Wide Content") {
  MenuBarPreviewFitView(maxWidth: 240) {
    Text("PWR 21.0W  CPU 20%  P 13%  E 36%  GPU 10%  MEM 50%")
      .font(.system(size: 18, weight: .semibold, design: .rounded))
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(Color.primary.opacity(0.09), in: .capsule)
  }
  .padding()
}
