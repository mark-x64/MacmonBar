import Darwin
import Foundation
import Testing
@testable import MacmonBar

@Test
func prefersExplicitMacmonBinaryEnvironmentPath() throws {
  let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer {
    try? FileManager.default.removeItem(at: directory)
  }

  let executableURL = directory.appending(path: "macmon")
  try Data().write(to: executableURL)
  chmod(executableURL.path, 0o755)

  let locator = MacmonBinaryLocator(
    environment: ["MACMON_BIN": executableURL.path],
    currentDirectory: directory,
    bundledExecutableURL: nil
  )

  #expect(try locator.resolve() == executableURL.standardizedFileURL)
}
