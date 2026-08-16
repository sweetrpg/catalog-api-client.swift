import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// Fetches an id-keyed name lookup for any of catalog-api's simple named resources
  /// (`/systems`, `/publishers`, `/studios`, `/licenses`) - they all share the same
  /// `NamedAttributes` shape.
  public func fetchNamed(path: String) async throws -> JSONAPIDocument<NamedAttributes> {
    try await fetch(path: path)
  }
}
