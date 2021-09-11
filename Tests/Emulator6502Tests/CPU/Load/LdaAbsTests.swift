import XCTest
import Foundation
@testable import Emulator6502

final class LdaAbsTests: XCTestCase {
  func testLdaAbsPositive() {
    print("debug: testLdaAbsPositive")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDAAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, negative and overflow
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDAAbs)

    print("debug: perform LDA Abs")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDAAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Add arg to A
    // Flags should be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
    XCTAssertFalse(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testLdaAbsZero() {
    print("debug: testLdaImmZero")
    let pins = Pins()
    let testValue1:UInt8 = 0xd3
    let testValue2:UInt8 = 0x2d
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDAAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, zero, set negative and overflow
    cpu.status.value = Status6502.NEGATIVE | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDAAbs)

    print("debug: perform LDA Abs")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDAAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

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

  func testLdaAbsNegative() {
    print("debug: testLdaAbsNegative")
    let pins = Pins()
    let testValue1:UInt8 = 0x93
    let testValue2:UInt8 = 0x2d
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDAAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, negative, set zero and overflow
    cpu.status.value = Status6502.ZERO | Status6502.OVERFLOW
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDAAbs)

    print("debug: perform LDA Abs")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDAAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Add arg to A
    // Carry, zero should be set, negative overflow clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)
    XCTAssertFalse(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testLdaAbsPositiveOverflow() {
    print("debug: testLdaAbsPositiveOverflow")
    let pins = Pins()
    let testValue1:UInt8 = 0x63
    let testValue2:UInt8 = 0x3b
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDAAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, clear negative and overflow
    cpu.status.value = Status6502.ZERO
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDAAbs)

    print("debug: perform LDA Abs")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDAAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)
    XCTAssertFalse(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)
    XCTAssert(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testLdaAbsNegativeOverflow() {
    print("debug: testLdaAbsNegativeOverflow")
    let pins = Pins()
    let testValue1:UInt8 = 0xb3
    let testValue2:UInt8 = 0x9d
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDAAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, negative and clear overflow
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDAAbs)

    print("debug: perform LDA Abs")
    // decode OP - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDAAbs)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
    XCTAssert(cpu.status.overflow)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
