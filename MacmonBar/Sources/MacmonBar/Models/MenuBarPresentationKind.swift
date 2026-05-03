import Foundation

enum MenuBarPresentationKind: String, CaseIterable, Identifiable, Sendable {
  case text
  case graph

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .text:
      return "Text"
    case .graph:
      return "Graph"
    }
  }
}
