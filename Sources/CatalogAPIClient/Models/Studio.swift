import Foundation

/// A studio's full set of attributes, matching `catalog-objects.go`'s studio model - the same
/// shape as `PublisherAttributes` minus `address`.
public struct StudioAttributes: Codable, Sendable {
  public let name: String?
  public let website: String?
  public let notes: String?
  public let tags: [TagAttributes]?

  public var displayName: String { name ?? "Untitled" }
}
