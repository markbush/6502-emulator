import XCTest
import Foundation
@testable import Emulator6502

final class StyZpXTests: XCTestCase {
  func testStyZpX() {
    print("debug: testStyZpX")
    let pins = Pins()
    let testValue1:UInt8 = 0xc3
    let memory = TestHelper.initMemory(pins)
    let memStore:UInt16 = 0x3c
    let offset:UInt8 = 0x05
    let actualStore:UInt16 = 0x41
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.STYZpX
    memory[TestHelper.RES_ADDR&+1] = UInt8(memStore & 0xff) // low byte
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[actualStore] = 0
    let cpu = CPU6502(pins)
    cpu.reset()
    cpu.x.value = offset // Index offset from base address

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.y.value = testValue1 // Set Y

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.STYZpX)

    print("debug: perform STY")
    // decode OP - fetch ADL
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.STYZpX)

    // Save ADL - discard read
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Write Y
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.data.value, testValue1)

    // Fetch next op
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[actualStore], testValue1)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
