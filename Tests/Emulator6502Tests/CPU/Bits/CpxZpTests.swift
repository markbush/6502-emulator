import XCTest
import Foundation
@testable import Emulator6502

final class CpxZpTests: XCTestCase {
  func testCpxZp() {
    print("debug: testCpxZp")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x003c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CPXZp
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X
    // Clear carry, set zero, negative
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CPXZp)

    print("debug: perform CPX Zp")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CPXZp)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Cmp arg to X
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue1)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
