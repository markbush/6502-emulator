import XCTest
import Foundation
@testable import Emulator6502

final class RorZpTests: XCTestCase {
  func testRorZp() {
    print("debug: testRorZp")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let testValue2:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x003c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.RORZp
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.RORZp)

    print("debug: perform ROR")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.RORZp)

    // Save ADL - fetch arg
    // Memory unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)
    XCTAssertEqual(memory[memStore], testValue2)

    // Shift data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)

    // Save data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssertEqual(memory[memStore], testValue2 >> 1)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
