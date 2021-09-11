import Foundation
@testable import Emulator6502

class TestHelper {
  static let BRK:UInt8 = 0x00
  static let ORAZpIndX:UInt8 = 0x01
  static let ORAZp:UInt8 = 0x05
  static let ASLZp:UInt8 = 0x06
  static let PHP:UInt8 = 0x08
  static let ORAImm:UInt8 = 0x09
  static let ASL:UInt8 = 0x0a
  static let ORAAbs:UInt8 = 0x0d
  static let ASLAbs:UInt8 = 0x0e
  static let BPL:UInt8 = 0x10
  static let ORAZpIndY:UInt8 = 0x11
  static let ORAZpX:UInt8 = 0x15
  static let ASLZpX:UInt8 = 0x16
  static let CLC:UInt8 = 0x18
  static let ORAAbsY:UInt8 = 0x19
  static let ORAAbsX:UInt8 = 0x1d
  static let ASLAbsX:UInt8 = 0x1e
  static let JSR:UInt8 = 0x20
  static let ANDZpIndX:UInt8 = 0x21
  static let BITZp:UInt8 = 0x24
  static let ANDZp:UInt8 = 0x25
  static let ROLZp:UInt8 = 0x26
  static let PLP:UInt8 = 0x28
  static let ANDImm:UInt8 = 0x29
  static let ROL:UInt8 = 0x2a
  static let BITAbs:UInt8 = 0x2c
  static let ANDAbs:UInt8 = 0x2d
  static let ROLAbs:UInt8 = 0x2e
  static let BMI:UInt8 = 0x30
  static let ANDZpIndY:UInt8 = 0x31
  static let ANDZpX:UInt8 = 0x35
  static let ROLZpX:UInt8 = 0x36
  static let SEC:UInt8 = 0x38
  static let ANDAbsY:UInt8 = 0x39
  static let ANDAbsX:UInt8 = 0x3d
  static let ROLAbsX:UInt8 = 0x3e
  static let RTI:UInt8 = 0x40
  static let EORZpIndX:UInt8 = 0x41
  static let EORZp:UInt8 = 0x45
  static let LSRZp:UInt8 = 0x46
  static let PHA:UInt8 = 0x48
  static let EORImm:UInt8 = 0x49
  static let LSR:UInt8 = 0x4a
  static let JMP:UInt8 = 0x4c
  static let EORAbs:UInt8 = 0x4d
  static let LSRAbs:UInt8 = 0x4e
  static let BVC:UInt8 = 0x50
  static let EORZpIndY:UInt8 = 0x51
  static let EORZpX:UInt8 = 0x55
  static let LSRZpX:UInt8 = 0x56
  static let CLI:UInt8 = 0x58
  static let EORAbsY:UInt8 = 0x59
  static let EORAbsX:UInt8 = 0x5d
  static let LSRAbsX:UInt8 = 0x5e
  static let RTS:UInt8 = 0x60
  static let ADCZpIndX:UInt8 = 0x61
  static let ADCZp:UInt8 = 0x65
  static let RORZp:UInt8 = 0x66
  static let PLA:UInt8 = 0x68
  static let ADCImm:UInt8 = 0x69
  static let ROR:UInt8 = 0x6a
  static let JMPInd:UInt8 = 0x6c
  static let ADCAbs:UInt8 = 0x6d
  static let RORAbs:UInt8 = 0x6e
  static let BVS:UInt8 = 0x70
  static let ADCZpIndY:UInt8 = 0x71
  static let ADCZpX:UInt8 = 0x75
  static let RORZpX:UInt8 = 0x76
  static let SEI:UInt8 = 0x78
  static let ADCAbsY:UInt8 = 0x79
  static let ADCAbsX:UInt8 = 0x7d
  static let RORAbsX:UInt8 = 0x7e
  static let STAZpIndX:UInt8 = 0x81
  static let STYZp:UInt8 = 0x84
  static let STAZp:UInt8 = 0x85
  static let STXZp:UInt8 = 0x86
  static let DEY:UInt8 = 0x88
  static let TXA:UInt8 = 0x8a
  static let STYAbs:UInt8 = 0x8c
  static let STAAbs:UInt8 = 0x8d
  static let STXAbs:UInt8 = 0x8e
  static let BCC:UInt8 = 0x90
  static let STAZpIndY:UInt8 = 0x91
  static let STYZpX:UInt8 = 0x94
  static let STAZpX:UInt8 = 0x95
  static let STXZpY:UInt8 = 0x96
  static let TYA:UInt8 = 0x98
  static let STAAbsY:UInt8 = 0x99
  static let TXS:UInt8 = 0x9a
  static let STAAbsX:UInt8 = 0x9d
  static let LDYImm:UInt8 = 0xa0
  static let LDAZpIndX:UInt8 = 0xa1
  static let LDXImm:UInt8 = 0xa2
  static let LDYZp:UInt8 = 0xa4
  static let LDAZp:UInt8 = 0xa5
  static let LDXZp:UInt8 = 0xa6
  static let TAY:UInt8 = 0xa8
  static let LDAImm:UInt8 = 0xa9
  static let TAX:UInt8 = 0xaa
  static let LDYAbs:UInt8 = 0xac
  static let LDAAbs:UInt8 = 0xad
  static let LDXAbs:UInt8 = 0xae
  static let BCS:UInt8 = 0xb0
  static let LDAZpIndY:UInt8 = 0xb1
  static let LDYZpX:UInt8 = 0xb4
  static let LDAZpX:UInt8 = 0xb5
  static let LDXZpY:UInt8 = 0xb6
  static let CLV:UInt8 = 0xb8
  static let LDAAbsY:UInt8 = 0xb9
  static let TSX:UInt8 = 0xba
  static let LDYAbsX:UInt8 = 0xbc
  static let LDAAbsX:UInt8 = 0xbd
  static let LDXAbsY:UInt8 = 0xbe
  static let CPYImm:UInt8 = 0xc0
  static let CMPZpIndX:UInt8 = 0xc1
  static let CPYZp:UInt8 = 0xc4
  static let CMPZp:UInt8 = 0xc5
  static let DECZp:UInt8 = 0xc6
  static let INY:UInt8 = 0xc8
  static let CMPImm:UInt8 = 0xc9
  static let DEX:UInt8 = 0xca
  static let CPYAbs:UInt8 = 0xcc
  static let CMPAbs:UInt8 = 0xcd
  static let DECAbs:UInt8 = 0xce
  static let BNE:UInt8 = 0xd0
  static let CMPZpIndY:UInt8 = 0xd1
  static let CMPZpX:UInt8 = 0xd5
  static let DECZpX:UInt8 = 0xd6
  static let CLD:UInt8 = 0xd8
  static let CMPAbsY:UInt8 = 0xd9
  static let CMPAbsX:UInt8 = 0xdd
  static let DECAbsX:UInt8 = 0xde
  static let CPXImm:UInt8 = 0xe0
  static let SBCZpIndX:UInt8 = 0xe1
  static let CPXZp:UInt8 = 0xe4
  static let SBCZp:UInt8 = 0xe5
  static let INCZp:UInt8 = 0xe6
  static let INX:UInt8 = 0xe8
  static let SBCImm:UInt8 = 0xe9
  static let NOP:UInt8 = 0xea
  static let CPXAbs:UInt8 = 0xec
  static let SBCAbs:UInt8 = 0xed
  static let INCAbs:UInt8 = 0xee
  static let BEQ:UInt8 = 0xf0
  static let SBCZpIndY:UInt8 = 0xf1
  static let SBCZpX:UInt8 = 0xf5
  static let INCZpX:UInt8 = 0xf6
  static let SED:UInt8 = 0xf8
  static let SBCAbsY:UInt8 = 0xf9
  static let SBCAbsX:UInt8 = 0xfd
  static let INCAbsX:UInt8 = 0xfe

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
