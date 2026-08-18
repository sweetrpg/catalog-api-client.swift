import Foundation

public struct NamedAttributes: Codable, Sendable {
  public let name: String?
  public let title: String?

  public var displayName: String { name ?? title ?? "Untitled" }
}
