public class Pin {
  var value:Bool
  init(_ isOn:Bool) {
    value = isOn
  }
  func set() {
    value = true
  }
  func clear() {
    value = false
  }
  func isHigh() -> Bool {
    return value
  }
  func isLow() -> Bool {
    return !value
  }
}
