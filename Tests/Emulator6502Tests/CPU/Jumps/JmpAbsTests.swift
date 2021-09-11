import XCTest
import Foundation
@testable import Emulator6502

final class JmpAbsTests: XCTestCase {
  func testJmpAbs() {
    print("debug: testJmpAbs")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let target:UInt16 = 0x3c2a
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.JMP
    memory[TestHelper.RES_ADDR&+1] = UInt8(target & 0xff)
    memory[TestHelper.RES_ADDR&+2] = UInt8(target >> 8)
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.JMP)

    print("debug: perform JMP")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.JMP)
    XCTAssertEqual(pins.data.value, UInt8(target & 0xff))

    // Fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(target >> 8))

    // Jump to new address
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)
    XCTAssertEqual(pins.data.value, TestHelper.NOP)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
