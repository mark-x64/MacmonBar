import SwiftUI

enum MonitorStatus: Equatable, Sendable {
  case starting
  case live
  case stopped
  case unavailable(String)

  var title: String {
    switch self {
    case .starting:
      return "Starting"
    case .live:
      return "Live"
    case .stopped:
      return "Stopped"
    case .unavailable:
      return "Unavailable"
    }
  }

  var message: String {
    switch self {
    case .starting:
      return "Starting macmon sampler..."
    case .live:
      return "Sampling every second"
    case .stopped:
      return "Sampling paused"
    case .unavailable(let message):
      return message
    }
  }

  var symbolName: String {
    switch self {
    case .starting:
      return "hourglass"
    case .live:
      return "waveform.path.ecg"
    case .stopped:
      return "pause.circle"
    case .unavailable:
      return "exclamationmark.triangle.fill"
    }
  }

  var tint: Color {
    switch self {
    case .starting:
      return .secondary
    case .live:
      return .green
    case .stopped:
      return .orange
    case .unavailable:
      return .red
    }
  }
}
