import XCTest
import Foundation
@testable import Emulator6502

final class BcsTests: XCTestCase {
  func testBcsNoBranch() {
    print("debug: testBcsNoBranch")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x0a
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCS
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry clear
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCS)

    print("debug: perform BCS")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCS)
    XCTAssertEqual(pins.data.value, offset)

    // No branch - continue with next instruction
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR&+2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBcsBranchNoPageCross() {
    print("debug: testBcsBranchNoPageCross")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x0a
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCS
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry set
    cpu.status.value = Status6502.CARRY

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCS)

    print("debug: perform BCS")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCS)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBcsBranchPageCross() {
    print("debug: testBcsBranchPageCross")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x61
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCS
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry set
    cpu.status.value = Status6502.CARRY

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCS)

    print("debug: perform BCS")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCS)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Branch - adjust for page crossing
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
