import Foundation

/// A publisher's full set of attributes, matching `catalog-objects.go`'s publisher model -
/// `NamedAttributes` only covers `name`/`title` and is kept around for the other simple named
/// resources (systems) that don't need more.
public struct PublisherAttributes: Codable, Sendable {
  public let name: String?
  public let address: String?
  public let website: String?
  public let notes: String?
  public let tags: [TagAttributes]?

  public var displayName: String { name ?? "Untitled" }
}
