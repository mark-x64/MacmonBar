import Foundation

struct MacmonBinaryLocator: Sendable {
  let environment: [String: String]
  let currentDirectory: URL
  let bundledExecutableURL: URL?

  init(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    currentDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true),
    bundledExecutableURL: URL? = Bundle.main.url(
      forResource: "macmon",
      withExtension: nil,
      subdirectory: "bin"
    )
  ) {
    self.environment = environment
    self.currentDirectory = currentDirectory.standardizedFileURL
    self.bundledExecutableURL = bundledExecutableURL?.standardizedFileURL
  }

  var candidateURLs: [URL] {
    [
      bundledExecutableURL,
      environment["MACMON_BIN"].map { URL(fileURLWithPath: $0) },
      currentDirectory.appending(path: "../MacmonBarRuntime/target/release/macmon"),
      currentDirectory.appending(path: "MacmonBarRuntime/target/release/macmon"),
      currentDirectory.appending(path: "../macmon/target/release/macmon"),
      currentDirectory.appending(path: "macmon/target/release/macmon"),
      URL(fileURLWithPath: "/opt/homebrew/bin/macmon"),
      URL(fileURLWithPath: "/usr/local/bin/macmon"),
    ].compactMap { $0?.standardizedFileURL }
  }

  func resolve() throws -> URL {
    for candidate in candidateURLs where FileManager.default.isExecutableFile(atPath: candidate.path) {
      return candidate
    }

    throw MacmonClientError.binaryNotFound(candidateURLs.map(\.path))
  }
}
