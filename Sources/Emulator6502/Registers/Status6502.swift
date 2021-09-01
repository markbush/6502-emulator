class Status6502 : Register8 {
  static let CARRY:UInt8 = 0b0000_0001
  static let CARRY_MASK:UInt8 = ~CARRY
  static let ZERO:UInt8 = 0b0000_0010
  static let ZERO_MASK:UInt8 = ~ZERO
  static let INTERRUPT:UInt8 = 0b0000_0100
  static let INTERRUPT_MASK:UInt8 = ~INTERRUPT
  static let DECIMAL:UInt8 = 0b0000_1000
  static let DECIMAL_MASK:UInt8 = ~DECIMAL
  static let BREAK:UInt8 = 0b0001_0000
  static let BREAK_MASK:UInt8 = ~BREAK
  static let OVERFLOW:UInt8 = 0b0100_0000
  static let OVERFLOW_MASK:UInt8 = ~OVERFLOW
  static let NEGATIVE:UInt8 = 0b1000_0000
  static let NEGATIVE_MASK:UInt8 = ~NEGATIVE

  var carry:Bool {
    get { (value & Status6502.CARRY) == Status6502.CARRY }
    set { value = (value & Status6502.CARRY_MASK) | (newValue ? Status6502.CARRY : 0) }
  }
  var zero:Bool {
    get { (value & Status6502.ZERO) == Status6502.ZERO }
    set { value = (value & Status6502.ZERO_MASK) | (newValue ? Status6502.ZERO : 0) }
  }
  var interrupt:Bool {
    get { (value & Status6502.INTERRUPT) == Status6502.INTERRUPT }
    set { value = (value & Status6502.INTERRUPT_MASK) | (newValue ? Status6502.INTERRUPT : 0) }
  }
  var decimal:Bool {
    get { (value & Status6502.DECIMAL) == Status6502.DECIMAL }
    set { value = (value & Status6502.DECIMAL_MASK) | (newValue ? Status6502.DECIMAL : 0) }
  }
  var brk:Bool {
    get { (value & Status6502.BREAK) == Status6502.BREAK }
    set { value = (value & Status6502.BREAK_MASK) | (newValue ? Status6502.BREAK : 0) }
  }
  var overflow:Bool {
    get { (value & Status6502.OVERFLOW) == Status6502.OVERFLOW }
    set { value = (value & Status6502.OVERFLOW_MASK) | (newValue ? Status6502.OVERFLOW : 0) }
  }
  var negative:Bool {
    get { (value & Status6502.NEGATIVE) == Status6502.NEGATIVE }
    set { value = (value & Status6502.NEGATIVE_MASK) | (newValue ? Status6502.NEGATIVE : 0) }
  }
}
