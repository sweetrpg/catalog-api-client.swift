import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchStudios() async throws -> JSONAPIDocument<StudioAttributes> {
    try await withSpan("fetchStudios") { _ in
      try await fetch(path: "/studios")
    }
  }

  public func fetchStudio(id: String) async throws -> JSONAPISingleDocument<StudioAttributes> {
    try await withSpan("fetchStudio") { _ in
      try await fetch(path: "/studios/\(id)")
    }
  }

  public func fetchStudioVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetchStudioVolumes") { _ in
      try await fetch(path: "/studios/\(id)/volumes")
    }
  }
}
