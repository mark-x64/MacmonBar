import Foundation

struct AppVersion: Equatable, Sendable {
  let version: String
  let build: String

  var displayText: String {
    "v\(version) (\(build))"
  }

  static var current: AppVersion {
    let info = Bundle.main.infoDictionary ?? [:]
    let version = info["CFBundleShortVersionString"] as? String ?? "0.0.0"
    let build = info["CFBundleVersion"] as? String ?? "0"

    return AppVersion(version: version, build: build)
  }
}
