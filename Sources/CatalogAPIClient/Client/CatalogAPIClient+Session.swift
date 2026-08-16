import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// Finalizes the caller's in-flight durable edit session for a volume: catalog-api reads the
  /// session itself (this call sends no body) and applies it directly (admin/editor) or creates
  /// a proposed change referencing it (submitter), the same `VolumePatchResult` shape as
  /// `patchVolume`. Throws `CatalogAPIError` (400) if there's no session, it belongs to a
  /// different record, or the caller is at their unapproved-submission cap - see
  /// durable-volume-editing in sweetrpg/platform.
  public func finalizeSession(id: String, token: String) async throws -> VolumePatchResult {
    try await withSpan("finalizeSession") { _ in
      let (data, status) = try await send(
        method: "POST", path: "/volumes/\(id)/finalize-session", token: token, body: nil)
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
