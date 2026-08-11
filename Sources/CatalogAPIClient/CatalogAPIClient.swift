import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Swift client SDK for `catalog-api`: JSON:API fetch and decoding only, for volumes, credits,
/// reviews, and name maps (systems, publishers, studios, licenses, persons). Deliberately has
/// no built-in caching - response caching is a per-application policy decision left to the
/// consumer, see this package's README.
public struct CatalogAPIClient: Sendable {
  private let baseURL: String
  private let session: URLSession

  public init(baseURL: String, timeoutSeconds: TimeInterval = 10) {
    self.baseURL = baseURL
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = timeoutSeconds
    configuration.timeoutIntervalForResource = timeoutSeconds
    self.session = URLSession(configuration: configuration)
  }

  public func fetchVolumes() async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/volumes")
  }

  /// Fetches an id-keyed name lookup for any of catalog-api's simple named resources
  /// (`/systems`, `/publishers`, `/studios`, `/licenses`) - they all share the same
  /// `NamedAttributes` shape.
  public func fetchNamed(path: String) async throws -> JSONAPIDocument<NamedAttributes> {
    try await fetch(path: path)
  }

  public func fetchPersons() async throws -> JSONAPIDocument<PersonAttributes> {
    try await fetch(path: "/persons")
  }

  public func fetchContributions() async throws -> JSONAPIDocument<ContributionAttributes> {
    try await fetch(path: "/contributions")
  }

  public func fetchReviews() async throws -> JSONAPIDocument<ReviewAttributes> {
    try await fetch(path: "/reviews")
  }

  /// Edits a volume, or proposes an edit for review, depending on the bearer token's roles
  /// (verified server-side by catalog-api via auth-api's `/authz/check` - this SDK does no
  /// role logic of its own, it just forwards the token). At least one of title/description/
  /// notes must be non-nil.
  public func patchVolume(
    id: String, token: String, title: String? = nil, description: String? = nil,
    notes: String? = nil
  ) async throws -> VolumePatchResult {
    let body = try JSONEncoder().encode(
      PatchVolumeRequestBody(title: title, description: description, notes: notes))
    let (data, status) = try await send(
      method: "PATCH", path: "/volumes/\(id)", token: token, body: body)
    switch status {
    case 200:
      return .applied(try Self.decodeFirstLine(data))
    case 202:
      return .proposed(try JSONDecoder().decode(ProposedChangeSubmission.self, from: data))
    default:
      throw Self.decodeError(data, statusCode: status)
    }
  }

  /// Lists a volume's pending proposed changes - editor/admin only, enforced by catalog-api.
  public func listProposedChanges(volumeID: String, token: String) async throws
    -> [ProposedChangeSummary]
  {
    let (data, status) = try await send(
      method: "GET", path: "/volumes/\(volumeID)/proposed-changes", token: token, body: nil)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([ProposedChangeSummary].self, from: data)
  }

  /// Accepts a proposed change in full (`fields: nil`) or in part (`fields` lists which
  /// changed field names to accept; the rest are rejected). Editor/admin only.
  public func acceptProposedChange(
    volumeID: String, proposalID: String, token: String, fields: [String]? = nil
  ) async throws -> ReviewProposalResult {
    let body = try JSONEncoder().encode(AcceptProposalRequestBody(fields: fields))
    let (data, status) = try await send(
      method: "POST", path: "/volumes/\(volumeID)/proposed-changes/\(proposalID)/accept",
      token: token, body: body)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(ReviewProposalResult.self, from: data)
  }

  /// Rejects a proposed change in full, with an optional review note. Editor/admin only.
  public func rejectProposedChange(
    volumeID: String, proposalID: String, token: String, note: String? = nil
  ) async throws -> ReviewProposalResult {
    let body = try JSONEncoder().encode(RejectProposalRequestBody(note: note))
    let (data, status) = try await send(
      method: "POST", path: "/volumes/\(volumeID)/proposed-changes/\(proposalID)/reject",
      token: token, body: body)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(ReviewProposalResult.self, from: data)
  }

  private func send(method: String, path: String, token: String, body: Data?) async throws -> (
    Data, Int
  ) {
    guard let url = URL(string: baseURL + path) else {
      throw URLError(.badURL)
    }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    if let body {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = body
    }
    let (data, response) = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
      let task = session.dataTask(with: request) { data, response, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let data, let response {
          continuation.resume(returning: (data, response))
        } else {
          continuation.resume(throwing: URLError(.badServerResponse))
        }
      }
      task.resume()
    }
    guard let http = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    return (data, http.statusCode)
  }

  static func decodeError(_ data: Data, statusCode: Int) -> CatalogAPIError {
    struct ErrorBody: Decodable {
      let error: String?
      let message: String?
    }
    let decoded = try? JSONDecoder().decode(ErrorBody.self, from: data)
    return CatalogAPIError(
      statusCode: statusCode, error: decoded?.error, message: decoded?.message)
  }

  private func fetch<T: Codable & Sendable>(path: String) async throws -> JSONAPIDocument<T> {
    guard let url = URL(string: baseURL + path) else {
      throw URLError(.badURL)
    }
    let (data, response) = try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
      let task = session.dataTask(with: url) { data, response, error in
        if let error {
          continuation.resume(throwing: error)
        } else if let data, let response {
          continuation.resume(returning: (data, response))
        } else {
          continuation.resume(throwing: URLError(.badServerResponse))
        }
      }
      task.resume()
    }
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw URLError(.badServerResponse)
    }
    return try Self.decodeFirstLine(data)
  }

  /// catalog-api has been observed appending a second, unrelated JSON object after a newline
  /// when its Redis cache write fails server-side (a leaked error that should have just been
  /// logged, not written to the response) - see
  /// https://github.com/sweetrpg/catalog-api/issues/121. Decoding only up to the first newline
  /// is defensive against that, not a statement that this response shape is expected or
  /// supported - revisit once #121's fix is confirmed deployed everywhere. Internal (not
  /// private) so it's directly testable without a network fixture.
  static func decodeFirstLine<T: Decodable>(_ data: Data) throws -> T {
    let firstLine =
      data.split(separator: UInt8(ascii: "\n"), maxSplits: 1, omittingEmptySubsequences: true)
      .first ?? data[...]
    return try JSONDecoder().decode(T.self, from: Data(firstLine))
  }
}
