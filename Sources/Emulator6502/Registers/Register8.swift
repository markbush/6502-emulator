public class Register8 : Bus8 {
  func shiftLeft() -> (UInt8,Bool,Bool,Bool) {
    let carryOut = (value & 0b1000_0000) == 0b1000_0000
    let newValue = value << 1
    let negative = (newValue & 0x80) == 0x80
    return (newValue, carryOut, negative, newValue == 0)
  }
  func shiftRight() -> (UInt8,Bool,Bool,Bool) {
    let carryOut = (value & 0b0000_0001) == 1
    let newValue = value >> 1
    let negative = (newValue & 0x80) == 0x80
    return (newValue, carryOut, negative, newValue == 0)
  }

  func rotateLeft(carryIn: Bool) -> (UInt8,Bool,Bool,Bool) {
    let carryOut = (value & 0b1000_0000) == 0b1000_0000
    var newValue = value << 1
    if carryIn { newValue |= 1 }
    let negative = (newValue & 0x80) == 0x80
    return (newValue, carryOut, negative, newValue == 0)
  }
  func rotateRight(carryIn: Bool) -> (UInt8,Bool,Bool,Bool) {
    let carryOut = (value & 0b0000_0001) == 1
    var newValue = value >> 1
    if carryIn { newValue |= 0b1000_0000 }
    let negative = (newValue & 0x80) == 0x80
    return (newValue, carryOut, negative, newValue == 0)
  }

  func adc(_ from: UInt8, carryIn: Bool) -> (UInt8,Bool,Bool,Bool,Bool) {
    let result = UInt16(value) + UInt16(from) + (carryIn ? 1 : 0)
    let newValue = UInt8(result & 0xff)
    let carryOut = (result & 0x100) == 0x100
    let overflow = ((from ^ newValue) & (value ^ newValue) & 0x80) != 0
    let negative = (newValue & 0x80) == 0x80
    return (newValue, carryOut, overflow, negative, newValue == 0)
  }
  func and(_ from: UInt8) -> (UInt8,Bool,Bool) {
    let result = value & from
    let negative = (result & 0x80) == 0x80
    return (result, negative, result == 0)
  }
  func eor(_ from: UInt8) -> (UInt8,Bool,Bool) {
    let result = value ^ from
    let negative = (result & 0x80) == 0x80
    return (result, negative, result == 0)
  }
  func or(_ from: UInt8) -> (UInt8,Bool,Bool) {
    let result = value | from
    let negative = (result & 0x80) == 0x80
    return (result, negative, result == 0)
  }

  func incr() {
    value &+= 1
  }
  func decr() {
    value &-= 1
  }
}
