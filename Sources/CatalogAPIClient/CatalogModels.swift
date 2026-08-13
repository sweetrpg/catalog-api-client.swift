import Foundation

public struct TagAttributes: Codable, Sendable {
  public let name: String?
  public let value: String?

  public var displayName: String { name ?? value ?? "" }
}

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

public struct VolumeAttributes: Codable, Sendable {
  public let title: String?
  public let description: String?
  public let notes: String?
  public let tags: [TagAttributes]?
  public let properties: [PropertyAttributes]?
  public let format: String?
  public let sampleAssetIds: [String]?
}

public struct NamedAttributes: Codable, Sendable {
  public let name: String?
  public let title: String?

  public var displayName: String { name ?? title ?? "Untitled" }
}

public struct PersonAttributes: Codable, Sendable {
  public let name: String?
  public let fullName: String?
  public let firstName: String?
  public let lastName: String?
  public let notes: String?
  public let tags: [TagAttributes]?

  public var displayName: String {
    if let name { return name }
    if let fullName { return fullName }
    let combined = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    return combined.isEmpty ? "Unknown" : combined
  }
}

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

/// A studio's full set of attributes, matching `catalog-objects.go`'s studio model - the same
/// shape as `PublisherAttributes` minus `address`.
public struct StudioAttributes: Codable, Sendable {
  public let name: String?
  public let website: String?
  public let notes: String?
  public let tags: [TagAttributes]?

  public var displayName: String { name ?? "Untitled" }
}

/// A license's full set of attributes, matching `catalog-objects.go`'s license model - the
/// richest of the four entity types, with no equivalent thin shape.
public struct LicenseAttributes: Codable, Sendable {
  public let title: String?
  public let shortTitle: String?
  public let version: String?
  public let deed: String?
  public let legalCode: String?
  public let website: String?
  public let status: String?
  public let availability: String?
  public let notes: String?
  public let tags: [TagAttributes]?

  public var displayName: String { title ?? "Untitled" }
}

public struct ContributionAttributes: Codable, Sendable {
  public let role: String?
  public let credit: String?
  public let title: String?
}

public struct ReviewAttributes: Codable, Sendable {
  public let authorName: String?
  public let author: String?
  public let name: String?
  public let rating: Double?
  public let score: Double?
  public let body: String?
  public let text: String?
  public let review: String?
  public let content: String?

  public var displayAuthor: String { authorName ?? author ?? name ?? "A reader" }
  public var displayRating: Double { rating ?? score ?? 0 }
  public var displayText: String { body ?? text ?? review ?? content ?? "" }
}
