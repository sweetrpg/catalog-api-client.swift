import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// Catalog-wide summary stats (total volume count, most recent update) in one call - unlike
  /// `fetchVolumes()`, which returns a paginated page and would undercount if a caller mistook
  /// its length for the true total. Unauthenticated, same as `fetchVolumes()`.
  public func fetchCatalogStats() async throws -> CatalogStats {
    try await withSpan("fetch-catalog-stats") { _ in
      let (data, status) = try await send(method: "GET", path: "/stats", token: "", body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(CatalogStats.self, from: data)
    }
  }
}
