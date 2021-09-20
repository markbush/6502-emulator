import XCTest
import Foundation
@testable import Emulator6502

final class IncAbsTests: XCTestCase {
  func testIncAbsPositive() {
    print("debug: testIncAbsPositive")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let testValue2:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x533c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.INCAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear zero, negative
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.INCAbs)

    print("debug: perform INC")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.INCAbs)

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[memStore], testValue2)

    // Save ADH - fetch arg
    // Memory unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)
    XCTAssertEqual(memory[memStore], testValue2)

    // Inc data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)

    // Save data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssertEqual(memory[memStore], testValue2 &+ 1)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Incode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testIncAbsZero() {
    print("debug: testIncAbsZero")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let testValue2:UInt8 = 0xff
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x533c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.INCAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear zero, negative
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.INCAbs)

    print("debug: perform INC")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.INCAbs)

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[memStore], testValue2)

    // Save ADH - fetch arg
    // Memory unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)
    XCTAssertEqual(memory[memStore], testValue2)

    // Inc data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)

    // Save data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssertEqual(memory[memStore], 0)
    XCTAssert(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Incode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }


  func testIncAbsNegative() {
    print("debug: testIncAbsNegative")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let testValue2:UInt8 = 0xa7
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x533c
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.INCAbs
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[memStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear zero, negative
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.INCAbs)

    print("debug: perform INC")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.INCAbs)

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[memStore], testValue2)

    // Save ADH - fetch arg
    // Memory unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)
    XCTAssertEqual(memory[memStore], testValue2)

    // Inc data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)

    // Save data
    // A unchanged
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssertEqual(memory[memStore], testValue2 &+ 1)
    XCTAssertFalse(cpu.status.zero)
    XCTAssert(cpu.status.negative)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Incode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
