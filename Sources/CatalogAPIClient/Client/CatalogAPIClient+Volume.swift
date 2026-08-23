import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  public func fetchVolumes() async throws -> JSONAPIDocument<VolumeAttributes> {
    try await withSpan("fetch-volumes") { _ in
      try await fetch(path: "/volumes")
    }
  }

  /// Edits a volume, or proposes an edit for review, depending on the bearer token's roles
  /// (verified server-side by catalog-api via auth-api's `/authz/check` - this SDK does no
  /// role logic of its own, it just forwards the token). At least one of title/description/
  /// notes/tags must be non-nil.
  public func patchVolume(
    id: String, token: String, title: String? = nil, description: String? = nil,
    notes: String? = nil, tags: [String]? = nil
  ) async throws -> VolumePatchResult {
    try await withSpan("patch-volume") { _ in
      let body = try JSONEncoder().encode(
        PatchVolumeRequestBody(
          title: title, description: description, notes: notes, tags: tags))
      let (data, status) = try await send(
        method: "PATCH", path: "/volumes/\(id)", token: token, body: body)
      switch status {
      case 200:
        return .applied(try Self.decodeFirstLine(data))
      case 202:
        return .proposed(try JSONDecoder().decode(SubmittedVersionResponse.self, from: data))
      default:
        throw Self.decodeError(data, statusCode: status)
      }
    }
  }

  /// Lists a volume's version history, newest first.
  public func fetchVolumeVersions(id: String, token: String) async throws
    -> [VolumeVersionAttributes]
  {
    try await withSpan("fetch-volume-versions") { _ in
      let (data, status) = try await send(
        method: "GET", path: "/volumes/\(id)/versions", token: token, body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode([VolumeVersionAttributes].self, from: data)
    }
  }

  /// Fetches one version's full field snapshot, regardless of whether it's current.
  public func fetchVolumeVersion(id: String, version: Int, token: String) async throws
    -> VolumeVersionAttributes
  {
    try await withSpan("fetch-volume-version") { _ in
      let (data, status) = try await send(
        method: "GET", path: "/volumes/\(id)/versions/\(version)", token: token, body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(VolumeVersionAttributes.self, from: data)
    }
  }

  /// Accepts a submitted volume version in full (`fields: nil`) or in part (`fields` lists which
  /// changed field names to accept). Editor/admin only, enforced by catalog-api.
  public func acceptVolumeVersion(
    id: String, version: Int, token: String, fields: [String]? = nil
  ) async throws -> ReviewVersionResult {
    try await withSpan("accept-volume-version") { _ in
      let body = try JSONEncoder().encode(AcceptVersionRequestBody(fields: fields))
      let (data, status) = try await send(
        method: "POST", path: "/volumes/\(id)/versions/\(version)/accept", token: token,
        body: body)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      return try JSONDecoder().decode(ReviewVersionResult.self, from: data)
    }
  }

  /// Rejects a submitted volume version in full, with an optional review note. Editor/admin
  /// only, enforced by catalog-api.
  public func rejectVolumeVersion(
    id: String, version: Int, token: String, note: String? = nil
  ) async throws -> ReviewVersionResult {
    try await withSpan("reject-volume-version") { _ in
      let body = try JSONEncoder().encode(RejectVersionRequestBody(note: note))
      let (data, status) = try await send(
        method: "POST", path: "/volumes/\(id)/versions/\(version)/reject", token: token,
        body: body)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      return try JSONDecoder().decode(ReviewVersionResult.self, from: data)
    }
  }

  /// Rolls a volume back (or forward) to an arbitrary existing version. Admin only, enforced by
  /// catalog-api.
  public func setCurrentVolumeVersion(id: String, version: Int, token: String) async throws
    -> VolumeVersionAttributes
  {
    try await withSpan("set-current-volume-version") { _ in
      let (data, status) = try await send(
        method: "POST", path: "/volumes/\(id)/versions/\(version)/current", token: token,
        body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(VolumeVersionAttributes.self, from: data)
    }
  }
}
