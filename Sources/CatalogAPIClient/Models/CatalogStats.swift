import Foundation

/// Catalog-wide summary stats - total volume count and the most recent volume update - as
/// returned by `GET /stats`. Not a JSON:API resource (no `id`, not a record): a plain JSON
/// object, decoded directly rather than through `JSONAPIDocument`.
public struct CatalogStats: Codable, Sendable {
  public let volumeCount: Int
  public let lastUpdated: Date?

  enum CodingKeys: String, CodingKey {
    case volumeCount = "volume_count"
    case lastUpdated = "last_updated"
  }
}
