import Foundation

/// Error surfaced by any write call (PATCH/POST) when catalog-api returns a non-2xx status.
/// Decodes catalog-api's `apiv.ErrorVO` shape (`{"error": "...", "message": "..."}`) when
/// present, falling back to `nil` fields if the body doesn't match (e.g. a 404 with an empty
/// body).
public struct CatalogAPIError: Error, Sendable {
  public let statusCode: Int
  public let error: String?
  public let message: String?

  public init(statusCode: Int, error: String?, message: String?) {
    self.statusCode = statusCode
    self.error = error
    self.message = message
  }
}

/// Response to `PATCH /volumes/:id` when the caller's role applies the change directly
/// (admin/editor) - a JSON:API single-resource document, matching `fetchVolumes`'s shape.
public typealias VolumeDocument = JSONAPISingleDocument<VolumeAttributes>

/// Response to a `PATCH`/`finalize-session` call when the caller's role only submits the change
/// for review (submitter) - every entity type's write endpoints return this same shape (200 =
/// applied directly, 202 = submitted) since the version model replaced `proposed_changes`.
public struct SubmittedVersionResponse: Codable, Sendable {
  public let version: Int
  public let state: String
  public let message: String

  public init(version: Int, state: String, message: String) {
    self.version = version
    self.state = state
    self.message = message
  }
}

/// A `PATCH /volumes/:id` response is one of these two shapes, distinguished by catalog-api's
/// HTTP status (200 = applied, 202 = submitted) rather than by trying both decodes.
public enum VolumePatchResult: Sendable {
  case applied(VolumeDocument)
  case proposed(SubmittedVersionResponse)
}

/// A `PATCH /:type/:id` response for any of publisher/studio/person/license/system - the generic
/// counterpart of `VolumePatchResult`, parameterized by that type's attributes.
public enum EntityPatchResult<Attributes: Codable & Sendable>: Sendable {
  case applied(JSONAPISingleDocument<Attributes>)
  case proposed(SubmittedVersionResponse)
}

/// Response to `GET`/`POST /vocabularies/:type` - a shared, growable list (contribution types,
/// property names, formats). See durable-volume-editing's design.md.
public struct VocabularyResponse: Codable, Sendable {
  public let type: String
  public let values: [String]

  public init(type: String, values: [String]) {
    self.type = type
    self.values = values
  }
}

struct AddVocabularyValueRequestBody: Encodable {
  let value: String
}

struct PatchVolumeRequestBody: Encodable {
  let title: String?
  let description: String?
  let notes: String?
  let tags: [String]?
}
