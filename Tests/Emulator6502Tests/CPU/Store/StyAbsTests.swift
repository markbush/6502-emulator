import XCTest
import Foundation
@testable import Emulator6502

final class StyAbsTests: XCTestCase {
  func testStyAbs() {
    print("debug: testStyAbs")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STYAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = 0 // ensure memory is clear
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.y.value = testValue1 // Set Y

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STYAbs)

    print("debug: perform STY Abs")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STYAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - store Y
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[memStore], testValue1)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
