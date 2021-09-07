import XCTest
import Foundation
@testable import Emulator6502

final class StatusTests: XCTestCase {
  func clear(_ name: String, op: UInt8, flag: UInt8) {
    print("debug: test"+name)
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = op
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    cpu.status.value = cpu.status.value | flag // Set flag initially
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, op)
    XCTAssertEqual(cpu.status.value & flag, flag)

    print("debug: perform "+name)
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, op)

    // Flag should now be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.status.value & flag, 0)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func set(_ name: String, op: UInt8, flag: UInt8) {
    print("debug: test"+name)
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = op
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    cpu.status.value = cpu.status.value & ~flag // Clear flag initially
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, op)
    XCTAssertEqual(cpu.status.value & flag, 0)

    print("debug: perform "+name)
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, op)

    // Flag should now be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.status.value & flag, flag)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testClc() throws {
    clear("CLC", op: TestHelper.CLC, flag: Status6502.CARRY)
  }
  func testCld() throws {
    clear("CLD", op: TestHelper.CLD, flag: Status6502.DECIMAL)
  }
  func testCli() throws {
    clear("CLI", op: TestHelper.CLI, flag: Status6502.INTERRUPT)
  }
  func testClv() throws {
    clear("CLV", op: TestHelper.CLV, flag: Status6502.OVERFLOW)
  }
  func testSec() throws {
    set("SEC", op: TestHelper.SEC, flag: Status6502.CARRY)
  }
  func testSed() throws {
    set("SED", op: TestHelper.SED, flag: Status6502.DECIMAL)
  }
  func testSei() throws {
    set("SEI", op: TestHelper.SEI, flag: Status6502.INTERRUPT)
  }
}
