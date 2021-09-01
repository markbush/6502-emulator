import XCTest
@testable import Emulator6502

final class Bus8Tests: XCTestCase {
  func testGetBits() throws {
      let bus = Bus8()

      let bitValues:[UInt8] = [
        0b0000_0001,
        0b0000_0010,
        0b0000_0100,
        0b0000_1000,
        0b0001_0000,
        0b0010_0000,
        0b0100_0000,
        0b1000_0000,
      ]
      for b in 0..<bitValues.count {
        bus.value = bitValues[b]
        XCTAssert(bus[b])
      }
  }

  func testSetBits() throws {
      let bus = Bus8()

      let bitValues:[UInt8] = [
        0b0000_0001,
        0b0000_0010,
        0b0000_0100,
        0b0000_1000,
        0b0001_0000,
        0b0010_0000,
        0b0100_0000,
        0b1000_0000,
      ]
      for b in 0..<bitValues.count {
        bus.value = 0
        bus[b] = true
        XCTAssertEqual(bus.value, bitValues[b])
      }
  }
}
