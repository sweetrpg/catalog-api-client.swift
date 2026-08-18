import Foundation

/// One free-form name/value property (e.g. "Page count" / "320") - `kind` is a type discriminator
/// catalog-api's `modelcore.PropertyVO` carries but this SDK's consumers don't yet interpret
/// (every property round-trips as a plain string value today).
public struct PropertyAttributes: Codable, Sendable {
  public let name: String
  public let kind: String
  public let value: String

  public init(name: String, kind: String, value: String) {
    self.name = name
    self.kind = kind
    self.value = value
  }
}
