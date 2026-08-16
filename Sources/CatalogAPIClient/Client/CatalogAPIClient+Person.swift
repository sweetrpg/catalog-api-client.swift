import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchPersons() async throws -> JSONAPIDocument<PersonAttributes> {
    try await withSpan("fetchPersons") { _ in
      try await fetch(path: "/persons")
    }
  }

  public func fetchPerson(id: String) async throws -> JSONAPISingleDocument<PersonAttributes> {
    try await withSpan("fetchPerson") { _ in
      try await fetch(path: "/persons/\(id)")
    }
  }

  public func fetchPersonVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetchPersonVolumes") { _ in
      try await fetch(path: "/persons/\(id)/volumes")
    }
  }
}
