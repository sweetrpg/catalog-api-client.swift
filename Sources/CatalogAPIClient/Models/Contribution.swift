import Foundation

public struct ContributionAttributes: Codable, Sendable {
  /// catalog-api's Contribution VO serializes its role list as `roles` (`jsonapi:"attr,roles"`
  /// on `catalog-objects.go`'s `ContributionVO`) - the `role`/`credit`/`title` fields this
  /// struct previously decoded never matched any real attribute name, so every credit's role
  /// silently decoded to nil and consumers fell back to a generic placeholder.
  public let roles: [String]?
}
