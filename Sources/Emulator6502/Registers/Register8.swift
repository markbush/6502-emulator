class Register8 : Bus8 {
  func shiftLeft() -> Bool {
    let carry = value & 0b1000_0000
    value <<= 1
    return carry == 0b1000_0000
  }
  func shiftRight() -> Bool {
    let carry = value & 0b0000_0001
    value >>= 1
    return carry == 1
  }

  func rotateLeft(carryIn: Bool) -> Bool {
    let carry = value & 0b1000_0000
    value <<= 1
    if carryIn { value |= 1 }
    return carry == 0b1000_0000
  }
  func rotateRight(carryIn: Bool) -> Bool {
    let carry = value & 0b0000_0001
    value >>= 1
    if carryIn { value |= 0b1000_0000 }
    return carry == 1
  }
  func adc(_ from: UInt8, carryIn: Bool) -> (UInt8, Bool,Bool) {
    let result = UInt16(value) + UInt16(from) + (carryIn ? 1 : 0)
    let newValue = UInt8(result & 0xff)
    let carryOut = (result & 0x100) == 0x100
    let overflow = ((from ^ newValue) & (value ^ newValue) & 0x80) != 0
    return (newValue, carryOut, overflow)
  }

  func incr() {
    value &+= 1
  }
  func decr() {
    value &-= 1
  }
}
