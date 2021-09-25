public class Pins {
  public init() {
    
  }
  let address = Bus16()
  let data = Bus8()
  let read = Pin(true)
  let nmi = Pin(true)
  let irq = Pin(true)
  let ready = Pin(true)
  let reset = Pin(false)
  let sync = Pin(false)
}
