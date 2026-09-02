import Foundation

public struct VolumeAttributes: Codable, Sendable {
  public let title: String?
  public let description: String?
  public let notes: String?
  public let tags: [TagAttributes]?
  public let properties: [PropertyAttributes]?
  public let format: String?
  public let sampleAssetIds: [String]?
  /// Denormalized game-system display names keyed by system ID, as of the volume's last write.
  /// Absent/`nil` for a volume saved before the denormalization shipped; a missing or empty
  /// entry means "render the system ID".
  public let systemTitles: [String: String]?
}
