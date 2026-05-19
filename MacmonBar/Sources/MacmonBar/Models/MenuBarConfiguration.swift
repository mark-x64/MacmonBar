import Foundation

enum MenuBarMetric: String, CaseIterable, Identifiable, Sendable {
  case cpuTotal
  case pCPU
  case eCPU
  case gpu
  case memory
  case network
  case power
  case cpuPower
  case gpuPower

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .cpuTotal:
      return "CPU Total"
    case .pCPU:
      return "P-CPU"
    case .eCPU:
      return "E-CPU"
    case .gpu:
      return "GPU"
    case .memory:
      return "Memory"
    case .network:
      return "Network"
    case .power:
      return "Power"
    case .cpuPower:
      return "CPU Power"
    case .gpuPower:
      return "GPU Power"
    }
  }

  var shortTitle: String {
    switch self {
    case .cpuTotal:
      return "CPU"
    case .pCPU:
      return "P"
    case .eCPU:
      return "E"
    case .gpu:
      return "GPU"
    case .memory:
      return "MEM"
    case .network:
      return "NET"
    case .power:
      return "PWR"
    case .cpuPower:
      return "CPU W"
    case .gpuPower:
      return "GPU W"
    }
  }

  static let defaultMenuBarOrder: [MenuBarMetric] = [
    .cpuTotal,
    .pCPU,
    .eCPU,
    .gpu,
    .memory,
    .network,
    .power,
    .cpuPower,
    .gpuPower,
  ]

  static func normalizedMenuBarOrder(_ metrics: [MenuBarMetric]) -> [MenuBarMetric] {
    var seen = Set<MenuBarMetric>()
    var orderedMetrics = metrics.filter { seen.insert($0).inserted }
    orderedMetrics.append(contentsOf: defaultMenuBarOrder.filter { seen.insert($0).inserted })

    return orderedMetrics
  }

  static func orderedMenuBarSelection(
    _ metrics: [MenuBarMetric],
    order: [MenuBarMetric]
  ) -> [MenuBarMetric] {
    let selectedMetrics = Set(metrics)

    return normalizedMenuBarOrder(order).filter { selectedMetrics.contains($0) }
  }
}
