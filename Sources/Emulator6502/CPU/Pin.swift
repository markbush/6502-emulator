public class Pin {
  var value:Bool
  init(_ isOn:Bool) {
    value = isOn
  }
  public func set() {
    value = true
  }
  public func clear() {
    value = false
  }
  public func isHigh() -> Bool {
    return value
  }
  public func isLow() -> Bool {
    return !value
  }
}
