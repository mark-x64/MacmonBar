import SwiftUI

struct MenuBarSettingsView: View {
  @Bindable var store: MonitorStore
  @State private var dragState: MenuBarMetricDragState?
  @State private var metricFrames: [String: CGRect] = [:]

  fileprivate static let metricGridCoordinateSpace = "MenuBarMetricGrid"

  private let metricColumns = [
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
    GridItem(.flexible(), spacing: 6),
  ]

  private let previewColumns = [
    GridItem(.flexible(), spacing: 8),
    GridItem(.flexible(), spacing: 8),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Menu Bar")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        LazyVGrid(columns: previewColumns, spacing: 8) {
          MenuBarTextPresentationCard(store: store)

          MenuBarPresentationPreviewCard(
            title: MenuBarPresentationKind.graph.title,
            isSelected: store.isMenuBarPresentationSelected(.graph),
            action: { store.toggleMenuBarPresentation(.graph) }
          ) {
            MenuBarGraphPreviewView(
              snapshot: store.snapshot,
              history: store.history,
              metrics: store.selectedMenuBarMetrics
            )
          }
        }
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("Data")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        metricGrid
      }
      .padding(10)
      .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 8) {
        Text("Dashboard")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)

        Toggle(isOn: $store.showsProcessPowerRanking) {
          Text("Process power ranking")
            .font(.caption)
            .fontWeight(.semibold)
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .help("Rank process power while the panel is open")
      }
      .padding(10)
      .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 8))
    }
  }

  private var metricGrid: some View {
    ZStack(alignment: .topLeading) {
      LazyVGrid(columns: metricColumns, spacing: 6) {
        ForEach(metricSlots) { slot in
          metricSlotView(slot)
            .background(MenuBarMetricFrameReader(slotID: slot.id))
        }
      }
      .animation(.bouncy, value: dragState?.targetIndex)

      draggedMetricOverlay
    }
    .coordinateSpace(name: Self.metricGridCoordinateSpace)
    .onPreferenceChange(MenuBarMetricFramePreferenceKey.self) { frames in
      metricFrames = frames
    }
  }

  private var metricSlots: [MenuBarMetricGridSlot] {
    guard let dragState else {
      return store.menuBarMetricOrder.map(MenuBarMetricGridSlot.metric)
    }

    var slots = store.menuBarMetricOrder
      .filter { $0 != dragState.metric }
      .map(MenuBarMetricGridSlot.metric)
    let targetIndex = clamped(dragState.targetIndex, lower: 0, upper: slots.count)
    slots.insert(.placeholder(dragState.metric), at: targetIndex)

    return slots
  }

  @ViewBuilder
  private func metricSlotView(_ slot: MenuBarMetricGridSlot) -> some View {
    switch slot {
    case .metric(let metric):
      MenuBarMetricToggleButton(
        metric: metric,
        isSelected: store.isMenuBarMetricSelected(metric),
        action: { store.toggleMenuBarMetric(metric) }
      )
      .highPriorityGesture(dragGesture(for: metric))
    case .placeholder:
      MenuBarMetricPlaceholderView()
    }
  }

  @ViewBuilder
  private var draggedMetricOverlay: some View {
    if let dragState {
      MenuBarMetricToggleButton(
        metric: dragState.metric,
        isSelected: store.isMenuBarMetricSelected(dragState.metric),
        action: {}
      )
      .frame(width: dragState.startFrame.width, height: dragState.startFrame.height)
      .position(
        x: dragState.startFrame.midX + dragState.translation.width,
        y: dragState.startFrame.midY + dragState.translation.height
      )
      .opacity(0.96)
      .allowsHitTesting(false)
      .zIndex(1)
    }
  }

  private func dragGesture(for metric: MenuBarMetric) -> some Gesture {
    DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.metricGridCoordinateSpace))
      .onChanged { value in
        let frame = metricFrames[MenuBarMetricGridSlot.metric(metric).id] ?? .zero
        let sourceIndex = store.menuBarMetricOrder.firstIndex(of: metric) ?? 0
        var nextState = dragState ?? MenuBarMetricDragState(
          metric: metric,
          targetIndex: sourceIndex,
          startFrame: frame,
          translation: .zero
        )

        guard nextState.metric == metric else {
          return
        }

        nextState.translation = value.translation
        nextState.targetIndex = targetIndex(for: value.location, currentState: nextState)

        withAnimation(.bouncy) {
          dragState = nextState
        }
      }
      .onEnded { _ in
        guard let dragState else {
          return
        }

        withAnimation(.bouncy) {
          store.moveMenuBarMetric(dragState.metric, toIndex: dragState.targetIndex)
          self.dragState = nil
        }
      }
  }

  private func targetIndex(
    for location: CGPoint,
    currentState: MenuBarMetricDragState
  ) -> Int {
    let maxIndex = max(store.menuBarMetricOrder.count - 1, 0)
    let candidates = metricSlots.enumerated().compactMap { index, slot in
      metricFrames[slot.id].map { frame in
        (index: index, slot: slot, frame: frame)
      }
    }

    guard !candidates.isEmpty else {
      return currentState.targetIndex
    }

    if let hit = candidates.first(where: { $0.frame.contains(location) }) {
      return targetIndex(for: hit.index, slot: hit.slot, frame: hit.frame, location: location, maxIndex: maxIndex)
    }

    let nearest = candidates.min { first, second in
      distanceSquared(from: location, to: first.frame.center) < distanceSquared(from: location, to: second.frame.center)
    }

    guard let nearest else {
      return currentState.targetIndex
    }

    return clamped(nearest.index, lower: 0, upper: maxIndex)
  }

  private func targetIndex(
    for index: Int,
    slot: MenuBarMetricGridSlot,
    frame: CGRect,
    location: CGPoint,
    maxIndex: Int
  ) -> Int {
    guard !slot.isPlaceholder else {
      return clamped(index, lower: 0, upper: maxIndex)
    }

    let isAfter = location.y > frame.midY || (abs(location.y - frame.midY) < frame.height / 2 && location.x > frame.midX)
    let proposedIndex = isAfter ? index + 1 : index

    return clamped(proposedIndex, lower: 0, upper: maxIndex)
  }

  private func clamped(_ value: Int, lower: Int, upper: Int) -> Int {
    min(max(value, lower), upper)
  }

  private func distanceSquared(from point: CGPoint, to target: CGPoint) -> CGFloat {
    let x = point.x - target.x
    let y = point.y - target.y

    return x * x + y * y
  }
}

