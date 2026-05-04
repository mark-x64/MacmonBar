import AppKit
import SwiftUI

extension MenuBarMetric {
  var menuBarColor: Color {
    switch self {
    case .cpuTotal:
      return .cyan
    case .pCPU:
      return .blue
    case .eCPU:
      return .green
    case .gpu:
      return .purple
    case .memory:
      return .orange
    case .network:
      return .green
    case .power:
      return .primary
    case .cpuPower:
      return .blue
    case .gpuPower:
      return .purple
    }
  }

  var menuBarNSColor: NSColor {
    switch self {
    case .cpuTotal:
      return .systemCyan
    case .pCPU:
      return .systemBlue
    case .eCPU:
      return .systemGreen
    case .gpu:
      return .systemPurple
    case .memory:
      return .systemOrange
    case .network:
      return .systemGreen
    case .power:
      return .labelColor
    case .cpuPower:
      return .systemBlue
    case .gpuPower:
      return .systemPurple
    }
  }
}
