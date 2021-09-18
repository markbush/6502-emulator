import XCTest
import Foundation
@testable import Emulator6502

final class RolTests: XCTestCase {
  func testRolNoCarry() {
    print("debug: testRolNoCarry")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ROL
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, negative
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ROL)

    print("debug: perform ROL")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ROL)

    // Shift A
    // Flags should be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 << 1)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testRolWithCarry() {
    print("debug: testRolWithCarry")
    let pins = Pins()
    let testValue1:UInt8 = 0x96
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ROL
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set carry, zero, negative
    cpu.status.value = Status6502.CARRY | Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ROL)

    print("debug: perform ROL")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ROL)

    // Rotate A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, (testValue1 << 1) &+ 1)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testRolWithNegative() {
    print("debug: testRolWithNegative")
    let pins = Pins()
    let testValue1:UInt8 = 0x66
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ROL
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set zero, clear carry, negative
    cpu.status.value = Status6502.ZERO
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ROL)

    print("debug: perform ROL")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ROL)

    // Rotate A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 << 1)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testRolWithZero() {
    print("debug: testRolWithZero")
    let pins = Pins()
    let testValue1:UInt8 = 0x80
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ROL
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set negative, clear zero, carry
    cpu.status.value = Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ROL)

    print("debug: perform ROL")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ROL)

    // Rotate A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 << 1)
    XCTAssert(cpu.status.carry)
    XCTAssert(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
