import Testing
@testable import MacmonBar

@Test
func formatsAppVersionForFooter() {
  let version = AppVersion(version: "1.0.0", build: "42")

  #expect(version.displayText == "v1.0.0 (42)")
}
