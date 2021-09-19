import XCTest
import Foundation
@testable import Emulator6502

final class CpxImmTests: XCTestCase {
  func testCpxImmPositive() {
    print("debug: testCpxImmPositive")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CPXImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X
    // Clear carry, set zero, negative
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CPXImm)

    print("debug: perform CPX Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CPXImm)

    // Cpx arg to X - X unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue1)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testCpxImmZero() {
    print("debug: testCpxImmZero")
    let pins = Pins()
    let testValue1:UInt8 = 0xd3
    let testValue2:UInt8 = 0xd3
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CPXImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X
    // Clear carry, zero, set negative and overflow
    cpu.status.value = Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CPXImm)

    print("debug: perform CPX Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CPXImm)

    // Cpx arg to X - X unchanged
    // Carry, zero should be set, negative overflow clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue1)
    XCTAssert(cpu.status.carry)
    XCTAssert(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testCpxImmNegative() {
    print("debug: testCpxImmNegative")
    let pins = Pins()
    let testValue1:UInt8 = 0x2d
    let testValue2:UInt8 = 0x53
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CPXImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X
    // Clear negative, set zero and carry
    cpu.status.value = Status6502.ZERO | Status6502.CARRY
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CPXImm)

    print("debug: perform CPX Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CPXImm)

    // Cpx arg to X - X unchanged
    // Carry, zero should be clear, negative set
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue1)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
