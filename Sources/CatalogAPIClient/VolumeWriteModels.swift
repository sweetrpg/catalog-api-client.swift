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

/// Response to `PATCH /volumes/:id` when the caller's role only proposes the change
/// (submitter) - catalog-api returns this instead of applying anything.
public struct ProposedChangeSubmission: Codable, Sendable {
  public let proposalId: String
  public let status: String
  public let message: String

  public init(proposalId: String, status: String, message: String) {
    self.proposalId = proposalId
    self.status = status
    self.message = message
  }
}

/// A `PATCH /volumes/:id` response is one of these two shapes, distinguished by catalog-api's
/// HTTP status (200 = applied, 202 = proposed) rather than by trying both decodes.
public enum VolumePatchResult: Sendable {
  case applied(VolumeDocument)
  case proposed(ProposedChangeSubmission)
}

/// One changed field's live-at-submission-time and proposed values, plus its own review
/// outcome. `old`/`new` are decoded as `String` - catalog-api's proposed-change fields are all
/// simple string attributes (title/description/notes) for now; if a non-string field is ever
/// added to the diff, this will need to become a more general JSON-value type.
public struct FieldChange: Codable, Sendable {
  public let old: String?
  public let new: String?
  public let status: String

  public init(old: String?, new: String?, status: String) {
    self.old = old
    self.new = new
    self.status = status
  }
}

/// A submitter's proposed edit to a volume, pending admin/editor review. Mirrors catalog-api's
/// `proposedchanges.ProposedChange` JSON shape.
public struct ProposedChangeSummary: Codable, Sendable, Identifiable {
  public let id: String
  public let recordType: String
  public let recordId: String
  public let diff: [String: FieldChange]
  public let status: String
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?

  public init(
    id: String, recordType: String, recordId: String, diff: [String: FieldChange],
    status: String, submittedBy: String, submittedAt: Date, reviewedBy: String?,
    reviewedAt: Date?, reviewNote: String?
  ) {
    self.id = id
    self.recordType = recordType
    self.recordId = recordId
    self.diff = diff
    self.status = status
    self.submittedBy = submittedBy
    self.submittedAt = submittedAt
    self.reviewedBy = reviewedBy
    self.reviewedAt = reviewedAt
    self.reviewNote = reviewNote
  }
}

/// Response to an accept/reject review action.
public struct ReviewProposalResult: Codable, Sendable {
  public let proposalId: String
  public let status: String
  public let applied: [String]?
  public let rejected: [String]?
  public let conflicts: [String]?

  public init(
    proposalId: String, status: String, applied: [String]?, rejected: [String]?,
    conflicts: [String]?
  ) {
    self.proposalId = proposalId
    self.status = status
    self.applied = applied
    self.rejected = rejected
    self.conflicts = conflicts
  }
}

struct PatchVolumeRequestBody: Encodable {
  let title: String?
  let description: String?
  let notes: String?
}

struct AcceptProposalRequestBody: Encodable {
  let fields: [String]?
}

struct RejectProposalRequestBody: Encodable {
  let note: String?
}
