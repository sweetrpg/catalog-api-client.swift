import Foundation

/// Minimal JSON:API envelope, matching catalog-api's response shape closely enough to decode
/// the fields consumers actually use. Not a general-purpose JSON:API client - extend as new
/// endpoints are wired up rather than trying to model the whole spec up front.
public struct JSONAPIDocument<Attributes: Codable & Sendable>: Codable, Sendable {
  public struct Resource: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: Attributes
    public let relationships: [String: JSONAPIRelationship]?
  }

  public let data: [Resource]
}

public struct JSONAPISingleDocument<Attributes: Codable & Sendable>: Codable, Sendable {
  public struct Resource: Codable, Sendable {
    public let id: String
    public let type: String
    public let attributes: Attributes
    public let relationships: [String: JSONAPIRelationship]?
  }

  public let data: Resource
}

public struct JSONAPIRelationship: Codable, Sendable {
  public let data: JSONAPIRelationshipData?
}

/// Relationship `data` is either a single identifier object or an array of them (to-one vs.
/// to-many) - JSON:API allows both shapes depending on the relationship, so this decodes
/// whichever is present rather than assuming one.
public enum JSONAPIRelationshipData: Codable, Sendable {
  case single(ResourceIdentifier)
  case many([ResourceIdentifier])

  public struct ResourceIdentifier: Codable, Sendable {
    public let id: String
    public let type: String
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let many = try? container.decode([ResourceIdentifier].self) {
      self = .many(many)
    } else {
      self = .single(try container.decode(ResourceIdentifier.self))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .single(let identifier): try container.encode(identifier)
    case .many(let identifiers): try container.encode(identifiers)
    }
  }

  public var ids: [String] {
    switch self {
    case .single(let identifier): return [identifier.id]
    case .many(let identifiers): return identifiers.map(\.id)
    }
  }
}
