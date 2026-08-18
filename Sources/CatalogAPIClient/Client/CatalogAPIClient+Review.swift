import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchReviews() async throws -> JSONAPIDocument<ReviewAttributes> {
    try await withSpan("fetch-reviews") { _ in
      try await fetch(path: "/reviews")
    }
  }
}
