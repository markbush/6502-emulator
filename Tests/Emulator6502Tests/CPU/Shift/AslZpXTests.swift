import XCTest
import Foundation
@testable import Emulator6502

final class AslZpXTests: XCTestCase {
  func testAslZpX() {
    print("debug: testAslZpX")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let testValue2:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ASLZpX
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.debug = true
    cpu.reset()
    cpu.x.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ASLZpX)

    print("debug: perform ASL")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ASLZpX)

    // Save ADL - fetch arg, discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Fetch arg
    // Memory unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)
    XCTAssertEqual(memory[actualStore], testValue2)

    // Shift data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)

    // Save data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssertEqual(memory[actualStore], testValue2 << 1)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
