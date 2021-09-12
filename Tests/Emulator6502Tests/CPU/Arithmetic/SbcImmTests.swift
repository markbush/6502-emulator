import XCTest
import Foundation
@testable import Emulator6502

final class SbcImmTests: XCTestCase {
  func testSbcImmPositive() {
    print("debug: testSbcImmPositive")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set carry, zero, negative and overflow
    cpu.status.value = Status6502.CARRY | Status6502.ZERO | Status6502.NEGATIVE | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCImm)

    print("debug: perform SBC Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCImm)

    // Add arg to A
    // Flags should be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
    XCTAssertFalse(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testSbcImmZero() {
    print("debug: testSbcImmZero")
    let pins = Pins()
    let testValue1:UInt8 = 0xd3
    let testValue2:UInt8 = 0xd3
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear zero, set carry, negative and overflow
    cpu.status.value = Status6502.CARRY | Status6502.NEGATIVE | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCImm)

    print("debug: perform SBC Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCImm)

    // Add arg to A
    // Carry, zero should be set, negative overflow clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, 0)
    XCTAssert(cpu.status.carry)
    XCTAssert(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
    XCTAssertFalse(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testSbcImmNegative() {
    print("debug: testSbcImmNegative")
    let pins = Pins()
    let testValue1:UInt8 = 0x2d
    let testValue2:UInt8 = 0x53
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear negative, set carry, zero and overflow
    cpu.status.value = Status6502.CARRY | Status6502.ZERO | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCImm)

    print("debug: perform SBC Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCImm)

    // Add arg to A
    // Carry, zero should be set, negative overflow clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)
    XCTAssertFalse(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testSbcImmPositiveOverflow() {
    print("debug: testSbcImmPositiveOverflow")
    let pins = Pins()
    let testValue1:UInt8 = 0x63
    let testValue2:UInt8 = 0xc5
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set carry, zero, clear negative and overflow
    cpu.status.value = Status6502.CARRY | Status6502.ZERO
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCImm)

    print("debug: perform SBC Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCImm)

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)
    XCTAssert(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testSbcImmNegativeOverflow() {
    print("debug: testSbcImmNegativeOverflow")
    let pins = Pins()
    let testValue1:UInt8 = 0xb3
    let testValue2:UInt8 = 0x6d
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCImm
    memory[TestHelper.RES_ADDR&+1] = testValue2
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Set carry, zero, negative and clear overflow
    cpu.status.value = Status6502.CARRY | Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCImm)

    print("debug: perform SBC Imm")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCImm)

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
    XCTAssert(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
