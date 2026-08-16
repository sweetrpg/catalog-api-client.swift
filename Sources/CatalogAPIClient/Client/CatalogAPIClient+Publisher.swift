import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchPublishers() async throws -> JSONAPIDocument<PublisherAttributes> {
    try await withSpan("fetchPublishers") { _ in
      try await fetch(path: "/publishers")
    }
  }

  public func fetchPublisher(id: String) async throws -> JSONAPISingleDocument<
    PublisherAttributes
  > {
    try await withSpan("fetchPublisher") { _ in
      try await fetch(path: "/publishers/\(id)")
    }
  }

  public func fetchPublisherVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetchPublisherVolumes") { _ in
      try await fetch(path: "/publishers/\(id)/volumes")
    }
  }
}
