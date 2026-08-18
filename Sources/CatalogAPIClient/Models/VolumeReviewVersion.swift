import Foundation

/// Response to `POST /volumes/:id/versions/:version/accept` or `/reject`.
public struct ReviewVersionResult: Codable, Sendable {
  public let version: Int
  public let state: String
  public let conflicts: [String]?

  public init(version: Int, state: String, conflicts: [String]?) {
    self.version = version
    self.state = state
    self.conflicts = conflicts
  }
}

struct AcceptVersionRequestBody: Encodable {
  let fields: [String]?
}

struct RejectVersionRequestBody: Encodable {
  let note: String?
}
