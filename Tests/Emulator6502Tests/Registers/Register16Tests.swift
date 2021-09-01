import XCTest
@testable import Emulator6502

final class Register16Tests: XCTestCase {
    func test8BitValueGetsSaved() throws {
      let r = Register16()

      r.value = 0x24
      XCTAssertEqual(r.value, 0x24)
    }

    func test16BitValueGetsSaved() throws {
      let r = Register16()

      r.value = 0x1c1c
      XCTAssertEqual(r.value, 0x1c1c)
    }

    func testHighReturnsTop8Bits() {
      let r = Register16()

      r.value = 0x17fe
      XCTAssertEqual(r.high, 0x17)
    }

    func testHighSetsTop8Bits() {
      let r = Register16()

      r.value = 0x17fe
      r.high = 0x02
      XCTAssertEqual(r.value, 0x02fe)
    }

    func testLowReturnsBottom8Bits() {
      let r = Register16()

      r.value = 0x17fe
      XCTAssertEqual(r.low, 0xfe)
    }

    func testLowSetsBottom8Bits() {
      let r = Register16()

      r.value = 0x17fe
      r.low = 0xa4
      XCTAssertEqual(r.value, 0x17a4)
    }
}
