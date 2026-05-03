import Foundation

extension MenuBarMetric {
  func compactText(for snapshot: MetricSnapshot, includeLabel: Bool = true) -> String {
    let value = switch self {
    case .cpuTotal:
      MetricText.compactPercent(snapshot.cpuUsageRatio)
    case .pCPU:
      MetricText.compactPercent(snapshot.pcpuUsage.utilizationRatio)
    case .eCPU:
      MetricText.compactPercent(snapshot.ecpuUsage.utilizationRatio)
    case .gpu:
      MetricText.compactPercent(snapshot.gpuUsage.utilizationRatio)
    case .memory:
      MetricText.compactPercent(snapshot.memory.ramUsageRatio)
    case .power:
      MetricText.compactWatts(snapshot.sysPower)
    case .cpuPower:
      MetricText.compactWatts(snapshot.cpuPower)
    case .gpuPower:
      MetricText.compactWatts(snapshot.gpuPower)
    }

    return includeLabel ? "\(shortTitle) \(value)" : value
  }

  func rawValue(from snapshot: MetricSnapshot) -> Double {
    switch self {
    case .cpuTotal:
      return snapshot.cpuUsageRatio
    case .pCPU:
      return snapshot.pcpuUsage.utilizationRatio
    case .eCPU:
      return snapshot.ecpuUsage.utilizationRatio
    case .gpu:
      return snapshot.gpuUsage.utilizationRatio
    case .memory:
      return snapshot.memory.ramUsageRatio
    case .power:
      return snapshot.sysPower
    case .cpuPower:
      return snapshot.cpuPower
    case .gpuPower:
      return snapshot.gpuPower
    }
  }

  func normalizedValues(from history: [MetricSnapshot]) -> [Double] {
    let values = history.map(rawValue(from:))

    switch self {
    case .cpuTotal, .pCPU, .eCPU, .gpu, .memory:
      return values.map { min(max($0, 0), 1) }
    case .power, .cpuPower, .gpuPower:
      let upperBound = max(values.max() ?? 0, 1)
      return values.map { min(max($0 / upperBound, 0), 1) }
    }
  }
}

extension Array where Element == MenuBarMetric {
  func compactText(for snapshot: MetricSnapshot, includeLabels: Bool = true) -> String {
    map { $0.compactText(for: snapshot, includeLabel: includeLabels) }
      .joined(separator: "  ")
  }
}
