class Memory {
  var mem = Array(repeating: UInt8(0), count: 0x10000) // 64K

  subscript(index: UInt16) -> UInt8 {
    get { mem[Int(index)] }
    set { mem[Int(index)] = newValue }
  }
}
