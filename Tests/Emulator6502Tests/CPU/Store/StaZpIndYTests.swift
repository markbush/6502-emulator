import XCTest
import Foundation
@testable import Emulator6502

final class StaZpIndYTests: XCTestCase {
  func testStaZpIndY() {
    print("debug: testStaZpIndY")
    let pins = Pins()
    let testValue1:UInt8 = 0x26
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x2a41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STAZpIndY
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore+UInt16(offset)] = 0 // ensure memory is clear
    memory[memStore] = UInt8(actualStore & 0xff)
    memory[memStore + 1] = UInt8(actualStore >> 8)
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.a.value = testValue1 // Set the accumulator
    cpu.y.value = offset

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STAZpIndY)

    print("debug: perform STA ZpIndY")
    // decode OP - fetch IAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STAZpIndY)
    XCTAssertEqual(pins.data.value, UInt8(memStore & 0xff))

    // Fetch BAL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore & 0xff))

    // Fetch BAH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, UInt8(actualStore >> 8))

    // Fetch BAH,BAL+Y - discard for carry
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Store A to BAH,BAL+Y
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[actualStore+UInt16(offset)], testValue1)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
