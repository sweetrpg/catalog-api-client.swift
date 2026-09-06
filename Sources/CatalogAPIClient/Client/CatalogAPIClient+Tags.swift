import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// The catalog's most-used volume tags, most frequent first - the tag cloud on the landing
  /// page. Unauthenticated, like `fetchCatalogStats()`. `limit` is copied onto the query string
  /// as-is; catalog-api clamps it (default 20, cap 100), so pass 0 to take its default.
  public func fetchVolumeTags(limit: Int = 0) async throws -> [String] {
    try await withSpan("fetch-volume-tags") { _ in
      let (data, status) = try await send(
        method: "GET", path: "/volumes/tags?limit=\(limit)", token: "", body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      return try JSONDecoder().decode([String].self, from: data)
    }
  }
}
