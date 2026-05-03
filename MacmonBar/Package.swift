// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "MacmonBar",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v14),
  ],
  products: [
    .executable(name: "MacmonBar", targets: ["MacmonBar"]),
  ],
  targets: [
    .executableTarget(
      name: "MacmonBar",
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]
    ),
    .testTarget(
      name: "MacmonBarTests",
      dependencies: ["MacmonBar"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
      ]
    ),
  ]
)
