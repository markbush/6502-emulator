class Register16 : Bus16 {
  func incr() {
    value = value &+ 1
  }
  func decr() {
    value = value &- 1
  }
}
