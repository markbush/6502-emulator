import XCTest
@testable import Emulator6502

final class Status6502Tests: XCTestCase {
  func testSetCarry() {
    let p = Status6502()

    p.value = 0
    p.carry = true
    XCTAssert(p.carry)
    XCTAssertEqual(p.value, Status6502.CARRY)
  }
  func testClearCarry() {
    let p = Status6502()

    p.value = 0xff
    p.carry = false
    XCTAssertFalse(p.carry)
    XCTAssertEqual(p.value, Status6502.CARRY_MASK)
  }

  func testSetZero() {
    let p = Status6502()

    p.value = 0
    p.zero = true
    XCTAssert(p.zero)
    XCTAssertEqual(p.value, Status6502.ZERO)
  }
  func testClearZero() {
    let p = Status6502()

    p.value = 0xff
    p.zero = false
    XCTAssertFalse(p.zero)
    XCTAssertEqual(p.value, Status6502.ZERO_MASK)
  }

  func testSetInterrupt() {
    let p = Status6502()

    p.value = 0
    p.interrupt = true
    XCTAssert(p.interrupt)
    XCTAssertEqual(p.value, Status6502.INTERRUPT)
  }
  func testClearInterrupt() {
    let p = Status6502()

    p.value = 0xff
    p.interrupt = false
    XCTAssertFalse(p.interrupt)
    XCTAssertEqual(p.value, Status6502.INTERRUPT_MASK)
  }

  func testSetDecimal() {
    let p = Status6502()

    p.value = 0
    p.decimal = true
    XCTAssert(p.decimal)
    XCTAssertEqual(p.value, Status6502.DECIMAL)
  }
  func testClearDecimal() {
    let p = Status6502()

    p.value = 0xff
    p.decimal = false
    XCTAssertFalse(p.decimal)
    XCTAssertEqual(p.value, Status6502.DECIMAL_MASK)
  }

  func testSetBreak() {
    let p = Status6502()

    p.value = 0
    p.brk = true
    XCTAssert(p.brk)
    XCTAssertEqual(p.value, Status6502.BREAK)
  }
  func testClearBreak() {
    let p = Status6502()

    p.value = 0xff
    p.brk = false
    XCTAssertFalse(p.brk)
    XCTAssertEqual(p.value, Status6502.BREAK_MASK)
  }

  func testSetOverflow() {
    let p = Status6502()

    p.value = 0
    p.overflow = true
    XCTAssert(p.overflow)
    XCTAssertEqual(p.value, Status6502.OVERFLOW)
  }
  func testClearOverflow() {
    let p = Status6502()

    p.value = 0xff
    p.overflow = false
    XCTAssertFalse(p.overflow)
    XCTAssertEqual(p.value, Status6502.OVERFLOW_MASK)
  }

  func testSetNegative() {
    let p = Status6502()

    p.value = 0
    p.negative = true
    XCTAssert(p.negative)
    XCTAssertEqual(p.value, Status6502.NEGATIVE)
  }
  func testClearNegative() {
    let p = Status6502()

    p.value = 0xff
    p.negative = false
    XCTAssertFalse(p.negative)
    XCTAssertEqual(p.value, Status6502.NEGATIVE_MASK)
  }
}
