import Foundation

class CPU6502 : Chip {
  var debug = false

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
    if debug {
      logStatus()
    }
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
    if debug {
      logStatus()
    }
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
    case .I_X_to_DATA: data.value = x.value
    case .I_Y_to_DATA: data.value = y.value
    case .I_DATA_to_PCH: pc.high = data.value
    case .I_DATA_to_PCL: pc.low = data.value
    case .I_DATA_to_ADH: adh.value = data.value
    case .I_DATA_to_ADL: adl.value = data.value ; adh.value = 0x00
    case .I_DATA_to_P: status.value = data.value
    case .I_DATA_to_A: a.value = data.value ; checkNZ(a)
    case .I_DATA_to_X: x.value = data.value ; checkNZ(x)
    case .I_DATA_to_Y: y.value = data.value ; checkNZ(y)
      // Arithmetic
    case .I_ADC:
      (a.value, status.carry, status.overflow, status.negative, status.zero) = a.adc(data.value, carryIn: status.carry)
    case .I_SBC:
      (a.value, status.carry, status.overflow, status.negative, status.zero) = a.adc(~data.value, carryIn: status.carry)
    case .I_AND:
      (a.value, status.negative, status.zero) = a.and(data.value)
    case .I_EOR:
      (a.value, status.negative, status.zero) = a.eor(data.value)
    case .I_ORA:
      (a.value, status.negative, status.zero) = a.or(data.value)
    case .I_CMP:
      (_, status.carry, _, status.negative, status.zero) = a.adc(~data.value, carryIn: true)
    case .I_ASL:
      (data.value, status.carry, status.negative, status.zero) = data.shiftLeft()
    case .I_LSR:
      (data.value, status.carry, status.negative, status.zero) = data.shiftRight()
    case .I_ROL:
      (data.value, status.carry, status.negative, status.zero) = data.rotateLeft(carryIn: status.carry)
    case .I_ROR:
      (data.value, status.carry, status.negative, status.zero) = data.rotateRight(carryIn: status.carry)
    case .I_ADL_plus_X:
      (adl.value, addressCarry, _, _, _) = adl.adc(x.value, carryIn: false)
    case .I_ADL_plus_Y:
      (adl.value, addressCarry, _, _, _) = adl.adc(y.value, carryIn: false)
    case .I_ADL_INCR: adl.incr()
    case .I_ADH_INCR: (adh.value, _, _, _, _) = adh.adc(0, carryIn: addressCarry) //adh.incr()
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
      [.I_SP_to_ADDR_B, .I_P_to_DATA, .I_WRITE, .I_SP_DECR], // Push P
      [.I_BRK_SEI, .I_INTL_to_ADDR_B], // Disable interrupts (IRQ/BRK only), low byte of interrupt vector
      [.I_DATA_to_PCL, .I_INTH_to_ADDR_B], // Load PCL, high byte of interrupt vector
      [.I_DATA_to_PCH, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR], // Load PCH, Next OP
    ],
    [ // 01 ORA (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
    ],
    [ // 06 ASL ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A left
      [.I_ASL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 07
      []
    ],
    [ // 08 PHP
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_P_to_DATA, .I_WRITE, .I_SP_DECR], // Write P to stack
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 09 ORA Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
    ],
    [ // 0a ASL
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_A_to_DATA, .I_ASL, .I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Shift A left, Next OP
    ],
    [ // 0b
      []
    ],
    [ // 0c
      []
    ],
    [ // 0d ORA Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
    ],
    [ // 0e ASL Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A left
      [.I_ASL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 0f
      []
    ],
    [ // 10 BPL
      []
    ],
    [ // 11 ORA (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
    ],
    [ // 16 ASL ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A left
      [.I_ASL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 17
      []
    ],
    [ // 18 CLC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear carry, Next OP
    ],
    [ // 19 ORA Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_ORA, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Or to A, Next OP
    ],
    [ // 1e ASL Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg - discarded
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A left
      [.I_ASL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 1f
      []
    ],
    [ // 20 JSR
      []
    ],
    [ // 21 AND (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
    ],
    [ // 26 ROL ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A left
      [.I_ROL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
    ],
    [ // 2a ROL
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_A_to_DATA, .I_ROL, .I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Rotate A left, Next OP
    ],
    [ // 2b
      []
    ],
    [ // 2c BIT Abs
      []
    ],
    [ // 2d AND Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
    ],
    [ // 2e ROL Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A left
      [.I_ROL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 2f
      []
    ],
    [ // 30 BMI
      []
    ],
    [ // 31 AND (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
    ],
    [ // 36 ROL ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A left
      [.I_ROL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 37
      []
    ],
    [ // 38 SEC
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SEC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Set carry, Next OP
    ],
    [ // 39 AND Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AND, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // And to A, Next OP
    ],
    [ // 3e ROL Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg - discarded
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A left
      [.I_ROL, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
    ],
    [ // 46 LSR ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A right
      [.I_LSR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 47
      []
    ],
    [ // 48 PHA
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_SP_to_ADDR_B, .I_A_to_DATA, .I_WRITE, .I_SP_DECR], // Write A to stack
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 49 EOR Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
    ],
    [ // 4a LSR
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_A_to_DATA, .I_LSR, .I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Shift A right, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
    ],
    [ // 4e LSR Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A right
      [.I_LSR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 4f
      []
    ],
    [ // 50 BVC
      []
    ],
    [ // 51 EOR (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
    ],
    [ // 56 LSR ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A right
      [.I_LSR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 57
      []
    ],
    [ // 58 CLI
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLI, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear interrupt, Next OP
    ],
    [ // 59 EOR Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_EOR, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Eor to A, Next OP
    ],
    [ // 5e LSR Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg - discarded
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A right
      [.I_LSR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A right
      [.I_ROR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_A_to_DATA, .I_ROR, .I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Rotate A right, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A right
      [.I_ROR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Shift A right
      [.I_LSR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg - discarded
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_AD_to_ADDR_B, .I_WRITE], // Rotate A right
      [.I_ROR, .I_AD_to_ADDR_B, .I_WRITE], // Write correct value
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 7f
      []
    ],
    [ // 80
      []
    ],
    [ // 81 STA (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Add to A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 86 STX ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_X_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write X
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 8e STX Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_X_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write X
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 8f
      []
    ],
    [ // 90 BCC
      []
    ],
    [ // 91 STA (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save BAH - discard
      [.I_ADH_INCR, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Adjust carry - write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Save ADL, ADL+X, unused read
      [.I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Unused read
      [.I_ADH_INCR, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Unused read
      [.I_ADH_INCR, .I_A_to_DATA, .I_AD_to_ADDR_B, .I_WRITE], // Write A
      [.I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Next OP
    ],
    [ // 9e
      []
    ],
    [ // 9f
      []
    ],
    [ // a0 LDY Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_DATA_to_Y, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load Y, Next OP
    ],
    [ // a1 LDA (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // a2 LDX Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_DATA_to_X, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load X, Next OP
    ],
    [ // a3
      []
    ],
    [ // a4 LDY ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_Y, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load Y, Next OP
    ],
    [ // a5 LDA ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // a6 LDX ZP
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_X, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load X, Next OP
    ],
    [ // a7
      []
    ],
    [ // a8 TAY
      []
    ],
    [ // a9 LDA Imm
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // aa TAX
      []
    ],
    [ // ab
      []
    ],
    [ // ac LDY Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_Y, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load Y, Next OP
    ],
    [ // ad LDA Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // ae LDX Abs
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_DATA_to_X, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load X, Next OP
    ],
    [ // af
      []
    ],
    [ // b0 BCS
      []
    ],
    [ // b1 LDA (ZP),Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // b2
      []
    ],
    [ // b3
      []
    ],
    [ // b4 LDY ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_Y, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load Y, Next OP
    ],
    [ // b5 LDA ZP,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // b6 LDX ZP,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_Y], // Read arg, ADL+Y
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_X, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load X, Next OP
    ],
    [ // b7
      []
    ],
    [ // b8 CLV
      [.I_PC_to_ADDR_B], // Arg - discard, suppress PC incr
      [.I_CLV, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Clear overflow, Next OP
    ],
    [ // b9 LDA Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // ba TSX
      []
    ],
    [ // bb
      []
    ],
    [ // bc LDY Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_Y, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load Y, Next OP
    ],
    [ // bd LDA Abs,X
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_A, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load A, Next OP
    ],
    [ // be LDX Abs,Y
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_DATA_to_X, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Load X, Next OP
    ],
    [ // bf
      []
    ],
    [ // c0 CPY Imm
      []
    ],
    [ // c1 CMP (ZP,X)
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for BAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read 00,BAL, do BAL=BAL+X
      [.I_AD_to_ADDR_B, .I_ADL_INCR], // Ignore 00,BAL, Read 00,BAL+X (ADL), BAL=BAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL], // Save ADL, Read 00,BAL+X+1 (ADH)
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Save ADH, Read ADH,ADL
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for Arg)
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH
      [.I_DATA_to_ADH, .I_AD_to_ADDR_B], // Read Arg
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_Y, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_ADL_plus_X, .I_PC_to_ADDR_B, .I_PC_INCR], // Read ADH, ADL+X
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read Arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_CMP, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Compare with A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B], // Read Arg
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for IAL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_INCR], // Read 00,IAL (for BAL), IAL=IAL+1
      [.I_AD_to_ADDR_B, .I_DATA_to_ADL, .I_ADL_plus_Y], // Read 00,IAL+1 (for BAH), save BAL+Y
      [.I_DATA_to_ADH, .I_CHK_carry, .I_AD_to_ADDR_B], // Read arg - discard if carry
      [.I_ADH_INCR, .I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
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
      [.I_PC_to_ADDR_B, .I_PC_INCR], // Read PC (for ADL)
      [.I_DATA_to_ADL, .I_AD_to_ADDR_B, .I_ADL_plus_X], // Read arg, ADL+X
      [.I_AD_to_ADDR_B], // Read arg from adjusted address
      [.I_SBC, .I_PC_to_ADDR_B, .I_NEXT_OP, .I_PC_INCR] // Subtract from A, Next OP
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

  static let Instructions:[String] = [
    "BRK", "ORA (zp,X)", "???", "???", "???", "ORA zp", "ASL zp", "???",
    "PHP", "ORA #", "ASL", "???", "???", "ORA abs", "ASL abs", "???",
    "BPL", "ORA (zp),Y", "???", "???", "???", "ORA zp,X", "ASL zp,X", "???",
    "CLC", "ORA abs,Y", "???", "???", "???", "ORA abs,X", "ASL abs,X", "???",
    "JSR", "AND (zp,X)", "???", "???", "BIT zp", "AND zp", "ROL zp", "???",
    "PLP", "AND #", "ROL", "???", "BIT abs", "AND abs", "ROL abs", "???",
    "BMI", "AND (zp),Y", "???", "???", "???", "AND zp,X", "ROL zp,X", "???",
    "SEC", "AND abs,Y", "???", "???", "???", "AND abs,X", "ROL abs,X", "???",
    "RTI", "EOR (zp,X)", "???", "???", "???", "EOR zp", "LSR zp", "???",
    "PHA", "EOR #", "LSR", "???", "JMP abs", "EOR abs", "LSR abs", "???",
    "BVC", "EOR (zp),Y", "???", "???", "???", "EOR zp,X", "LSR zp,X", "???",
    "CLI", "EOR abs,Y", "???", "???", "???", "EOR abs,X", "LSR abs,X", "???",
    "RTS", "ADC (zp,X)", "???", "???", "???", "ADC zp", "ROR zp", "???",
    "PLA", "ADC #", "ROR", "???", "JMP (abs)", "ADC abs", "ROR abs", "???",
    "BVS", "ADC (zp),Y", "???", "???", "???", "ADC zp,X", "ROR zp,X", "???",
    "SEI", "ADC abs,Y", "???", "???", "???", "ADC abs,X", "ROR abs,X", "???",
    "???", "STA (zp,X)", "???", "???", "STY zp", "STA zp", "STX zp", "???",
    "DEY", "???", "TXA", "???", "STY abs", "STA abs", "STX abs", "???",
    "BCC", "STA (zp),Y", "???", "???", "STY zp,X", "STA zp,X", "STX zp,Y", "???",
    "TYA", "STA abs,Y", "TXS", "???", "???", "STA abs,X", "???", "???",
    "LDY #", "LDA (zp,X)", "LDX #", "???", "LDY zp", "LDA zp", "LDX zp", "???",
    "TAY", "LDA #", "TAX", "???", "LDY abs", "LDA abs", "LDX abs", "???",
    "BCS", "LDA (zp),Y", "???", "???", "LDY zp,X", "LDA zp,X", "LDX zp,Y", "???",
    "CLV", "LDA abs,Y", "TSX", "???", "LDY abs,X", "LDA abs,X", "LDX abs,Y", "???",
    "CPY #", "CMP (zp,X)", "???", "???", "CPY zp", "CMP zp", "DEC zp", "???",
    "INY", "CMP #", "DEX", "???", "CPY abs", "CMP abs", "DEC abs", "???",
    "BNE", "CMP (zp),Y", "???", "???", "???", "CMP zp,X", "DEC zp,X", "???",
    "CLD", "CMP abs,Y", "???", "???", "???", "CMP abs,X", "DEC abs,X", "???",
    "CPX #", "SBC (zp,X)", "???", "???", "CPX zp", "SBC zp", "INC zp", "???",
    "INX", "SBC #", "NOP", "???", "CPX abs", "SBC abs", "INC abs", "???",
    "BEQ", "SBC (zp),Y", "???", "???", "???", "SBC zp,X", "INC zp,X", "???",
    "SED", "SBC abs,Y", "???", "???", "???", "SBC abs,X", "INC abs,X", "???"
  ]
  func logStatus() {
    print(String(format:"debug: %04x %02x %@ IR: %02x P: %02x %d %@ A: %02x X: %02x Y: %02x %@",
      pins.address.value,
      pins.data.value,
      (pins.read.isHigh() ? "R" : "W"),
      ir.value,
      status.value,
      instructionCycle,
      (pins.sync.isHigh() ? "H" : "L"),
      a.value,
      x.value,
      y.value,
      CPU6502.Instructions[Int(ir.value)]))
  }
}
