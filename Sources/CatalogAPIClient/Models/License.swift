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

  public var displayName: String { title ?? "Untitled" }
}