private enum MenuBarMetricGridSlot: Identifiable, Equatable {
  case metric(MenuBarMetric)
  case placeholder(MenuBarMetric)

  var id: String {
    switch self {
    case .metric(let metric):
      return "metric-\(metric.rawValue)"
    case .placeholder(let metric):
      return "placeholder-\(metric.rawValue)"
    }
  }

  var isPlaceholder: Bool {
    if case .placeholder = self {
      return true
    }

    return false
  }
}

private struct MenuBarMetricDragState: Equatable {
  let metric: MenuBarMetric
  var targetIndex: Int
  let startFrame: CGRect
  var translation: CGSize
}

private struct MenuBarMetricPlaceholderView: View {
  var body: some View {
    Capsule()
      .fill(Color.black.opacity(0.34))
      .overlay {
        Capsule()
          .stroke(Color.white.opacity(0.08), lineWidth: 1)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 28)
      .accessibilityHidden(true)
  }
}

private struct MenuBarMetricFrameReader: View {
  let slotID: String

  var body: some View {
    GeometryReader { proxy in
      Color.clear.preference(
        key: MenuBarMetricFramePreferenceKey.self,
        value: [slotID: proxy.frame(in: .named(MenuBarSettingsView.metricGridCoordinateSpace))]
      )
    }
  }
}

private struct MenuBarMetricFramePreferenceKey: PreferenceKey {
  static let defaultValue: [String: CGRect] = [:]

  static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
    value.merge(nextValue(), uniquingKeysWith: { _, next in next })
  }
}

private extension CGRect {
  var center: CGPoint {
    CGPoint(x: midX, y: midY)
  }
}
