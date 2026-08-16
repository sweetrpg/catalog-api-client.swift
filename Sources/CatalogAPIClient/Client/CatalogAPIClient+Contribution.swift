import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchContributions() async throws -> JSONAPIDocument<ContributionAttributes> {
    try await withSpan("fetchContributions") { _ in
      try await fetch(path: "/contributions")
    }
  }

}
