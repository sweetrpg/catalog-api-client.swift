import Foundation

public struct VolumeAttributes: Codable, Sendable {
  public let title: String?
  public let description: String?
  public let notes: String?
  public let tags: [TagAttributes]?
  public let properties: [PropertyAttributes]?
  public let format: String?
  public let sampleAssetIds: [String]?
}
