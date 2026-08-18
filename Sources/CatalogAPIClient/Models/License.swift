import Foundation

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
  public let properties: [PropertyAttributes]?
  public let tags: [TagAttributes]?

  // catalog-api emits snake_case for these two (short_title, legal_code) - without explicit
  // keys, Codable looks for "shortTitle"/"legalCode" literally, finds neither, and silently
  // decodes both as nil regardless of the actual response. Confirmed live: both are populated
  // server-side (e.g. short_title "OGL 1.0a", legal_code holding the full license text).
  enum CodingKeys: String, CodingKey {
    case title, version, deed, website, status, availability, notes, properties, tags
    case shortTitle = "short_title"
    case legalCode = "legal_code"
  }

  public var displayName: String { title ?? "Untitled" }
}
