import Foundation
import Testing
@testable import MacmonBar

@Test
func decodesMacmonPipeSnapshot() throws {
  let data = """
  {
    "timestamp": "2026-05-04T02:38:15.427569+00:00",
    "temp": {
      "cpu_temp_avg": 43.73614,
      "gpu_temp_avg": 36.95167
    },
    "memory": {
      "ram_total": 25769803776,
      "ram_usage": 20985479168,
      "swap_total": 4294967296,
      "swap_usage": 2602434560
    },
    "ecpu_usage": [1181, 0.082656614],
    "pcpu_usage": [1974, 0.015181795],
    "cpu_usage_pct": 0.036854,
    "gpu_usage": [461, 0.021497859],
    "cpu_power": 0.20486385,
    "gpu_power": 0.017451683,
    "ane_power": 0.0,
    "all_power": 0.22231553,
    "sys_power": 5.876533,
    "ram_power": 0.11635789,
    "gpu_ram_power": 0.0009615385,
    "soc": {
      "mac_model": "Mac15,6",
      "chip_name": "Apple M3 Pro",
      "memory_gb": 36,
      "ecpu_cores": 6,
      "pcpu_cores": 6,
      "ecpu_label": "E",
      "pcpu_label": "P",
      "ecpu_freqs": [744, 972],
      "pcpu_freqs": [696, 1056],
      "gpu_cores": 18,
      "gpu_freqs": [389, 461]
    }
  }
  """.data(using: .utf8)!

  let snapshot = try JSONDecoder().decode(MetricSnapshot.self, from: data)

  #expect(snapshot.soc?.chipName == "Apple M3 Pro")
  #expect(snapshot.memory.ramUsageRatio > 0.8)
  #expect(snapshot.ecpuUsage.frequencyMHz == 1181)
  #expect(snapshot.gpuUsage.utilizationRatio == 0.021497859)
  #expect(snapshot.allPower == 0.22231553)
}

@Test
func clampsMemoryUsageRatio() {
  let memory = MemoryMetrics(
    ramTotal: 100,
    ramUsage: 130,
    swapTotal: 0,
    swapUsage: 10
  )

  #expect(memory.ramUsageRatio == 1)
  #expect(memory.swapUsageRatio == 0)
}

@Test
func formatsMenuBarTextWithoutMetricLabels() {
  let snapshot = MetricSnapshot(
    temp: TemperatureMetrics(cpuAverage: 42, gpuAverage: 40),
    memory: MemoryMetrics(ramTotal: 100, ramUsage: 50, swapTotal: 100, swapUsage: 10),
    ecpuUsage: FrequencyUsage(frequencyMHz: 1200, utilizationRatio: 0.36),
    pcpuUsage: FrequencyUsage(frequencyMHz: 2200, utilizationRatio: 0.13),
    cpuUsageRatio: 0.2,
    gpuUsage: FrequencyUsage(frequencyMHz: 400, utilizationRatio: 0.1),
    cpuPower: 1.2,
    gpuPower: 0.4,
    anePower: 0,
    allPower: 1.6,
    sysPower: 21,
    ramPower: 0.1,
    gpuRamPower: 0
  )

  let metrics: [MenuBarMetric] = [.power, .pCPU, .eCPU]

  #expect(metrics.compactText(for: snapshot, includeLabels: true) == "PWR 21.0W  P 13%  E 36%")
  #expect(metrics.compactText(for: snapshot, includeLabels: false) == "21.0W  13%  36%")
}

@Test
func menuBarIntervalFollowsDashboardSelectionWithOneSecondMinimum() {
  #expect(
    MonitorStore.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: 500,
      isInterfaceVisible: false,
      minimumMenuBarIntervalMilliseconds: 1_000
    ) == 1_000
  )
  #expect(
    MonitorStore.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: 750,
      isInterfaceVisible: false,
      minimumMenuBarIntervalMilliseconds: 1_000
    ) == 1_000
  )
  #expect(
    MonitorStore.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: 2_000,
      isInterfaceVisible: false,
      minimumMenuBarIntervalMilliseconds: 1_000
    ) == 2_000
  )
}

@Test
func dashboardIntervalUsesExactSelectionWhenVisible() {
  #expect(
    MonitorStore.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: 500,
      isInterfaceVisible: true,
      minimumMenuBarIntervalMilliseconds: 1_000
    ) == 500
  )
  #expect(
    MonitorStore.resolvedIntervalMilliseconds(
      sampleIntervalMilliseconds: 2_000,
      isInterfaceVisible: true,
      minimumMenuBarIntervalMilliseconds: 1_000
    ) == 2_000
  )
}
