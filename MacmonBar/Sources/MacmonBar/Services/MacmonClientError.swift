import Foundation

enum MacmonClientError: LocalizedError, Sendable {
  case binaryNotFound([String])
  case invalidOutput(String)
  case processFailed(status: Int32, stderr: String)

  var errorDescription: String? {
    switch self {
    case .binaryNotFound(let paths):
      return """
      macmon binary not found. Run `make macmon`, set MACMON_BIN, or install macmon with Homebrew.

      Checked:
      \(paths.joined(separator: "\n"))
      """
    case .invalidOutput(let line):
      return "macmon returned JSON that MacmonBar could not decode: \(line)"
    case .processFailed(let status, let stderr):
      let detail = stderr.isEmpty ? "No error output." : stderr
      return "macmon exited with status \(status). \(detail)"
    }
  }
}
