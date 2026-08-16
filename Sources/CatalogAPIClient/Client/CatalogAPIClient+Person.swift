import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchPersons() async throws -> JSONAPIDocument<PersonAttributes> {
    try await fetch(path: "/persons")
  }

  public func fetchPerson(id: String) async throws -> JSONAPISingleDocument<PersonAttributes> {
    try await fetch(path: "/persons/\(id)")
  }

  public func fetchPersonVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/persons/\(id)/volumes")
  }
}
