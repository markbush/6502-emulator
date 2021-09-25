import XCTest
import Foundation
@testable import Emulator6502

final class BccTests: XCTestCase {
  func testBccNoBranch() {
    print("debug: testBccNoBranch")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x0a
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCC
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry set
    cpu.status.value = Status6502.CARRY

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCC)

    print("debug: perform BCC")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCC)
    XCTAssertEqual(pins.data.value, offset)

    // No branch - continue with next instruction
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR&+2)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBccBranchNoPageCross() {
    print("debug: testBccBranchNoPageCross")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x0a
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCC
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry clear
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCC)

    print("debug: perform BCC")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCC)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBccBranchBackNoPage() {
    print("debug: testBccBranchBackNoPage")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0xfd
    let target:UInt16 = TestHelper.RES_ADDR - 1
    // First OP after reset is op
    memory[target] = TestHelper.NOP
    memory[TestHelper.RES_ADDR] = TestHelper.BCC
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry clear
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCC)

    print("debug: perform BCC")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCC)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBccBranchPageCross() {
    print("debug: testBccBranchPageCross")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let offset:UInt8 = 0x61
    let target:UInt16 = TestHelper.RES_ADDR + UInt16(offset) + 2
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.BCC
    memory[TestHelper.RES_ADDR&+1] = offset
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    memory[target] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry clear
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCC)

    print("debug: perform BCC")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCC)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Branch - adjust for page crossing
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBccBranchBackPageCross() {
    print("debug: testBccBranchBackPageCross")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    let RES_ADDR:UInt16 = 0x0800
    let RES_ADDR_LOW = UInt8(RES_ADDR & 0xff) // Reset vector
    let RES_ADDR_HIGH = UInt8(RES_ADDR >> 8)
    let offset:UInt8 = 0xfd
    let target:UInt16 = RES_ADDR - 1
    // First OP after reset is op
    memory[TestHelper.RES_VEC_LOW] = RES_ADDR_LOW
    memory[TestHelper.RES_VEC_HIGH] = RES_ADDR_HIGH

    memory[RES_ADDR&-1] = TestHelper.NOP
    memory[RES_ADDR] = TestHelper.BCC
    memory[RES_ADDR&+1] = offset
    memory[RES_ADDR&+2] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    // Ensure carry clear
    cpu.status.value = 0

    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BCC)

    print("debug: perform BCC")
    // decode OP - fetch offset
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BCC)
    XCTAssertEqual(pins.data.value, offset)

    // Branch - calculate new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Branch - adjust for page crossing
    TestHelper.cycle(cpu, pins: pins, mem: memory)

    // Read instruction at new location
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, target)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
