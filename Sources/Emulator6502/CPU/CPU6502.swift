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
    case .I_SBC:
      (a.value, status.carry, status.overflow) = a.adc(~data.value, carryIn: status.carry)
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
    [ // 01 ORA (ZP,X)
      []
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
    [ // 05 ORA ZP
      []
    ],
    [ // 06 ASL ZP
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
    [ // 09 ORA Imm
      []
    ],
    [ // 0a ASL
      []
    ],
    [ // 0b
      []
    ],
    [ // 0c
      []
    ],
    [ // 0d ORA Abs
      []
    ],
    [ // 0e ASL Abs
      []
    ],
    [ // 0f
      []
    ],
    [ // 10 BPL
      []
    ],
    [ // 11 ORA (ZP),Y
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
    [ // 15 ORA ZP,X
      []
    ],
    [ // 16 ASL ZP,X
      []
    ],
    [ // 17
      []
    ],
    [ // 18 CLC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear carry, Next OP
    ],
    [ // 19 ORA Abs,Y
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
    [ // 1d ORA Abs,X
      []
    ],
    [ // 1e ASL Abs,X
      []
    ],
    [ // 1f
      []
    ],
    [ // 20 JSR
      []
    ],
    [ // 21 AND (ZP,X)
      []
    ],
    [ // 22
      []
    ],
    [ // 23
      []
    ],
    [ // 24 BIT ZP
      []
    ],
    [ // 25 AND ZP
      []
    ],
    [ // 26 ROL ZP
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
    [ // 29 AND Imm
      []
    ],
    [ // 2a ROL
      []
    ],
    [ // 2b
      []
    ],
    [ // 2c BIT Abs
      []
    ],
    [ // 2d AND Abs
      []
    ],
    [ // 2e ROL Abs
      []
    ],
    [ // 2f
      []
    ],
    [ // 30 BMI
      []
    ],
    [ // 31 AND (ZP),Y
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
    [ // 35 AND ZP,X
      []
    ],
    [ // 36 ROL ZP,X
      []
    ],
    [ // 37
      []
    ],
    [ // 38 SEC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SEC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set carry, Next OP
    ],
    [ // 39 AND Abs,Y
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
    [ // 3d AND Abs,X
      []
    ],
    [ // 3e ROL Abs,X
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
    [ // 41 EOR (ZP,X)
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
    [ // 45 EOR ZP
      []
    ],
    [ // 46 LSR ZP
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
    [ // 49 EOR Imm
      []
    ],
    [ // 4a LSR
      []
    ],
    [ // 4b
      []
    ],
    [ // 4c JMP Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for PCL)
      [.I_PC_to_ADDR_B, .I_DATA_to_PCL], // Read PC (for PCH)
      [.I_DATA_to_PCH, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 4d EOR Abs
      []
    ],
    [ // 4e LSR Abs
      []
    ],
    [ // 4f
      []
    ],
    [ // 50 BVC
      []
    ],
    [ // 51 EOR (ZP),Y
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
    [ // 55 EOR ZP,X
      []
    ],
    [ // 56 LSR ZP,X
      []
    ],
    [ // 57
      []
    ],
    [ // 58 CLI
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLI, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear interrupt, Next OP
    ],
    [ // 59 EOR Abs,Y
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
    [ // 5d EOR Abs,X
      []
    ],
    [ // 5e LSR Abs,X
      []
    ],
    [ // 5f
      []
    ],
    [ // 60 RTS
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
    [ // 66 ROR ZP
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
    [ // 6a ROR
      []
    ],
    [ // 6b
      []
    ],
    [ // 6c JMP (Abs)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B], // Read PC (for IAH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read AD (for PCL), Incr AD
      [.I_DATA_to_PCL, .I_AD_to_ADDR_B], // Read AD (for PCH)
      [.I_DATA_to_PCH, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 6d ADC Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_ADC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
    ],
    [ // 6e ROR Abs
      []
    ],
    [ // 6f
      []
    ],
    [ // 70 BVS
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
    [ // 76 ROR ZP,X
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
    [ // 7e ROR Abs,X
      []
    ],
    [ // 7f
      []
    ],
    [ // 80
      []
    ],
    [ // 81 STA (ZP,X)
      []
    ],
    [ // 82
      []
    ],
    [ // 83
      []
    ],
    [ // 84 STY ZP
      []
    ],
    [ // 85 STA ZP
      []
    ],
    [ // 86 STX ZP
      []
    ],
    [ // 87
      []
    ],
    [ // 88 DEY
      []
    ],
    [ // 89
      []
    ],
    [ // 8a TXA
      []
    ],
    [ // 8b
      []
    ],
    [ // 8c STY Abs
      []
    ],
    [ // 8d STA Abs
      []
    ],
    [ // 8e STX Abs
      []
    ],
    [ // 8f
      []
    ],
    [ // 90 BCC
      []
    ],
    [ // 91 STA (ZP),Y
      []
    ],
    [ // 92
      []
    ],
    [ // 93
      []
    ],
    [ // 94 STY ZP,X
      []
    ],
    [ // 95 STA ZP,X
      []
    ],
    [ // 96 STX ZP,Y
      []
    ],
    [ // 97
      []
    ],
    [ // 98 TYA
      []
    ],
    [ // 99 STA Abs,Y
      []
    ],
    [ // 9a TSX
      []
    ],
    [ // 9b
      []
    ],
    [ // 9c
      []
    ],
    [ // 9d STA Abs,X
      []
    ],
    [ // 9e
      []
    ],
    [ // 9f
      []
    ],
    [ // a0 LDY Imm
      []
    ],
    [ // a1 LDA (ZP,X)
      []
    ],
    [ // a2 LDX Imm
      []
    ],
    [ // a3
      []
    ],
    [ // a4 LDY ZP
      []
    ],
    [ // a5 LDA ZP
      []
    ],
    [ // a6 LDX ZP
      []
    ],
    [ // a7
      []
    ],
    [ // a8 TAY
      []
    ],
    [ // a9 LDA Imm
      []
    ],
    [ // aa TAX
      []
    ],
    [ // ab
      []
    ],
    [ // ac LDY Abs
      []
    ],
    [ // ad LDA Abs
      []
    ],
    [ // ae LDX Abs
      []
    ],
    [ // af
      []
    ],
    [ // b0 BCS
      []
    ],
    [ // b1 LDA (ZP),Y
      []
    ],
    [ // b2
      []
    ],
    [ // b3
      []
    ],
    [ // b4 LDY ZP,X
      []
    ],
    [ // b5 LDA ZP,X
      []
    ],
    [ // b6 LDX ZP,Y
      []
    ],
    [ // b7
      []
    ],
    [ // b8 CLV
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLV, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear overflow, Next OP
    ],
    [ // b9 LDA Abs,Y
      []
    ],
    [ // ba TSX
      []
    ],
    [ // bb
      []
    ],
    [ // bc LDY Abs,X
      []
    ],
    [ // bd LDA Abs,X
      []
    ],
    [ // be LDX Abs,Y
      []
    ],
    [ // bf
      []
    ],
    [ // c0 CPY Imm
      []
    ],
    [ // c1 CMP (ZP,X)
      []
    ],
    [ // c2
      []
    ],
    [ // c3
      []
    ],
    [ // c4 CPY ZP
      []
    ],
    [ // c5 CMP ZP
      []
    ],
    [ // c6 DEC ZP
      []
    ],
    [ // c7
      []
    ],
    [ // c8 INY
      []
    ],
    [ // c9 CMP Imm
      []
    ],
    [ // ca DEX
      []
    ],
    [ // cb
      []
    ],
    [ // cc CPY Abs
      []
    ],
    [ // cd CMP Abs
      []
    ],
    [ // ce DEC Abs
      []
    ],
    [ // cf
      []
    ],
    [ // d0 BNE
      []
    ],
    [ // d1 CMP (ZP),Y
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
    [ // d5 CMP ZP,X
      []
    ],
    [ // d6 DEC ZP,X
      []
    ],
    [ // d7
      []
    ],
    [ // d8 CLD
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLD, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear decimal, Next OP
    ],
    [ // d9 CMP Abs,Y
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
    [ // dd CMP Abs,X
      []
    ],
    [ // de DEC Abs,X
      []
    ],
    [ // df
      []
    ],
    [ // e0 CPX Imm
      []
    ],
    [ // e1 SBC (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
    ],
    [ // e2
      []
    ],
    [ // e3
      []
    ],
    [ // e4 CPX ZP
      []
    ],
    [ // e5 SBC ZP
      []
    ],
    [ // e6 INC ZP
      []
    ],
    [ // e7
      []
    ],
    [ // e8 INX
      []
    ],
    [ // e9 SBC Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
    ],
    [ // ea NOP
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // eb
      []
    ],
    [ // ec CPX Abs
      []
    ],
    [ // ed SBC Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
    ],
    [ // ee INC Abs
      []
    ],
    [ // ef
      []
    ],
    [ // f0 BEQ
      []
    ],
    [ // f1 SBC (ZP),Y
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
    [ // f5 SBC ZP,X
      []
    ],
    [ // f6 INC ZP,X
      []
    ],
    [ // f7
      []
    ],
    [ // f8 SED
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SED, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set decimal, Next OP
    ],
    [ // f9 SBC Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
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
    [ // fd SBC Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
    ],
    [ // fe INC Abs,X
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
