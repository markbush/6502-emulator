import Foundation
@testable import Emulator6502

class TestHelper {
  static let BRK:UInt8 = 0x00
  static let ORAInd:UInt8 = 0x01
  static let PHP:UInt8 = 0x08
  static let CLC:UInt8 = 0x18
  static let PLP:UInt8 = 0x28
  static let SEC:UInt8 = 0x38
  static let RTI:UInt8 = 0x40
  static let PHA:UInt8 = 0x48
  static let JMP:UInt8 = 0x4c
  static let CLI:UInt8 = 0x58
  static let ADCZpIndX:UInt8 = 0x61
  static let ADCZp:UInt8 = 0x65
  static let PLA:UInt8 = 0x68
  static let ADCImm:UInt8 = 0x69
  static let ADCAbs:UInt8 = 0x6d
  static let ADCZpIndY:UInt8 = 0x71
  static let ADCZpX:UInt8 = 0x75
  static let SEI:UInt8 = 0x78
  static let ADCAbsY:UInt8 = 0x79
  static let ADCAbsX:UInt8 = 0x7d
  static let CLV:UInt8 = 0xb8
  static let DEX:UInt8 = 0xca
  static let CLD:UInt8 = 0xd8
  static let NOP:UInt8 = 0xea
  static let SED:UInt8 = 0xf8

  static let STACK_TOP:UInt8 = 0xff

  static let NMI_ADDR:UInt16 = 0x1c02
  static let RES_ADDR:UInt16 = 0x08a0
  static let IRQ_ADDR:UInt16 = 0x1780

  static let NMI_VEC_LOW:UInt16 = 0xfffa
  static let NMI_VEC_HIGH:UInt16 = 0xfffb
  static let RES_VEC_LOW:UInt16 = 0xfffc
  static let RES_VEC_HIGH:UInt16 = 0xfffd
  static let IRQ_VEC_LOW:UInt16 = 0xfffe
  static let IRQ_VEC_HIGH:UInt16 = 0xffff

  static let NMI_ADDR_LOW = UInt8(NMI_ADDR & 0xff) // NMI vector
  static let NMI_ADDR_HIGH = UInt8(NMI_ADDR >> 8)
  static let RES_ADDR_LOW = UInt8(RES_ADDR & 0xff) // Reset vector
  static let RES_ADDR_HIGH = UInt8(RES_ADDR >> 8)
  static let IRQ_ADDR_LOW = UInt8(IRQ_ADDR & 0xff) // IRQ/BRK vector
  static let IRQ_ADDR_HIGH = UInt8(IRQ_ADDR >> 8)

  static func initMemory(_ pins: Pins) -> Memory {
    let mem = Memory(pins)
    mem[NMI_VEC_LOW] = NMI_ADDR_LOW
    mem[NMI_VEC_HIGH] = NMI_ADDR_HIGH
    mem[RES_VEC_LOW] = RES_ADDR_LOW
    mem[RES_VEC_HIGH] = RES_ADDR_HIGH
    mem[IRQ_VEC_LOW] = IRQ_ADDR_LOW
    mem[IRQ_VEC_HIGH] = IRQ_ADDR_HIGH
    return mem
  }

  static func cycle(_ cpu: CPU6502, pins: Pins, mem: Memory) {
    cpu.tick()
    mem.tick()
  }

  static func run(_ cpu: CPU6502, pins: Pins, mem: Memory, forCycles cycles:Int) {
    for _ in 0..<cycles {
      cycle(cpu, pins: pins, mem: mem)
    }
  }

  static func startupSequence(cpu: CPU6502, pins: Pins, mem: Memory) {
    print("debug: startupSequence")
    // Startup sequence - 7 cycles
    run(cpu, pins: pins, mem: mem, forCycles: 7)
  }
}
