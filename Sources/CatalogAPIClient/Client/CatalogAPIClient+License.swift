import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchLicenses() async throws -> JSONAPIDocument<LicenseAttributes> {
    try await withSpan("fetch-licenses") { _ in
      try await fetch(path: "/licenses")
    }
  }

  public func fetchLicense(id: String) async throws -> JSONAPISingleDocument<LicenseAttributes> {
    try await withSpan("fetch-license") { _ in
      try await fetch(path: "/licenses/\(id)")
    }
  }

  public func fetchLicenseVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetch-license-volumes") { _ in
      try await fetch(path: "/licenses/\(id)/volumes")
    }
  }
}
