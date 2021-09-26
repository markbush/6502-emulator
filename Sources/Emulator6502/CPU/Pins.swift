public class Pins {
  public init() {

  }
  public let address = Bus16()
  public let data = Bus8()
  public let read = Pin(true)
  public let nmi = Pin(true)
  public let irq = Pin(true)
  public let ready = Pin(true)
  public let reset = Pin(false)
  public let sync = Pin(false)
}
