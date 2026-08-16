import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

    public func fetchContributions() async throws -> JSONAPIDocument<ContributionAttributes> {
    try await fetch(path: "/contributions")
  }

}
