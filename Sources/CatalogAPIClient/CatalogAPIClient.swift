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
