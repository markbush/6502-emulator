import XCTest
import Foundation
@testable import Emulator6502

final class InterruptsTests: XCTestCase {
  func testStartup() throws {
    print("debug: testStartup")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is NOP
    memory[TestHelper.RES_ADDR] = TestHelper.NOP
    pins.data.value = TestHelper.ORAInd // preload data bus with junk
    let cpu = CPU6502(pins)
    cpu.reset()

    XCTAssert(pins.read.isHigh())

    // IR should be forced to a BRK
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BRK)
    XCTAssert(pins.read.isHigh())

    // Pushing PCH - no write
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.high, 0x01)
    let spTop = pins.address.low
    XCTAssert(pins.read.isHigh())

    // Pushing PCL - no write
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.high, 0x01)
    XCTAssertEqual(pins.address.low, spTop&-1)
    XCTAssert(pins.read.isHigh())

    // Pushing Status - no write
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.high, 0x01)
    XCTAssertEqual(pins.address.low, spTop&-2)
    XCTAssert(pins.read.isHigh())
    XCTAssert(cpu.status.brk) // Break flag should be set on startup

    // Fetch of Reset low
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_VEC_LOW)
    XCTAssert(pins.read.isHigh())

    // Fetch of Reset high
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_VEC_HIGH)
    XCTAssert(pins.read.isHigh())

    // Reset vector - fetch first instruction and increment PC
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(cpu.pc.value, TestHelper.RES_ADDR&+1)
    XCTAssert(pins.read.isHigh())

    // Read first instruction
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }

  func testBreak() throws {
    print("debug: testBreak")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is BRK
    memory[TestHelper.RES_ADDR] = TestHelper.BRK
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    let status = cpu.status.value

    print("debug: break")
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BRK)

    // Pushing PCH - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_HIGH)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing PCL+2 - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-1)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_LOW&+2)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing Status
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-2)|0x0100)
    XCTAssertEqual(pins.data.value, status)
    XCTAssertFalse(pins.read.isHigh())
    XCTAssert(cpu.status.brk) // BRK flag should be set

    // Fetch of IRQ low
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_VEC_LOW)
    XCTAssert(pins.read.isHigh())

    // Fetch of IRQ high
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_VEC_HIGH)
    XCTAssert(pins.read.isHigh())

    // IRQ vector - fetch instruction and increment PC
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_ADDR)
    XCTAssertEqual(cpu.pc.value, TestHelper.IRQ_ADDR&+1)
    XCTAssert(pins.read.isHigh())
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-3)
  }

  func testNmiWithInterruptsEnabled() throws {
    print("debug: testNmiWithInterruptsEnabled")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is NOP
    memory[TestHelper.RES_ADDR] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    // Pull NMI low
    pins.nmi.value = false
    cpu.status.interrupt = false // Enable IRQ

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    let status = cpu.status.value

    print("debug: NMI")
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BRK) // Should force a BRK

    // Pushing PCH - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_HIGH)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing PCL - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-1)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_LOW)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing Status
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-2)|0x0100)
    XCTAssertEqual(pins.data.value, status)
    XCTAssertFalse(pins.read.isHigh())

    // Fetch of NMI low
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_VEC_LOW)
    XCTAssert(pins.read.isHigh())

    // Fetch of NMI high
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_VEC_HIGH)
    XCTAssert(pins.read.isHigh())

    // NMI vector - fetch instruction and increment PC
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_ADDR)
    XCTAssertEqual(cpu.pc.value, TestHelper.NMI_ADDR&+1)
    XCTAssert(pins.read.isHigh())
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-3)
  }

  func testNmiWithInterruptsDisabled() throws {
    print("debug: testNmiWithInterruptsDisabled")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is NOP
    memory[TestHelper.RES_ADDR] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    // Pull NMI low
    pins.nmi.value = false
    cpu.status.interrupt = true // Disable IRQ - should still interrupt

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    let status = cpu.status.value

    print("debug: NMI interrupts disabled")
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BRK) // Should force a BRK

    // Pushing PCH - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_HIGH)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing PCL - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-1)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_LOW)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing Status
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-2)|0x0100)
    XCTAssertEqual(pins.data.value, status)
    XCTAssertFalse(pins.read.isHigh())

    // Fetch of NMI low
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_VEC_LOW)
    XCTAssert(pins.read.isHigh())

    // Fetch of NMI high
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_VEC_HIGH)
    XCTAssert(pins.read.isHigh())

    // NMI vector - fetch instruction and increment PC
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.NMI_ADDR)
    XCTAssertEqual(cpu.pc.value, TestHelper.NMI_ADDR&+1)
    XCTAssert(pins.read.isHigh())
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-3)
  }

  func testIrqWithInterruptsEnabled() throws {
    print("debug: testIrqWithInterruptsEnabled")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is NOP
    memory[TestHelper.RES_ADDR] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    // Pull IRQ low
    pins.irq.value = false
    cpu.status.interrupt = false // Enable IRQ

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup

    print("debug: IRQ")
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.BRK) // Should force a BRK

    // Pushing PCH - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_HIGH)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing PCL - currently reset vector
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-1)|0x0100)
    XCTAssertEqual(pins.data.value, TestHelper.RES_ADDR_LOW)
    XCTAssertFalse(pins.read.isHigh())

    // Pushing Status
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, UInt16(TestHelper.STACK_TOP&-2)|0x0100)
    XCTAssertEqual(pins.data.value, UInt8(0x00)) // Break should be cleared
    XCTAssertFalse(pins.read.isHigh())
    XCTAssertFalse(cpu.status.brk) // BRK flag should not be set for IRQ

    // Fetch of IRQ low
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_VEC_LOW)
    XCTAssert(pins.read.isHigh())

    // Fetch of IRQ high
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_VEC_HIGH)
    XCTAssert(pins.read.isHigh())

    // NMI vector - fetch instruction and increment PC
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_ADDR)
    XCTAssertEqual(cpu.pc.value, TestHelper.IRQ_ADDR&+1)
    XCTAssert(pins.read.isHigh())
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-3)
  }

  func testIrqWithInterruptsDisabled() throws {
    print("debug: testIrqWithInterruptsDisabled")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is NOP
    memory[TestHelper.RES_ADDR] = TestHelper.NOP
    let cpu = CPU6502(pins)
    cpu.reset()

    // Pull IRQ low
    pins.irq.value = false
    cpu.status.interrupt = true // Disable IRQ

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup

    print("debug: IRQ interrupts disabled")
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP) // Should ignore BRK
  }

  func testRti() throws {
    print("debug: testRti")
    let pins = Pins()
    let memory = TestHelper.initMemory(pins)
    // First OP after reset is BRK
    memory[TestHelper.RES_ADDR] = TestHelper.BRK
    memory[TestHelper.RES_ADDR&+1] = TestHelper.BRK // Should be ignored
    memory[TestHelper.RES_ADDR&+2] = TestHelper.NOP
    // At IRQ, just return
    memory[TestHelper.IRQ_ADDR] = TestHelper.RTI
    let cpu = CPU6502(pins)
    cpu.reset()

    TestHelper.startupSequence(cpu: cpu, pins: pins, mem: memory)
    cpu.sp.value = TestHelper.STACK_TOP // Ensure stack pointer setup
    // Next instruction should be BRK at RESET address
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.BRK)

    print("debug: RTI perform BRK")
    // Allow BRK to occur
    TestHelper.run(cpu, pins: pins, mem: memory, forCycles: 7)
    // Stack should contain 3 items: PCH, PCL, and P
    // PC should be 2 after location of BRK! (RES_ADDR&+2)
    XCTAssertEqual(cpu.sp.value, TestHelper.STACK_TOP&-3)
    let stackTopAddr = UInt16(0x0100) | UInt16(TestHelper.STACK_TOP)
    // PCH was first
    XCTAssertEqual(memory[stackTopAddr], UInt8((TestHelper.RES_ADDR&+2) >> 8))
    // Then PCL
    XCTAssertEqual(memory[stackTopAddr&-1], UInt8((TestHelper.RES_ADDR&+2) & 0xff))
    // Then status which should have the break flag set
    let savedP = memory[stackTopAddr&-2]
    XCTAssertEqual(savedP & 0x10, 0x10)
    // Should now be at IRQ address ready to perform RTI
    XCTAssertEqual(pins.address.value, TestHelper.IRQ_ADDR)
    XCTAssertEqual(pins.data.value, TestHelper.RTI)

    print("debug: perform RTI")
    // decode OP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.RTI)

    // read from existing SP - discarded
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-3)

    // read P
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-2)
    XCTAssertEqual(pins.data.value, savedP)

    // read PCL - P should now be set
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr&-1)
    XCTAssertEqual(cpu.status.value, savedP)

    // read PCH
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, stackTopAddr)

    // Next OP - should be at NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(pins.address.value, TestHelper.RES_ADDR&+2)
    XCTAssertEqual(pins.data.value, TestHelper.NOP)
    // PC ready to read next location
    XCTAssertEqual(cpu.pc.value, TestHelper.RES_ADDR&+3)

    // Decode NOP
    TestHelper.cycle(cpu, pins: pins, mem: memory)
    XCTAssertEqual(cpu.ir.value, TestHelper.NOP)
  }
}
