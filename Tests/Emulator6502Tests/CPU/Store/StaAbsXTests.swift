import XCTest
import Foundation
@testable import Emulator6502

final class StaAbsXTests: XCTestCase {
  func testStaAbsX() {
    print("debug: testStaAbsX")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x573c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x5741
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STAAbsX
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[actualStore] = 0
    let cpu = CPU6502(pins)
    cpu.reset()

    cpu.x.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STAAbsX)

    print("debug: perform STA")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STAAbsX)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - discard read
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Write A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[actualStore], testValue1)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
