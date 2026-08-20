import Foundation

/// One entity type's landing-page-summary card (catalog-landing-page-summary): a live-record
/// count plus the single most recently added/updated record, or a nil `mostRecent`/`lastUpdated`
/// when the type has zero records.
public struct TypeStats: Codable, Sendable {
  public let count: Int
  public let lastUpdated: Date?
  public let mostRecent: TypeStatsMostRecent?

  enum CodingKeys: String, CodingKey {
    case count
    case lastUpdated = "last_updated"
    case mostRecent = "most_recent"
  }
}

public struct TypeStatsMostRecent: Codable, Sendable {
  public let id: String
  public let name: String
}

/// Catalog-wide summary stats - one `TypeStats` card per entity type - as returned by
/// `GET /stats`. Not a JSON:API resource (no `id`, not a record): a plain JSON object, decoded
/// directly rather than through `JSONAPIDocument`.
public struct CatalogStats: Codable, Sendable {
  public let volumes: TypeStats
  public let publishers: TypeStats
  public let studios: TypeStats
  public let persons: TypeStats
  public let licenses: TypeStats
  public let systems: TypeStats
}
