import XCTest
import Foundation
@testable import Emulator6502

final class AdcZpIndYTests: XCTestCase {
  func testAdcZpIndYNoPageChange() {
    print("debug: testAdcZpIndYNoPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x2341
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ADCZpIndY
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

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ADCZpIndY)

    print("debug: perform ADC ZpIndY")
    // decode OP - fetch IAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ADCZpIndY)
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

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testAdcZpIndYWithPageChange() {
    print("debug: testAdcZpIndYWithPageChange")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let testValue2:UInt8 = 0x1c
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x23fd
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.ADCZpIndY
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

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.ADCZpIndY)

    print("debug: perform ADC ZpIndY")
    // decode OP - fetch IAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.ADCZpIndY)
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

    // Add arg to A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue1 &+ testValue2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
