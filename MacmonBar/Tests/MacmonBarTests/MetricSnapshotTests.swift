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
