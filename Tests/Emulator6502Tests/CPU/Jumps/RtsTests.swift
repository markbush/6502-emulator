import XCTest
import Foundation
@testable import Emulator6502

final class RtsTests: XCTestCase {
  func testRts() {
    print("debug: testRts")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let target:UInt16 = 0x3c2a
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.RTS
    memory[stackTopAddr] = UInt8(target >> 8)
    memory[stackTopAddr&-1] = UInt8(target & 0xff) &- 1
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP &- 2 // Ensure stack pointer setup

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.RTS)

    print("debug: perform RTS")
    // decode OP - discard arg
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(cpu.ir.value, TestHelper.RTS)

    // read from existing SP - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, stackTopAddr&-2)

    // read PCL
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(pins.data.value, UInt8(target & 0xff) &- 1)

    // read PCH
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, UInt8(target >> 8))

    // read PC - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, target &- 1)

    // Jump to new address
    // Stack increased by 2
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, target)
    XCTAssertEqual(pins.data.value, TestHelper.NOP)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
