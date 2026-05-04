import AppKit
import SwiftUI
import Testing
@testable import MacmonBar

@MainActor
@Test
func renderReadmeDashboardScreenshot() throws {
  guard let outputPath = ProcessInfo.processInfo.environment["MACMONBAR_README_SCREENSHOT"] else {
    return
  }

  let history = makeScreenshotHistory()
  let snapshot = try #require(history.last)
  let view = ReadmeDashboardScreenshotView(snapshot: snapshot, history: history)
  let renderer = ImageRenderer(content: view)
  renderer.scale = 2

  let image = try #require(renderer.nsImage)
  let tiffData = try #require(image.tiffRepresentation)
  let bitmap = try #require(NSBitmapImageRep(data: tiffData))
  let pngData = try #require(bitmap.representation(using: .png, properties: [:]))
  let outputURL = URL(fileURLWithPath: outputPath)

  try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try pngData.write(to: outputURL)
}

private struct ReadmeDashboardScreenshotView: View {
  let snapshot: MetricSnapshot
  let history: [MetricSnapshot]

  var body: some View {
    ZStack {
      Color(red: 0.04, green: 0.04, blue: 0.04)

      VStack(alignment: .leading, spacing: 10) {
        header

        SnapshotContentView(snapshot: snapshot, history: history)

        Divider()

        footer
      }
      .padding(12)
      .frame(width: 520)
      .background(Color(red: 0.07, green: 0.07, blue: 0.07), in: .rect(cornerRadius: 24))
      .overlay {
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.white.opacity(0.14), lineWidth: 1)
      }
      .padding(24)
    }
    .frame(width: 568, height: 760)
    .environment(\.colorScheme, .dark)
  }

  private var header: some View {
    HStack(spacing: 10) {
      Image(systemName: "waveform.path.ecg")
        .foregroundStyle(.green)
        .symbolRenderingMode(.hierarchical)
        .font(.headline)
        .frame(width: 22, height: 22)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(MetricText.chipLine(for: snapshot))
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .lineLimit(1)

        Text("Sampling every 1.0s")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      IntervalControlView(
        intervalTitle: "1.0s",
        canDecrease: true,
        canIncrease: true,
        decreaseAction: {},
        increaseAction: {}
      )
    }
  }

  private var footer: some View {
    HStack {
      Text("07:30")
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()

      Text("·")
        .font(.caption)
        .foregroundStyle(.tertiary)

      Text("\(history.count) samples")
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()

      Spacer()

      VStack(alignment: .trailing, spacing: 2) {
        Text("Process power is estimated")
          .font(.caption2)
          .foregroundStyle(.tertiary)

        Text("macmon")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private func makeScreenshotHistory() -> [MetricSnapshot] {
  (0..<90).map { index in
    let phase = Double(index) / 9
    let cpu = 0.28 + 0.12 * sin(phase)
    let pCPU = 0.14 + 0.08 * sin(phase * 1.7)
    let eCPU = 0.38 + 0.1 * cos(phase * 1.2)
    let gpu = 0.08 + 0.05 * sin(phase * 0.8)
    let power = 18 + 6 * sin(phase * 0.65)
    let down = 420_000 + 260_000 * max(sin(phase * 1.3), 0)
    let up = 86_000 + 72_000 * max(cos(phase * 0.9), 0)

    return MetricSnapshot(
      id: Date(timeIntervalSince1970: 1_800_000_000 + Double(index)),
      temp: TemperatureMetrics(
        cpuAverage: 46 + 2 * sin(phase),
        gpuAverage: 44 + 2 * cos(phase)
      ),
      memory: MemoryMetrics(
        ramTotal: 64 * 1_073_741_824,
        ramUsage: Int64((28 + 2 * sin(phase * 0.3)) * 1_073_741_824),
        swapTotal: 11 * 1_073_741_824,
        swapUsage: Int64(9.6 * 1_073_741_824)
      ),
      network: NetworkMetrics(
        downloadBytesPerSecond: down,
        uploadBytesPerSecond: up,
        receivedBytes: Int64(92 * 1_000_000_000 + index * 420_000),
        transmittedBytes: Int64(18 * 1_000_000_000 + index * 86_000)
      ),
      ecpuUsage: FrequencyUsage(frequencyMHz: 1840 + index % 420, utilizationRatio: eCPU),
      pcpuUsage: FrequencyUsage(frequencyMHz: 1900 + index % 500, utilizationRatio: pCPU),
      cpuUsageRatio: cpu,
      gpuUsage: FrequencyUsage(frequencyMHz: 338, utilizationRatio: gpu),
      cpuPower: 1.2 + 0.4 * sin(phase),
      gpuPower: 0.4 + 0.2 * cos(phase),
      anePower: 0.0,
      allPower: 1.6,
      sysPower: power,
      ramPower: 0.2,
      gpuRamPower: 0,
      processPower: screenshotProcessPower,
      soc: SocInfo(
        macModel: "Mac16,5",
        chipName: "Apple M4 Max",
        memoryGB: 64,
        ecpuCores: 4,
        pcpuCores: 12,
        ecpuLabel: "E",
        pcpuLabel: "P",
        ecpuFreqs: [744, 972, 1320, 1840],
        pcpuFreqs: [696, 1056, 1900, 2400],
        gpuCores: 40,
        gpuFreqs: [338, 461, 720]
      )
    )
  }
}

private let screenshotProcessPower = [
  ProcessPowerMetric(pid: 1240, name: "Xcode", estimatedPower: 0.74, cpuUsagePercent: 28.4),
  ProcessPowerMetric(pid: 981, name: "Google Chrome Helper", estimatedPower: 0.52, cpuUsagePercent: 20.2),
  ProcessPowerMetric(pid: 2215, name: "Simulator", estimatedPower: 0.31, cpuUsagePercent: 12.1),
  ProcessPowerMetric(pid: 503, name: "WindowServer", estimatedPower: 0.26, cpuUsagePercent: 9.4),
  ProcessPowerMetric(pid: 811, name: "codex", estimatedPower: 0.18, cpuUsagePercent: 6.2),
]
