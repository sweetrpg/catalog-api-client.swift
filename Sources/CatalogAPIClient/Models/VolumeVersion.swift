import Foundation

/// One version of a volume's full field snapshot, plus its submission/review audit trail.
/// Decoded from catalog-api's plain-JSON version endpoints (`GET /volumes/:id/versions[/:version]`,
/// the accept/reject/rollback responses) - not JSON:API, unlike `fetchVolumes`/`patchVolume`.
///
/// Relationship fields (`systems`/`publishers`/`studios`/`licenses`/`properties`/`tags`) aren't
/// decoded here - domain model types belong in `catalog-objects.swift` per this package's scope,
/// and a version-history view only needs the fields below. `Codable` silently ignores JSON keys
/// with no matching property, so this is a safe subset rather than a lossy one.
public struct VolumeVersionAttributes: Codable, Sendable, Identifiable {
  public let id: String
  public let recordId: String
  public let version: Int
  public let title: String
  public let description: String
  public let notes: String
  public let format: String
  public let coverAssetId: String
  public let sampleAssetIds: [String]
  public let state: String
  public let baseVersion: Int?
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?
  public let resultingVersion: Int?

  public init(
    id: String, recordId: String, version: Int, title: String, description: String,
    notes: String, format: String, coverAssetId: String, sampleAssetIds: [String], state: String,
    baseVersion: Int?, submittedBy: String, submittedAt: Date, reviewedBy: String?,
    reviewedAt: Date?, reviewNote: String?, resultingVersion: Int?
  ) {
    self.id = id
    self.recordId = recordId
    self.version = version
    self.title = title
    self.description = description
    self.notes = notes
    self.format = format
    self.coverAssetId = coverAssetId
    self.sampleAssetIds = sampleAssetIds
    self.state = state
    self.baseVersion = baseVersion
    self.submittedBy = submittedBy
    self.submittedAt = submittedAt
    self.reviewedBy = reviewedBy
    self.reviewedAt = reviewedAt
    self.reviewNote = reviewNote
    self.resultingVersion = resultingVersion
  }
}
