public class Memory : Chip {
  var mem = Array(repeating: UInt8(0), count: 0x10000) // 64K
  let pins: Pins

  init(_ pins: Pins) {
    self.pins = pins
  }

  public subscript(index: UInt16) -> UInt8 {
    get { mem[Int(index)] }
    set { mem[Int(index)] = newValue }
  }

  public func tick() -> Void {
    if pins.read.isHigh() {
      pins.data.value = self[pins.address.value]
    } else {
      self[pins.address.value] = pins.data.value
    }
  }
}
