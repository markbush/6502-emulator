import XCTest
import Foundation
@testable import Emulator6502

final class LdxZpYTests: XCTestCase {
  func testLdxZpYNoPageChange() {
    print("debug: testLdxZpYNoPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDXZpY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff)
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDXZpY)

    print("debug: perform LDX ZpY")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDXZpY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch arg - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertNotEqual(pins.data.value, testValue2)

    // Fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Load arg to X
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testLdxZpYWithPageChange() {
    print("debug: testLdxZpYWithPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x1afc
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x01
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.LDXZpY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff)
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore] = testValue2
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.y.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.x.value = testValue1 // Set X

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.LDXZpY)

    print("debug: perform LDX ZpY")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.LDXZpY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Save ADL - fetch arg - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertNotEqual(pins.data.value, testValue2)

    // Fetch arg
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue2)

    // Load arg to X
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.x.value, testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
