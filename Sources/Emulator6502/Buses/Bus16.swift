public class Bus16 {
  public let highLines = Register8()
  public let lowLines = Register8()
  public var value:UInt16 {
    get { (UInt16(highLines.value) << 8) | UInt16(lowLines.value) }
    set { highLines.value = UInt8(newValue >> 8) ; lowLines.value = UInt8(newValue & 0xff) }
  }
  public var high:UInt8 {
    get { highLines.value }
    set { highLines.value = newValue }
  }
  public var low:UInt8 {
    get { lowLines.value }
    set { lowLines.value = newValue }
  }

  public subscript(index:Int) -> Bool {
    get { (index < 8) ? lowLines[index] : highLines[index - 8] }
    set {
      if index < 8 {
        lowLines[index] = newValue
      } else {
        highLines[index - 8] = newValue
      }
    }
  }

  public func load(from: Bus16) {
    high = from.high
    low = from.low
  }
}
