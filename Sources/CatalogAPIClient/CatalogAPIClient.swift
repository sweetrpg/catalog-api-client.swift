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

  public func fetchPerson(id: String) async throws -> JSONAPISingleDocument<PersonAttributes> {
    try await fetch(path: "/persons/\(id)")
  }

  public func fetchPersonVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/persons/\(id)/volumes")
  }

  public func fetchPublishers() async throws -> JSONAPIDocument<PublisherAttributes> {
    try await fetch(path: "/publishers")
  }

  public func fetchPublisher(id: String) async throws -> JSONAPISingleDocument<
    PublisherAttributes
  > {
    try await fetch(path: "/publishers/\(id)")
  }

  public func fetchPublisherVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes>
  {
    try await fetch(path: "/publishers/\(id)/volumes")
  }

  public func fetchStudios() async throws -> JSONAPIDocument<StudioAttributes> {
    try await fetch(path: "/studios")
  }

  public func fetchStudio(id: String) async throws -> JSONAPISingleDocument<StudioAttributes> {
    try await fetch(path: "/studios/\(id)")
  }

  public func fetchStudioVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/studios/\(id)/volumes")
  }

  public func fetchLicenses() async throws -> JSONAPIDocument<LicenseAttributes> {
    try await fetch(path: "/licenses")
  }

  public func fetchLicense(id: String) async throws -> JSONAPISingleDocument<LicenseAttributes> {
    try await fetch(path: "/licenses/\(id)")
  }

  public func fetchLicenseVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/licenses/\(id)/volumes")
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

  /// Finalizes the caller's in-flight durable edit session for a volume: catalog-api reads the
  /// session itself (this call sends no body) and applies it directly (admin/editor) or creates
  /// a proposed change referencing it (submitter), the same `VolumePatchResult` shape as
  /// `patchVolume`. Throws `CatalogAPIError` (400) if there's no session, it belongs to a
  /// different record, or the caller is at their unapproved-submission cap - see
  /// durable-volume-editing in sweetrpg/platform.
  public func finalizeSession(id: String, token: String) async throws -> VolumePatchResult {
    let (data, status) = try await send(
      method: "POST", path: "/volumes/\(id)/finalize-session", token: token, body: nil)
    switch status {
    case 200:
      return .applied(try Self.decodeFirstLine(data))
    case 202:
      return .proposed(try JSONDecoder().decode(ProposedChangeSubmission.self, from: data))
    default:
      throw Self.decodeError(data, statusCode: status)
    }
  }

  /// Edits a publisher/studio/person/license, or proposes an edit for review, depending on the
  /// bearer token's roles - the generic counterpart of `patchVolume`, matching catalog-api's
  /// `PATCH /:type/:id` contract of an arbitrary field-name-keyed JSON body. `path` is the
  /// resource's collection path (e.g. `/publishers`).
  public func patchEntity<Attributes: Codable & Sendable>(
    path: String, id: String, token: String, fields: [String: String]
  ) async throws -> EntityPatchResult<Attributes> {
    let body = try JSONEncoder().encode(fields)
    let (data, status) = try await send(
      method: "PATCH", path: "\(path)/\(id)", token: token, body: body)
    switch status {
    case 200:
      return .applied(try Self.decodeFirstLine(data))
    case 202:
      return .proposed(try JSONDecoder().decode(ProposedChangeSubmission.self, from: data))
    default:
      throw Self.decodeError(data, statusCode: status)
    }
  }

  /// Lists a publisher/studio/person/license's pending proposed changes - the generic
  /// counterpart of `listProposedChanges(volumeID:token:)`. `path` is the resource's collection
  /// path (e.g. `/publishers`). Editor/admin only, enforced by catalog-api.
  public func listProposedChanges(path: String, id: String, token: String) async throws
    -> [ProposedChangeSummary]
  {
    let (data, status) = try await send(
      method: "GET", path: "\(path)/\(id)/proposed-changes", token: token, body: nil)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([ProposedChangeSummary].self, from: data)
  }

  /// Accepts a publisher/studio/person/license proposed change - the generic counterpart of
  /// `acceptProposedChange(volumeID:proposalID:token:fields:)`.
  public func acceptProposedChange(
    path: String, id: String, proposalID: String, token: String, fields: [String]? = nil
  ) async throws -> ReviewProposalResult {
    let body = try JSONEncoder().encode(AcceptProposalRequestBody(fields: fields))
    let (data, status) = try await send(
      method: "POST", path: "\(path)/\(id)/proposed-changes/\(proposalID)/accept",
      token: token, body: body)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(ReviewProposalResult.self, from: data)
  }

  /// Rejects a publisher/studio/person/license proposed change - the generic counterpart of
  /// `rejectProposedChange(volumeID:proposalID:token:note:)`.
  public func rejectProposedChange(
    path: String, id: String, proposalID: String, token: String, note: String? = nil
  ) async throws -> ReviewProposalResult {
    let body = try JSONEncoder().encode(RejectProposalRequestBody(note: note))
    let (data, status) = try await send(
      method: "POST", path: "\(path)/\(id)/proposed-changes/\(proposalID)/reject",
      token: token, body: body)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(ReviewProposalResult.self, from: data)
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

  /// Lists a shared vocabulary's values (`contribution-type`, `property-name`, or `format`) -
  /// any edit-capable role, enforced by catalog-api. `format` is further restricted to
  /// editor/admin - a submitter's token gets a 403, same as any other role check here.
  public func fetchVocabulary(type: String, token: String) async throws -> VocabularyResponse {
    let (data, status) = try await send(
      method: "GET", path: "/vocabularies/\(type)", token: token, body: nil)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(VocabularyResponse.self, from: data)
  }

  /// Adds a new value to a shared vocabulary - editor/admin only for every type, enforced by
  /// catalog-api. Returns the vocabulary's full value list after the add.
  public func addVocabularyValue(type: String, value: String, token: String) async throws
    -> VocabularyResponse
  {
    let body = try JSONEncoder().encode(AddVocabularyValueRequestBody(value: value))
    let (data, status) = try await send(
      method: "POST", path: "/vocabularies/\(type)", token: token, body: body)
    guard status == 201 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(VocabularyResponse.self, from: data)
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
    try Self.decodeFirstLine(try await fetchRaw(path: path))
  }

  private func fetch<T: Codable & Sendable>(path: String) async throws -> JSONAPISingleDocument<T>
  {
    try Self.decodeFirstLine(try await fetchRaw(path: path))
  }

  private func fetchRaw(path: String) async throws -> Data {
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
    return data
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
