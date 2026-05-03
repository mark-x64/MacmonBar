import SwiftUI

struct EmptyMonitorView: View {
  let status: MonitorStatus

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Image(systemName: status.symbolName)
        .font(.largeTitle)
        .foregroundStyle(status.tint)
        .symbolRenderingMode(.hierarchical)
        .accessibilityHidden(true)

      Text(status.title)
        .font(.headline)

      Text(status.message)
        .font(.caption)
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.quaternary.opacity(0.55), in: .rect(cornerRadius: 8))
  }
}
