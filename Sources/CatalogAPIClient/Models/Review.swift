import Foundation

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
