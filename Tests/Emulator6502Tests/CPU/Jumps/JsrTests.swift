import XCTest
import Foundation
@testable import Emulator6502

final class JsrTests: XCTestCase {
  func testJsr() {
    print("debug: testJsr")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let target:UInt16 = 0x3c2a
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.JSR
    memory[TestHelper.RES_ADDR&+1] = UInt8(target & 0xff)
    memory[TestHelper.RES_ADDR&+2] = UInt8(target >> 8)
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.JSR)

    print("debug: perform JSR")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(cpu.ir.value, TestHelper.JSR)
    XCTAssertEqual(pins.data.value, UInt8(target & 0xff))
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR&+1)

    // Spurious write to stack
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.data.value, UInt8(target & 0xff))
    XCTAssertEqual(pins.address.value, stackTopAddr)

    // Push PCH to stack
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.data.value, UInt8((TestHelper.RES_ADDR&+2) >> 8))
    XCTAssertEqual(pins.address.value, stackTopAddr)

    // Push PCL to stack
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.data.value, UInt8((TestHelper.RES_ADDR&+2) & 0xff))
    XCTAssertEqual(pins.address.value, stackTopAddr &- 1)

    // Fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.data.value, UInt8(target >> 8))
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR&+2)

    // Jump to new address
    // Stack reduced by 2
    TestHelper.cycle(cpu, pins: pins, mem: memory, true)
    XCTAssertEqual(pins.address.value, target)
    XCTAssertEqual(pins.data.value, TestHelper.NOP)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP &- 2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
