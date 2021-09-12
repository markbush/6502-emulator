import XCTest
import Foundation
@testable import Emulator6502

final class SbcZpTests: XCTestCase {
  func testSbcZp() {
    print("debug: testSbcZpPositive")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x003c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCZp
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set carry
    cpu.status.value = Status6502.CARRY
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCZp)

    print("debug: perform SBC Zp")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCZp)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Subtract arg from A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
