import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

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
}
