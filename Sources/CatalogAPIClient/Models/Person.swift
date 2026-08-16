import Foundation

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
