import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// Edits a publisher/studio/person/license, or proposes an edit for review, depending on the
  /// bearer token's roles - the generic counterpart of `patchVolume`, matching catalog-api's
  /// `PATCH /:type/:id` contract of an arbitrary field-name-keyed JSON body. `path` is the
  /// resource's collection path (e.g. `/publishers`).
  public func patchEntity<Attributes: Codable & Sendable>(
    path: String, id: String, token: String, fields: [String: String]
  ) async throws -> EntityPatchResult<Attributes> {
    try await withSpan("patch-entity") { _ in
      let body = try JSONEncoder().encode(fields)
      let (data, status) = try await send(
        method: "PATCH", path: "\(path)/\(id)", token: token, body: body)
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

  /// Lists a publisher/studio/person/license's version history, newest first - the generic
  /// counterpart of `fetchVolumeVersions(id:token:)`. `path` is the resource's collection path
  /// (e.g. `/publishers`).
  public func fetchEntityVersions<T: EntityVersionAttributes>(
    path: String, id: String, token: String
  ) async throws -> [T] {
    try await withSpan("fetch-entity-versions") { _ in
      let (data, status) = try await send(
        method: "GET", path: "\(path)/\(id)/versions", token: token, body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode([T].self, from: data)
    }
  }

  /// Fetches one publisher/studio/person/license version's full field snapshot - the generic
  /// counterpart of `fetchVolumeVersion(id:version:token:)`.
  public func fetchEntityVersion<T: EntityVersionAttributes>(
    path: String, id: String, version: Int, token: String
  ) async throws -> T {
    try await withSpan("fetch-entity-version") { _ in
      let (data, status) = try await send(
        method: "GET", path: "\(path)/\(id)/versions/\(version)", token: token, body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(T.self, from: data)
    }
  }

  /// Accepts a publisher/studio/person/license submitted version, in full or in part - the
  /// generic counterpart of `acceptVolumeVersion(id:version:token:fields:)`. Editor/admin only,
  /// enforced by catalog-api.
  public func acceptEntityVersion(
    path: String, id: String, version: Int, token: String, fields: [String]? = nil
  ) async throws -> ReviewVersionResult {
    try await withSpan("accept-entity-version") { _ in
      let body = try JSONEncoder().encode(AcceptVersionRequestBody(fields: fields))
      let (data, status) = try await send(
        method: "POST", path: "\(path)/\(id)/versions/\(version)/accept", token: token,
        body: body)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      return try JSONDecoder().decode(ReviewVersionResult.self, from: data)
    }
  }

  /// Rejects a publisher/studio/person/license submitted version in full, with an optional
  /// review note - the generic counterpart of `rejectVolumeVersion(id:version:token:note:)`.
  /// Editor/admin only, enforced by catalog-api.
  public func rejectEntityVersion(
    path: String, id: String, version: Int, token: String, note: String? = nil
  ) async throws -> ReviewVersionResult {
    try await withSpan("reject-entity-version") { _ in
      let body = try JSONEncoder().encode(RejectVersionRequestBody(note: note))
      let (data, status) = try await send(
        method: "POST", path: "\(path)/\(id)/versions/\(version)/reject", token: token,
        body: body)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      return try JSONDecoder().decode(ReviewVersionResult.self, from: data)
    }
  }

  /// Rolls a publisher/studio/person/license back (or forward) to an arbitrary existing version -
  /// the generic counterpart of `setCurrentVolumeVersion(id:version:token:)`. Admin only,
  /// enforced by catalog-api.
  public func setCurrentEntityVersion<T: EntityVersionAttributes>(
    path: String, id: String, version: Int, token: String
  ) async throws -> T {
    try await withSpan("set-current-entity-version") { _ in
      let (data, status) = try await send(
        method: "POST", path: "\(path)/\(id)/versions/\(version)/current", token: token,
        body: nil)
      guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode(T.self, from: data)
    }
  }
}
