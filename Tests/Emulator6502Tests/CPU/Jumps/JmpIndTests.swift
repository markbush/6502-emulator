import XCTest
import Foundation
@testable import Emulator6502

final class JmpIndTests: XCTestCase {
  func testJmpInd() {
    print("debug: testJmpInd")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x42ba
    let target:UInt16 = 0x3c2a
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.JMPInd
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff)
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8)
    memory[memStore] = UInt8(target & 0xff)
    memory[memStore + 1] = UInt8(target >> 8)
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.JMPInd)

    print("debug: perform JMP")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.JMPInd)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Fetch new PCL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(target & 0xff))

    // Fetch new PCH
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
