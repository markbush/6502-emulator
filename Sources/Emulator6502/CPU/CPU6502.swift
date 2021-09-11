import Foundation

class CPU6502 : Chip {
  let a = Register8()
  let x = Register8()
  let y = Register8()
  let sp = Register8()
  let pc = Register16()
  let status = Status6502()
  let ir = Register8() // Instruction Register
  let ad = Register16() // Internal address register
  let adh:Register8
  let adl:Register8
  let data = Register8() // Internal data register

  var instructionCycle = 0
  var interruptType: InterruptType = .reset
  var addressCarry = false

  let pins: Pins

  init(_ pins: Pins) {
    self.pins = pins
    adh = ad.highLines
    adl = ad.lowLines
  }

  func tick() -> Void {
    if pins.ready.isLow() || pins.reset.isLow() {
      return // Halted
    }
    if pins.read.isHigh() { // End of read cycle
      data.value = pins.data.value
    }
    if pins.sync.isHigh() && (interruptType != .reset) {
      nextOp()
    }
    pins.read.set() // Each cycle defaults to a read
    let instructions = CPU6502.InstructionDecode[Int(ir.value)][instructionCycle]
    for instruction in instructions {
      perform(instruction)
    }
    if pins.read.isLow() { // Write cycle
      pins.data.value = data.value
    }
    logStatus()
    instructionCycle += 1
    if pins.sync.isHigh() && (interruptType == .reset) {
      interruptType = .brk
    }
  }

  func reset() {
    pins.reset.set() // Reset conditoin is cleared
    pins.read.set() // Ensure no data is written out during startup
    status.decimal = false
    status.brk = true
    ir.value = 0x00 // BRK
    interruptType = .reset
    pins.sync.clear() // Not fetching an operation during reset
    perform(.I_PC_to_ADDR_B)
    perform(.I_PC_INCR)
    logStatus()
  }

  func nextOp() {
    pins.sync.clear()
    instructionCycle = 0
    ir.value = data.value
    if ir.value == 0x00 {
      status.brk = true
    }
    interruptType = .brk
    checkForInterrupt()
  }

  func checkForInterrupt() {
    if pins.nmi.isLow() || (pins.irq.isLow() && !status.interrupt) {
      // Force interrupt
      ir.value = 0x00
      pc.decr() // Undo PC increment when OP was read to enable reading again
      pc.decr() // Not correct behaviour, but saves check on every PC incr
      if pins.nmi.isLow() {
        interruptType = .nmi
        pins.nmi.set() // Ensure we don't continue to interrupt
      } else if pins.irq.isLow() {
        interruptType = .irq
        status.brk = false
      }
    }
  }

  func checkNZ(_ register: Register8) {
    status.zero = (register.value == 0)
    status.negative = register[7]
  }

  func perform(_ instruction:CPU6502Instruction) {
    switch instruction {
      // Flags / interrupt
    case .I_NEXT_OP: pins.sync.set()
    case .I_PC_INCR: pc.incr()
    case .I_SP_INCR: sp.incr()
    case .I_SP_DECR: sp.decr()
    case .I_WRITE: pins.read.value = (interruptType == .reset) // write except when resetting
    case .I_INTL_to_ADDR_B:
      switch interruptType {
      case .nmi: pins.address.value = 0xfffa
      case .reset: pins.address.value = 0xfffc
      case .irq, .brk: pins.address.value = 0xfffe
      }
    case .I_INTH_to_ADDR_B:
      switch interruptType {
      case .nmi: pins.address.value = 0xfffb
      case .reset: pins.address.value = 0xfffd
      case .irq, .brk: pins.address.value = 0xffff
      }
    case .I_CLC: status.carry = false
    case .I_CLD: status.decimal = false
    case .I_CLI: status.interrupt = false
    case .I_CLV: status.overflow = false
    case .I_SEC: status.carry = true
    case .I_SED: status.decimal = true
    case .I_SEI: status.interrupt = true
    case .I_BRK_SEI: if (interruptType == .irq || interruptType == .brk) { status.interrupt = true }
      // Address bus
    case .I_AD_to_ADDR_B: pins.address.load(from: ad)
    case .I_PC_to_ADDR_B: pins.address.load(from: pc)
    case .I_ADDR_B_to_PC: pc.load(from: pins.address)
    case .I_SP_to_ADDR_B: pins.address.high = 0x01 ; pins.address.low = sp.value
      // Data register
    case .I_PCH_to_DATA: data.value = pc.high
    case .I_PCL_to_DATA: data.value = pc.low
    case .I_P_to_DATA: data.value = status.value
    case .I_A_to_DATA: data.value = a.value
    case .I_DATA_to_PCH: pc.high = data.value
    case .I_DATA_to_PCL: pc.low = data.value
    case .I_DATA_to_ADH: adh.value = data.value
    case .I_DATA_to_ADL: adl.value = data.value ; adh.value = 0x00
    case .I_DATA_to_P: status.value = data.value
    case .I_DATA_to_A: a.value = data.value ; checkNZ(a)
      // Arithmetic
    case .I_ADC:
      (a.value, status.carry, status.overflow) = a.adc(data.value, carryIn: status.carry)
      checkNZ(a)
    case .I_ADL_plus_X:
      (adl.value, addressCarry, _) = adl.adc(x.value, carryIn: false)
    case .I_ADL_plus_Y:
      (adl.value, addressCarry, _) = adl.adc(y.value, carryIn: false)
    case .I_ADL_INCR: adl.incr()
    case .I_ADH_INCR: adh.incr()
    case .I_CHK_carry:
      if (!addressCarry) {
        instructionCycle += 1
      }
    }
  }

