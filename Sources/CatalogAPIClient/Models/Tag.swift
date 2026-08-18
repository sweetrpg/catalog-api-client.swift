import Foundation

public struct TagAttributes: Codable, Sendable {
  public let name: String?
  public let value: String?

  public var displayName: String { name ?? value ?? "" }
}
