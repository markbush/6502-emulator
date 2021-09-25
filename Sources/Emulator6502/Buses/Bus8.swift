public class Bus8 {
  var value:UInt8 = 0

  subscript(index:Int) -> Bool {
    get { (value & (1 << index)) != 0 }
    set {
      let bitValue:UInt8 = 1 << index
      let bitMask:UInt8 = ~bitValue
      value = (value & bitMask)
      if newValue { value = value | bitValue }
    }
  }
}
