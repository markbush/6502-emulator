import XCTest
import Foundation
@testable import Emulator6502

final class CmpZpIndYTests: XCTestCase {
  func testCmpZpIndYNoPageChange() {
    print("debug: testCmpZpIndYNoPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x2341
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CMPZpIndY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff)
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = UInt8(actualStore & 0xff)
    memory[memStore + 1] = UInt8(actualStore >> 8)
    memory[actualStore+UInt16(offset)] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, negative
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CMPZpIndY)

    print("debug: perform CMP ZpIndY")
    // decode OP - fetch IAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CMPZpIndY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Fetch BAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore & 0xff))

    // Fetch BAH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore >> 8))

    // Fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Cmp arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testCmpZpIndYWithPageChange() {
    print("debug: testCmpZpIndYWithPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x23fd
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.CMPZpIndY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff)
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[memStore] = UInt8(actualStore & 0xff)
    memory[memStore + 1] = UInt8(actualStore >> 8)
    memory[actualStore+UInt16(offset)] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    // Clear carry, set zero, negative
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.CMPZpIndY)

    print("debug: perform CMP ZpIndY")
    // decode OP - fetch IAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.CMPZpIndY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Fetch BAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore & 0xff))

    // Fetch BAH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore >> 8))

    // Fetch arg from wrong page
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(0x2302))
    XCTAssertNotEqual(pins.data.value, testValue2)

    // Fetch arg from correct page
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(0x2402))
    XCTAssertEqual(pins.data.value, testValue2)

    // Cmp arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1)
    XCTAssert(cpu.status.carry)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
