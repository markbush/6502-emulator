public class Register16 : Bus16 {
  public func incr() {
    value = value &+ 1
  }
  public func decr() {
    value = value &- 1
  }
}
