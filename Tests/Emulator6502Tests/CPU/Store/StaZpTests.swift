import XCTest
import Foundation
@testable import Emulator6502

final class StaZpTests: XCTestCase {
  func testStaZp() {
    print("debug: testStaZp")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STAZp
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = 0 // ensure memory is clear
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STAZp)

    print("debug: perform STA Zp")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STAZp)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - store arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[memStore], testValue1)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
