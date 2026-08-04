import Foundation

public struct TagAttributes: Codable, Sendable {
  public let name: String?
  public let value: String?

  public var displayName: String { name ?? value ?? "" }
}

public struct VolumeAttributes: Codable, Sendable {
  public let title: String?
  public let description: String?
  public let notes: String?
  public let tags: [TagAttributes]?
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

  public var displayName: String {
    if let name { return name }
    if let fullName { return fullName }
    let combined = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    return combined.isEmpty ? "Unknown" : combined
  }
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
