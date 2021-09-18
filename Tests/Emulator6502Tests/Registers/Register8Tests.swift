import XCTest
@testable import Emulator6502

final class Register8Tests: XCTestCase {
    func testValueGetsSaved() throws {
      let r = Register8()

      r.value = 0x24
      XCTAssertEqual(r.value, 0x24)
    }

    func testShiftLeftWithoutCarry() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.shiftLeft()
      XCTAssertEqual(newValue, 0x48)
      XCTAssertEqual(carryOut, false)
    }

    func testShiftLeftWithCarry() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.shiftLeft()
      XCTAssertEqual(newValue, 0xb2)
      XCTAssertEqual(carryOut, true)
    }

    func testShiftRightWithoutCarry() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.shiftRight()
      XCTAssertEqual(newValue, 0x12)
      XCTAssertEqual(carryOut, false)
    }

    func testShiftRightWithCarry() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.shiftRight()
      XCTAssertEqual(newValue, 0x6c)
      XCTAssertEqual(carryOut, true)
    }

    func testRotateLeftWithoutCarries() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.rotateLeft(carryIn: false)
      XCTAssertEqual(newValue, 0x48)
      XCTAssertEqual(carryOut, false)
    }

    func testRotateLeftWithCarryIn() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.rotateLeft(carryIn: true)
      XCTAssertEqual(newValue, 0x49)
      XCTAssertEqual(carryOut, false)
    }

    func testRotateLeftWithCarryOut() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.rotateLeft(carryIn: false)
      XCTAssertEqual(newValue, 0xb2)
      XCTAssertEqual(carryOut, true)
    }

    func testRotateLeftWithCarryInOut() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.rotateLeft(carryIn: true)
      XCTAssertEqual(newValue, 0xb3)
      XCTAssertEqual(carryOut, true)
    }

    func testRotateRightWithoutCarries() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.rotateRight(carryIn: false)
      XCTAssertEqual(newValue, 0x12)
      XCTAssertEqual(carryOut, false)
    }

    func testRotateRightWithCarryIn() throws {
      let r = Register8()

      r.value = 0x24
      let (newValue, carryOut, _, _) = r.rotateRight(carryIn: true)
      XCTAssertEqual(newValue, 0x92)
      XCTAssertEqual(carryOut, false)
    }

    func testRotateRightWithCarryOut() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.rotateRight(carryIn: false)
      XCTAssertEqual(newValue, 0x6c)
      XCTAssertEqual(carryOut, true)
    }

    func testRotateRightWithCarryInOut() throws {
      let r = Register8()

      r.value = 0xd9
      let (newValue, carryOut, _, _) = r.rotateRight(carryIn: true)
      XCTAssertEqual(newValue, 0xec)
      XCTAssertEqual(carryOut, true)
    }

    func testIncrementNoOverflow() throws {
      let r = Register8()

      r.value = 0x24
      r.incr()
      XCTAssertEqual(r.value, 0x25)
    }

    func testIncrementWithOverflow() throws {
      let r = Register8()

      r.value = 0xff
      r.incr()
      XCTAssertEqual(r.value, 0x00)
    }

    func testDecrementNoOverflow() throws {
      let r = Register8()

      r.value = 0x24
      r.decr()
      XCTAssertEqual(r.value, 0x23)
    }

    func testDecrementWithOverflow() throws {
      let r = Register8()

      r.value = 0x00
      r.decr()
      XCTAssertEqual(r.value, 0xff)
    }

    func testBitGetting() throws {
      let r = Register8()

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
      for i in 0..<bitValues.count {
        r.value = bitValues[i]
        XCTAssertEqual(r[i], true)
      }
    }

    func testBitSetting() throws {
      let r = Register8()

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
      for i in 0..<bitValues.count {
        r.value = 0
        r[i] = true
        XCTAssertEqual(r.value, bitValues[i])
      }
    }

    func testBitClearing() throws {
      let r = Register8()

      let bitValues:[UInt8] = [
        0b1111_1110,
        0b1111_1101,
        0b1111_1011,
        0b1111_0111,
        0b1110_1111,
        0b1101_1111,
        0b1011_1111,
        0b0111_1111,
      ]
      for i in 0..<bitValues.count {
        r.value = 0xff
        r[i] = false
        XCTAssertEqual(r.value, bitValues[i])
      }
    }
}
