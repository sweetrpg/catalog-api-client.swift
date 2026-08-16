import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchLicenses() async throws -> JSONAPIDocument<LicenseAttributes> {
    try await fetch(path: "/licenses")
  }

  public func fetchLicense(id: String) async throws -> JSONAPISingleDocument<LicenseAttributes> {
    try await fetch(path: "/licenses/\(id)")
  }

  public func fetchLicenseVolumes(id: String) async throws -> JSONAPIDocument<VolumeAttributes> {
    try await fetch(path: "/licenses/\(id)/volumes")
  }
}
