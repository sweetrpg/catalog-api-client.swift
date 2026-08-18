import Foundation
import Tracing

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

  func send(method: String, path: String, token: String, body: Data?) async throws -> (
    Data, Int
  ) {
    try await withSpan("send") { _ in
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

  func fetch<T: Codable & Sendable>(path: String) async throws -> JSONAPIDocument<T> {
    try await withSpan("fetch") { _ in
      try Self.decodeFirstLine(try await fetchRaw(path: path))
    }
  }

  func fetch<T: Codable & Sendable>(path: String) async throws -> JSONAPISingleDocument<T> {
    try await withSpan("fetch") { _ in
      try Self.decodeFirstLine(try await fetchRaw(path: path))
    }
  }

  private func fetchRaw(path: String) async throws -> Data {
    try await withSpan("fetch-raw") { _ in
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
