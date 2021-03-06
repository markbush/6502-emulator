import XCTest
import Foundation
@testable import Emulator6502

final class SbcAbsYTests: XCTestCase {
  func testSbcAbsYNoPageChange() {
    print("debug: testSbcAbsYNoPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1a3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x1a41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCAbsY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[actualStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    cpu.status.value = Status6502.CARRY // Set carry

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCAbsY)

    print("debug: perform SBC AbsY")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCAbsY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Subtract arg from A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testSbcAbsYWithPageChange() {
    print("debug: testSbcAbsYWithPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1afc
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x1b01
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.SBCAbsY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = UInt8(memStore >> 8) // high byte
    memory[TestHelper.RES_ADDR&+3] = TestHelper.NOP
    memory[actualStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    cpu.status.value = Status6502.CARRY // Set carry

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.SBCAbsY)

    print("debug: perform SBC AbsY")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.SBCAbsY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch ADH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(memStore >> 8))

    // Save ADH - fetch arg - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertNotEqual(pins.data.value, testValue2)

    // Save ADH - fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Subtract arg from A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &- testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
