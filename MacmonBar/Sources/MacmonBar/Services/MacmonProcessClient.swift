import Foundation

struct MacmonProcessClient: Sendable {
  let locator: MacmonBinaryLocator

  init(locator: MacmonBinaryLocator = MacmonBinaryLocator()) {
    self.locator = locator
  }

  func startSnapshots(
    intervalMilliseconds: Int,
    includesProcessPower: Bool = true,
    ioReportSamples: Int = 4
  ) -> MacmonSnapshotSession {
    let session = ProcessSession()
    let stream = AsyncThrowingStream<MetricSnapshot, Error> { continuation in

      do {
        let executableURL = try locator.resolve()
        let process = Process()
        process.executableURL = executableURL
        process.arguments = Self.arguments(
          intervalMilliseconds: intervalMilliseconds,
          includesProcessPower: includesProcessPower,
          ioReportSamples: ioReportSamples
        )

        let stdout = Pipe()
        let stderr = Pipe()
        let lineParser = MacmonLineParser(continuation: continuation)
        let errorBuffer = ProcessErrorBuffer()

        process.standardOutput = stdout
        process.standardError = stderr

        stdout.fileHandleForReading.readabilityHandler = { fileHandle in
          let data = fileHandle.availableData
          guard !data.isEmpty else {
            return
          }

          lineParser.consume(data)
        }

        stderr.fileHandleForReading.readabilityHandler = { fileHandle in
          let data = fileHandle.availableData
          guard !data.isEmpty else {
            return
          }

          errorBuffer.append(data)
        }

        process.terminationHandler = { terminatedProcess in
          session.clearHandlers()

          if terminatedProcess.terminationStatus == 0 {
            continuation.finish()
          } else {
            continuation.finish(
              throwing: MacmonClientError.processFailed(
                status: terminatedProcess.terminationStatus,
                stderr: errorBuffer.text
              )
            )
          }
        }

        session.assign(process: process, stdout: stdout, stderr: stderr)
        try process.run()
      } catch {
        session.clearHandlers()
        continuation.finish(throwing: error)
      }

      continuation.onTermination = { _ in
        session.terminate()
      }
    }

    return MacmonSnapshotSession(stream: stream, cancel: session.terminate)
  }
}

struct MacmonSnapshotSession: Sendable {
  let stream: AsyncThrowingStream<MetricSnapshot, Error>
  let cancel: @Sendable () -> Void
}

extension MacmonProcessClient {
  static func arguments(
    intervalMilliseconds: Int,
    includesProcessPower: Bool,
    ioReportSamples: Int = 4
  ) -> [String] {
    var arguments = [
      "--interval",
      "\(intervalMilliseconds)",
      "pipe",
      "--soc-info",
    ]

    if !includesProcessPower {
      arguments.append("--no-process-power")
    }

    if ioReportSamples != 4 {
      arguments.append(contentsOf: ["--io-report-samples", "\(ioReportSamples)"])
    }

    return arguments
  }

  func snapshots(
    intervalMilliseconds: Int,
    includesProcessPower: Bool = true,
    ioReportSamples: Int = 4
  ) -> AsyncThrowingStream<MetricSnapshot, Error> {
    startSnapshots(
      intervalMilliseconds: intervalMilliseconds,
      includesProcessPower: includesProcessPower,
      ioReportSamples: ioReportSamples
    ).stream
  }
}

private final class ProcessSession: @unchecked Sendable {
  private let lock = NSLock()
  private var process: Process?
  private var stdout: Pipe?
  private var stderr: Pipe?

  func assign(process: Process, stdout: Pipe, stderr: Pipe) {
    lock.lock()
    self.process = process
    self.stdout = stdout
    self.stderr = stderr
    lock.unlock()
  }

  func clearHandlers() {
    lock.lock()
    let stdout = stdout
    let stderr = stderr
    self.stdout = nil
    self.stderr = nil
    lock.unlock()

    stdout?.fileHandleForReading.readabilityHandler = nil
    stderr?.fileHandleForReading.readabilityHandler = nil
  }

  func terminate() {
    lock.lock()
    let process = process
    self.process = nil
    lock.unlock()

    clearHandlers()

    guard process?.isRunning == true else {
      return
    }

    process?.terminate()
  }
}

private final class MacmonLineParser: @unchecked Sendable {
  private let lock = NSLock()
  private var pendingData = Data()
  private let continuation: AsyncThrowingStream<MetricSnapshot, Error>.Continuation

  init(continuation: AsyncThrowingStream<MetricSnapshot, Error>.Continuation) {
    self.continuation = continuation
  }

  func consume(_ data: Data) {
    let lines = extractLines(from: data)
    let decoder = JSONDecoder()

    for line in lines {
      guard !line.isEmpty else {
        continue
      }

      do {
        continuation.yield(try decoder.decode(MetricSnapshot.self, from: line))
      } catch {
        let output = String(data: line.prefix(400), encoding: .utf8) ?? "<non-UTF8 output>"
        continuation.finish(throwing: MacmonClientError.invalidOutput(output))
      }
    }
  }

  private func extractLines(from data: Data) -> [Data] {
    lock.lock()
    defer {
      lock.unlock()
    }

    pendingData.append(data)

    var lines: [Data] = []
    let newline = Data([0x0A])

    while let range = pendingData.firstRange(of: newline) {
      let line = pendingData[..<range.lowerBound]
      lines.append(Data(line))
      pendingData.removeSubrange(..<range.upperBound)
    }

    return lines
  }
}

private final class ProcessErrorBuffer: @unchecked Sendable {
  private let lock = NSLock()
  private var storage = ""

  var text: String {
    lock.lock()
    defer {
      lock.unlock()
    }

    return storage
  }

  func append(_ data: Data) {
    guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
      return
    }

    lock.lock()
    storage.append(text)

    if storage.count > 4_000 {
      storage.removeFirst(storage.count - 4_000)
    }

    lock.unlock()
  }
}
