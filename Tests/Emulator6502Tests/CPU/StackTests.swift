import XCTest
import Foundation
@testable import Emulator6502

final class StackTests: XCTestCase {
  func testPha() {
    print("debug: testPha")
    let pins = Pins()
    let testValue:UInt8 = 0x24
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.PHA
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    cpu.a.value = testValue // Set the accumulator
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PHA)
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    // Ensure stack top starts blank
    XCTAssertEqual(memory[stackTopAddr], 0x00)

    print("debug: perform PHA")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PHA)

    // Writing to stack - SP should be decremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Decode NOP - stack should contain A
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[stackTopAddr], testValue)
  }

  func testPlaPositive() {
    print("debug: testPlaPositive")
    let pins = Pins()
    let testValue:UInt8 = 0x24
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.PLA
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    memory[stackTopAddr] = testValue
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP&-1 // Ensure stack pointer setup
    cpu.a.value = 0x00 // Ensure accumulator is clear
    cpu.status.value = Status6502.ZERO | Status6502.NEGATIVE // set zero and negative flags
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PLA)

    print("debug: perform PLA")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PLA)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Load from current stack pointer
    // Stack pointer should be incremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP)

    // Load from new stack pointer
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)

    // Decode NOP - A should contain value
    // Zero and negative flags should be clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue)
    XCTAssertFalse(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
  }

  func testPlaNegative() {
    print("debug: testPlaNegative")
    let pins = Pins()
    let testValue:UInt8 = 0xd4 // Negative value
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.PLA
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    memory[stackTopAddr] = testValue
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP&-1 // Ensure stack pointer setup
    cpu.a.value = 0x00 // Ensure accumulator is clear
    cpu.status.value = Status6502.ZERO // set zero and clear negative flags
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PLA)

    print("debug: perform PLA")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PLA)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Load from current stack pointer
    // Stack pointer should be incremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP)

    // Load from new stack pointer
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)

    // Decode NOP - A should contain value
    // Negative flag should be set, zero clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue)
    XCTAssert(cpu.status.negative)
    XCTAssertFalse(cpu.status.zero)
  }

  func testPlaZero() {
    print("debug: testPlaZero")
    let pins = Pins()
    let testValue:UInt8 = 0x00
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.PLA
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    memory[stackTopAddr] = testValue
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP&-1 // Ensure stack pointer setup
    cpu.a.value = 0x24 // Ensure accumulator is set to something
    cpu.status.value = Status6502.NEGATIVE // clear zero and set negative flags
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PLA)

    print("debug: perform PLA")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PLA)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Load from current stack pointer
    // Stack pointer should be incremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP)

    // Load from new stack pointer
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)

    // Decode NOP - A should contain 0
    // Zero flag should be set, negative clear
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.a.value, testValue)
    XCTAssert(cpu.status.zero)
    XCTAssertFalse(cpu.status.negative)
  }

  func testPhp() {
    print("debug: testPhp")
    let pins = Pins()
    let testValue:UInt8 = 0x24
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    memory[TestHelper.RES_ADDR] = TestHelper.PHP
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    cpu.status.value = testValue // Set the status
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PHP)
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    // Ensure stack top starts blank
    XCTAssertEqual(memory[stackTopAddr], 0x00)

    print("debug: perform PHP")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PHP)

    // Writing to stack - SP should be decremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Decode NOP - stack should contain P
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(memory[stackTopAddr], testValue)
  }

  func testPlp() {
    print("debug: testPlp")
    let pins = Pins()
    let testValue:UInt8 = 0x24
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is op
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    memory[TestHelper.RES_ADDR] = TestHelper.PLP
    memory[TestHelper.RES_ADDR&+1] = TestHelper.NOP
    memory[stackTopAddr] = testValue
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP&-1 // Ensure stack pointer setup
    cpu.status.value = 0x00 // Ensure status is clear
    // Next instruction should be op at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.PLP)

    print("debug: perform PLP")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.PLP)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-1)

    // Load from current stack pointer
    // Stack pointer should be incremented
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP)

    // Load from new stack pointer
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)
    XCTAssertEqual(pins.data.value, testValue)

    // Decode NOP - P should contain value
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.status.value, testValue)
  }
}