  static let InstructionDecode:[[[CPU6502Instruction]]] = [
    [ // 00 BRK
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Arg - discard
      [.I_SP_to_ADDR_B, .I_PCH_to_DATA, .I_WRITE, .I_SP_DECR], // Push PCH
      [.I_SP_to_ADDR_B, .I_PCL_to_DATA, .I_WRITE, .I_SP_DECR], // Push PCL
      [.I_SP_to_ADDR_B, .I_P_to_DATA,   .I_WRITE, .I_SP_DECR], // Push P
      [.I_BRK_SEI, .I_INTL_to_ADDR_B], // Disable interrupts (IRQ/BRK only), low byte of interrupt vector
      [.I_DATA_to_PCL, .I_INTH_to_ADDR_B], // Load PCL, high byte of interrupt vector
      [.I_DATA_to_PCH, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR], // Load PCH, Next OP
    ],
    [ // 01
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR], // Next OP
    ],
    [ // 02
      []
    ],
    [ // 03
      []
    ],
    [ // 04
      []
    ],
    [ // 05
      []
    ],
    [ // 06
      []
    ],
    [ // 07
      []
    ],
    [ // 08 PHP
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_P_to_DATA,   .I_WRITE, .I_SP_DECR], // Write P to stack
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 09
      []
    ],
    [ // 0a
      []
    ],
    [ // 0b
      []
    ],
    [ // 0c
      []
    ],
    [ // 0d
      []
    ],
    [ // 0e
      []
    ],
    [ // 0f
      []
    ],
    [ // 10
      []
    ],
    [ // 11
      []
    ],
    [ // 12
      []
    ],
    [ // 13
      []
    ],
    [ // 14
      []
    ],
    [ // 15
      []
    ],
    [ // 16
      []
    ],
    [ // 17
      []
    ],
    [ // 18 CLC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear carry, Next OP
    ],
    [ // 19
      []
    ],
    [ // 1a
      []
    ],
    [ // 1b
      []
    ],
    [ // 1c
      []
    ],
    [ // 1d
      []
    ],
    [ // 1e
      []
    ],
    [ // 1f
      []
    ],
    [ // 20
      []
    ],
    [ // 21
      []
    ],
    [ // 22
      []
    ],
    [ // 23
      []
    ],
    [ // 24
      []
    ],
    [ // 25
      []
    ],
    [ // 26
      []
    ],
    [ // 27
      []
    ],
    [ // 28 PLP
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_SP_INCR], // Read SP
      [.I_SP_to_ADDR_B, .I_SP_to_ADDR_B], // Discard, Read SP
      [.I_DATA_to_P, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load P, Next OP
    ],
    [ // 29
      []
    ],
    [ // 2a
      []
    ],
    [ // 2b
      []
    ],
    [ // 2c
      []
    ],
    [ // 2d
      []
    ],
    [ // 2e
      []
    ],
    [ // 2f
      []
    ],
    [ // 30
      []
    ],
    [ // 31
      []
    ],
    [ // 32
      []
    ],
    [ // 33
      []
    ],
    [ // 34
      []
    ],
    [ // 35
      []
    ],
    [ // 36
      []
    ],
    [ // 37
      []
    ],
    [ // 38 SEC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SEC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set carry, Next OP
    ],
    [ // 39
      []
    ],
    [ // 3a
      []
    ],
    [ // 3b
      []
    ],
    [ // 3c
      []
    ],
    [ // 3d
      []
    ],
    [ // 3e
      []
    ],
    [ // 3f
      []
    ],
    [ // 40 RTI
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Arg - discard
      [.I_SP_to_ADDR_B, .I_SP_INCR], // Read SP
      [.I_SP_to_ADDR_B, .I_SP_INCR], // Discard, Read SP
      [.I_DATA_to_P, .I_SP_to_ADDR_B, .I_SP_INCR], // Load P, Read SP
      [.I_DATA_to_PCL, .I_SP_to_ADDR_B], // Load PCL, Read SP
      [.I_DATA_to_PCH, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load PCH, Next OP
    ],
    [ // 41
      []
    ],
    [ // 42
      []
    ],
    [ // 43
      []
    ],
    [ // 44
      []
    ],
    [ // 45
      []
    ],
    [ // 46
      []
    ],
    [ // 47
      []
    ],
    [ // 48 PHA
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_A_to_DATA,   .I_WRITE, .I_SP_DECR], // Write A to stack
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 49
      []
    ],
    [ // 4a
      []
    ],
    [ // 4b
      []
    ],
    [ // 4c
      []
    ],
    [ // 4d
      []
    ],
    [ // 4e
      []
    ],
    [ // 4f
      []
    ],
    [ // 50
      []
    ],
    [ // 51
      []
    ],
    [ // 52
      []
    ],
    [ // 53
      []
    ],
    [ // 54
      []
    ],
    [ // 55
      []
    ],
    [ // 56
      []
    ],
    [ // 57
      []
    ],
    [ // 58 CLI
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLI, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear interrupt, Next OP
    ],
    [ // 59
      []
    ],
    [ // 5a
      []
    ],
    [ // 5b
      []
    ],
    [ // 5c
      []
    ],
    [ // 5d
      []
    ],
    [ // 5e
      []
    ],
    [ // 5f
      []
    ],
    [ // 60
      []
    ],
    [ // 61 ADC (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 62
      []
    ],
    [ // 63
      []
    ],
    [ // 64
      []
    ],
    [ // 65 ADC ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 66
      []
    ],
    [ // 67
      []
    ],
    [ // 68 PLA
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_SP_INCR], // Read SP
      [.I_SP_to_ADDR_B, .I_SP_to_ADDR_B], // Discard, Read SP
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // 69 ADC Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 6a
      []
    ],
    [ // 6b
      []
    ],
    [ // 6c
      []
    ],
    [ // 6d ADC Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 6e
      []
    ],
    [ // 6f
      []
    ],
    [ // 70
      []
    ],
    [ // 71 ADC (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 72
      []
    ],
    [ // 73
      []
    ],
    [ // 74
      []
    ],
    [ // 75 ADC ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 76
      []
    ],
    [ // 77
      []
    ],
    [ // 78 SEI
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SEI, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set interrupt, Next OP
    ],
    [ // 79 ADC Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 7a
      []
    ],
    [ // 7b
      []
    ],
    [ // 7c
      []
    ],
    [ // 7d ADC Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 7e
      []
    ],
    [ // 7f
      []
    ],
    [ // 80
      []
    ],
    [ // 81
      []
    ],
    [ // 82
      []
    ],
    [ // 83
      []
    ],
    [ // 84
      []
    ],
    [ // 85
      []
    ],
    [ // 86
      []
    ],
    [ // 87
      []
    ],
    [ // 88
      []
    ],
    [ // 89
      []
    ],
    [ // 8a
      []
    ],
    [ // 8b
      []
    ],
    [ // 8c
      []
    ],
    [ // 8d
      []
    ],
    [ // 8e
      []
    ],
    [ // 8f
      []
    ],
    [ // 90
      []
    ],
    [ // 91
      []
    ],
    [ // 92
      []
    ],
    [ // 93
      []
    ],
    [ // 94
      []
    ],
    [ // 95
      []
    ],
    [ // 96
      []
    ],
    [ // 97
      []
    ],
    [ // 98
      []
    ],
    [ // 99
      []
    ],
    [ // 9a
      []
    ],
    [ // 9b
      []
    ],
    [ // 9c
      []
    ],
    [ // 9d
      []
    ],
    [ // 9e
      []
    ],
    [ // 9f
      []
    ],
    [ // a0
      []
    ],
    [ // a1
      []
    ],
    [ // a2
      []
    ],
    [ // a3
      []
    ],
    [ // a4
      []
    ],
    [ // a5
      []
    ],
    [ // a6
      []
    ],
    [ // a7
      []
    ],
    [ // a8
      []
    ],
    [ // a9
      []
    ],
    [ // aa
      []
    ],
    [ // ab
      []
    ],
    [ // ac
      []
    ],
    [ // ad
      []
    ],
    [ // ae
      []
    ],
    [ // af
      []
    ],
    [ // b0
      []
    ],
    [ // b1
      []
    ],
    [ // b2
      []
    ],
    [ // b3
      []
    ],
    [ // b4
      []
    ],
    [ // b5
      []
    ],
    [ // b6
      []
    ],
    [ // b7
      []
    ],
    [ // b8 CLV
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLV, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear overflow, Next OP
    ],
    [ // b9
      []
    ],
    [ // ba
      []
    ],
    [ // bb
      []
    ],
    [ // bc
      []
    ],
    [ // bd
      []
    ],
    [ // be
      []
    ],
    [ // bf
      []
    ],
    [ // c0
      []
    ],
    [ // c1
      []
    ],
    [ // c2
      []
    ],
    [ // c3
      []
    ],
    [ // c4
      []
    ],
    [ // c5
      []
    ],
    [ // c6
      []
    ],
    [ // c7
      []
    ],
    [ // c8
      []
    ],
    [ // c9
      []
    ],
    [ // ca
      []
    ],
    [ // cb
      []
    ],
    [ // cc
      []
    ],
    [ // cd
      []
    ],
    [ // ce
      []
    ],
    [ // cf
      []
    ],
    [ // d0
      []
    ],
    [ // d1
      []
    ],
    [ // d2
      []
    ],
    [ // d3
      []
    ],
    [ // d4
      []
    ],
    [ // d5
      []
    ],
    [ // d6
      []
    ],
    [ // d7
      []
    ],
    [ // d8 CLD
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLD, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear decimal, Next OP
    ],
    [ // d9
      []
    ],
    [ // da
      []
    ],
    [ // db
      []
    ],
    [ // dc
      []
    ],
    [ // dd
      []
    ],
    [ // de
      []
    ],
    [ // df
      []
    ],
    [ // e0
      []
    ],
    [ // e1
      []
    ],
    [ // e2
      []
    ],
    [ // e3
      []
    ],
    [ // e4
      []
    ],
    [ // e5
      []
    ],
    [ // e6
      []
    ],
    [ // e7
      []
    ],
    [ // e8
      []
    ],
    [ // e9
      []
    ],
    [ // ea NOP
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // eb
      []
    ],
    [ // ec
      []
    ],
    [ // ed
      []
    ],
    [ // ee
      []
    ],
    [ // ef
      []
    ],
    [ // f0
      []
    ],
    [ // f1
      []
    ],
    [ // f2
      []
    ],
    [ // f3
      []
    ],
    [ // f4
      []
    ],
    [ // f5
      []
    ],
    [ // f6
      []
    ],
    [ // f7
      []
    ],
    [ // f8 SED
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SED, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set decimal, Next OP
    ],
    [ // f9
      []
    ],
    [ // fa
      []
    ],
    [ // fb
      []
    ],
    [ // fc
      []
    ],
    [ // fd
      []
    ],
    [ // fe
      []
    ],
    [ // ff
      []
    ],
  ]

  func logStatus() {
    print(String(format:"debug: %04x %02x %@ IR: %02x P: %02x %d %@ A: %02x",
      pins.address.value,
      pins.data.value,
      (pins.read.isHigh() ? "R" : "W"),
      ir.value,
      status.value,
      instructionCycle,
      (pins.sync.isHigh() ? "H" : "L"),
      a.value))
  }
}
