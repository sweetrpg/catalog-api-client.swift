import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchReviews() async throws -> JSONAPIDocument<ReviewAttributes> {
    try await fetch(path: "/reviews")
  }
}
