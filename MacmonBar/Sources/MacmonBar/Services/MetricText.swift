import Foundation

enum MetricText {
  static func watts(_ value: Double) -> String {
    "\(value.formatted(.number.precision(.fractionLength(1)))) W"
  }

  static func compactWatts(_ value: Double) -> String {
    "\(value.formatted(.number.precision(.fractionLength(1))))W"
  }

  static func temperature(_ value: Double) -> String {
    "\(value.formatted(.number.precision(.fractionLength(0))))°C"
  }

  static func percent(_ ratio: Double, precision: Int = 0) -> String {
    let percentage = ratio * 100
    return "\(percentage.formatted(.number.precision(.fractionLength(precision))))%"
  }

  static func compactPercent(_ ratio: Double) -> String {
    percent(ratio, precision: 0)
  }

  static func megahertz(_ value: Int) -> String {
    "\(value.formatted()) MHz"
  }

  static func gigabytes(_ bytes: Int64, precision: Int = 1) -> String {
    let value = Double(bytes) / 1_073_741_824
    return "\(value.formatted(.number.precision(.fractionLength(precision)))) GB"
  }

  static func bytes(_ value: Int64) -> String {
    value.formatted(.byteCount(style: .memory))
  }

  static func bytesPerSecond(_ value: Double) -> String {
    guard value > 0 else {
      return "0 B/s"
    }

    return "\(Int64(value).formatted(.byteCount(style: .file)))/s"
  }

  static func chipLine(for snapshot: MetricSnapshot) -> String {
    guard let soc = snapshot.soc else {
      return "Apple Silicon"
    }

    return "\(soc.chipName) - \(soc.memoryGB) GB"
  }
}
