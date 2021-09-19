import XCTest
import Foundation
@testable import Emulator6502

final class StaZpIndXTests: XCTestCase {
  func testStaZpIndX() {
    print("debug: testStaZpIndX")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x2a41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STAZpIndX
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore] = 0 // ensure memory is clear
    memory[memStore + UInt16(offset)] = UInt8(actualStore & 0xff)
    memory[memStore + UInt16(offset) + 1] = UInt8(actualStore >> 8)
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    cpu.x.value = offset

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STAZpIndX)

    print("debug: perform STA ZpIndX")
    // decode OP - fetch BAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STAZpIndX)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Fetch 00,BAL and discard
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Fetch 00,BAL+X for ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore & 0xff))

    // Fetch 00,BAL+X+1 for ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore >> 8))

    // Store A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[actualStore], testValue1)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
