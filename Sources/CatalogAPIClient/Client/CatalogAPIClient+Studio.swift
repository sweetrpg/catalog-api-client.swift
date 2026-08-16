import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchStudios() async throws -> JSONAPIDocument<StudioAttributes> {
    try await fetch(path: "/studios")
  }

  public func fetchStudio(id: String) async throws -> JSONAPISingleDocument<StudioAttributes> {
    try await fetch(path: "/studios/\(id)")
  }

  public func fetchStudioVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/studios/\(id)/volumes")
  }
}
