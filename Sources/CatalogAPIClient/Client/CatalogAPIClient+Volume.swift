import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchVolumes() async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetchVolumes") {
      try await fetch(path: "/volumes")
    }
  }

  /// Edits a volume, or proposes an edit for review, depending on the bearer token's roles
  /// (verified server-side by catalog-api via auth-api's `/authz/check` - this SDK does no
  /// role logic of its own, it just forwards the token). At least one of title/description/
  /// notes must be non-nil.
  public func patchVolume(
    id: String, token: String, title: String? = nil, description: String? = nil,
    notes: String? = nil
  ) async throws -> VolumePatchResult {
    try await withSpan("patchVolume") {
      let body = try JSONEncoder().encode(
        PatchVolumeRequestBody(title: title, description: description, notes: notes))
      let (data, status) = try await send(
        method: "PATCH", path: "/volumes/\(id)", token: token, body: body)
      switch status {
      case 200:
        return .applied(try Self.decodeFirstLine(data))
      case 202:
        return .proposed(try JSONDecoder().decode(ProposedChangeSubmission.self, from: data))
      default:
        throw Self.decodeError(data, statusCode: status)
      }
    }
  }
}
