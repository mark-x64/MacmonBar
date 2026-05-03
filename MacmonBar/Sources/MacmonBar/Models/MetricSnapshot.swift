import Foundation

struct MetricSnapshot: Decodable, Equatable, Identifiable, Sendable {
  let id: Date
  let timestamp: String?
  let temp: TemperatureMetrics
  let memory: MemoryMetrics
  let ecpuUsage: FrequencyUsage
  let pcpuUsage: FrequencyUsage
  let cpuUsageRatio: Double
  let gpuUsage: FrequencyUsage
  let cpuPower: Double
  let gpuPower: Double
  let anePower: Double
  let allPower: Double
  let sysPower: Double
  let ramPower: Double
  let gpuRamPower: Double
  let soc: SocInfo?

  enum CodingKeys: String, CodingKey {
    case timestamp
    case temp
    case memory
    case ecpuUsage = "ecpu_usage"
    case pcpuUsage = "pcpu_usage"
    case cpuUsageRatio = "cpu_usage_pct"
    case gpuUsage = "gpu_usage"
    case cpuPower = "cpu_power"
    case gpuPower = "gpu_power"
    case anePower = "ane_power"
    case allPower = "all_power"
    case sysPower = "sys_power"
    case ramPower = "ram_power"
    case gpuRamPower = "gpu_ram_power"
    case soc
  }

  init(
    id: Date = .now,
    timestamp: String? = nil,
    temp: TemperatureMetrics,
    memory: MemoryMetrics,
    ecpuUsage: FrequencyUsage,
    pcpuUsage: FrequencyUsage,
    cpuUsageRatio: Double,
    gpuUsage: FrequencyUsage,
    cpuPower: Double,
    gpuPower: Double,
    anePower: Double,
    allPower: Double,
    sysPower: Double,
    ramPower: Double,
    gpuRamPower: Double,
    soc: SocInfo? = nil
  ) {
    self.id = id
    self.timestamp = timestamp
    self.temp = temp
    self.memory = memory
    self.ecpuUsage = ecpuUsage
    self.pcpuUsage = pcpuUsage
    self.cpuUsageRatio = cpuUsageRatio
    self.gpuUsage = gpuUsage
    self.cpuPower = cpuPower
    self.gpuPower = gpuPower
    self.anePower = anePower
    self.allPower = allPower
    self.sysPower = sysPower
    self.ramPower = ramPower
    self.gpuRamPower = gpuRamPower
    self.soc = soc
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)

    self.id = timestamp.flatMap { try? Date($0, strategy: .iso8601) } ?? .now
    self.timestamp = timestamp
    self.temp = try container.decode(TemperatureMetrics.self, forKey: .temp)
    self.memory = try container.decode(MemoryMetrics.self, forKey: .memory)
    self.ecpuUsage = try container.decode(FrequencyUsage.self, forKey: .ecpuUsage)
    self.pcpuUsage = try container.decode(FrequencyUsage.self, forKey: .pcpuUsage)
    self.cpuUsageRatio = try container.decode(Double.self, forKey: .cpuUsageRatio)
    self.gpuUsage = try container.decode(FrequencyUsage.self, forKey: .gpuUsage)
    self.cpuPower = try container.decode(Double.self, forKey: .cpuPower)
    self.gpuPower = try container.decode(Double.self, forKey: .gpuPower)
    self.anePower = try container.decode(Double.self, forKey: .anePower)
    self.allPower = try container.decode(Double.self, forKey: .allPower)
    self.sysPower = try container.decode(Double.self, forKey: .sysPower)
    self.ramPower = try container.decode(Double.self, forKey: .ramPower)
    self.gpuRamPower = try container.decode(Double.self, forKey: .gpuRamPower)
    self.soc = try container.decodeIfPresent(SocInfo.self, forKey: .soc)
  }
}

struct TemperatureMetrics: Decodable, Equatable, Sendable {
  let cpuAverage: Double
  let gpuAverage: Double

  enum CodingKeys: String, CodingKey {
    case cpuAverage = "cpu_temp_avg"
    case gpuAverage = "gpu_temp_avg"
  }
}

struct MemoryMetrics: Decodable, Equatable, Sendable {
  let ramTotal: Int64
  let ramUsage: Int64
  let swapTotal: Int64
  let swapUsage: Int64

  var ramUsageRatio: Double {
    guard ramTotal > 0 else {
      return 0
    }

    return min(max(Double(ramUsage) / Double(ramTotal), 0), 1)
  }

  var swapUsageRatio: Double {
    guard swapTotal > 0 else {
      return 0
    }

    return min(max(Double(swapUsage) / Double(swapTotal), 0), 1)
  }

  enum CodingKeys: String, CodingKey {
    case ramTotal = "ram_total"
    case ramUsage = "ram_usage"
    case swapTotal = "swap_total"
    case swapUsage = "swap_usage"
  }
}

struct FrequencyUsage: Decodable, Equatable, Sendable {
  let frequencyMHz: Int
  let utilizationRatio: Double

  init(frequencyMHz: Int, utilizationRatio: Double) {
    self.frequencyMHz = frequencyMHz
    self.utilizationRatio = utilizationRatio
  }

  init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    self.frequencyMHz = try container.decode(Int.self)
    self.utilizationRatio = try container.decode(Double.self)
  }
}

struct SocInfo: Decodable, Equatable, Sendable {
  let macModel: String
  let chipName: String
  let memoryGB: Int
  let ecpuCores: Int
  let pcpuCores: Int
  let ecpuLabel: String
  let pcpuLabel: String
  let ecpuFreqs: [Int]
  let pcpuFreqs: [Int]
  let gpuCores: Int
  let gpuFreqs: [Int]

  enum CodingKeys: String, CodingKey {
    case macModel = "mac_model"
    case chipName = "chip_name"
    case memoryGB = "memory_gb"
    case ecpuCores = "ecpu_cores"
    case pcpuCores = "pcpu_cores"
    case ecpuLabel = "ecpu_label"
    case pcpuLabel = "pcpu_label"
    case ecpuFreqs = "ecpu_freqs"
    case pcpuFreqs = "pcpu_freqs"
    case gpuCores = "gpu_cores"
    case gpuFreqs = "gpu_freqs"
  }
}
