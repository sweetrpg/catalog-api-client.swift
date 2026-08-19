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

  enum CodingKeys: String, CodingKey {
    case id, recordId, version, title, description, notes, format, coverAssetId, sampleAssetIds,
      state, baseVersion, submittedBy, submittedAt, reviewedBy, reviewedAt, reviewNote,
      resultingVersion
  }

  // catalog-api has been observed emitting `sample_asset_ids: null` on some version records
  // (rather than an omitted key or `[]`) - the synthesized decoder for a non-optional `[String]`
  // rejects that outright with a valueNotFound error, breaking version-history/pending-review
  // fetches for the affected volume entirely. `decodeIfPresent` returns nil for an explicit JSON
  // null the same way it does for a missing key, so this tolerates both.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    recordId = try container.decode(String.self, forKey: .recordId)
    version = try container.decode(Int.self, forKey: .version)
    title = try container.decode(String.self, forKey: .title)
    description = try container.decode(String.self, forKey: .description)
    notes = try container.decode(String.self, forKey: .notes)
    format = try container.decode(String.self, forKey: .format)
    coverAssetId = try container.decode(String.self, forKey: .coverAssetId)
    sampleAssetIds = try container.decodeIfPresent([String].self, forKey: .sampleAssetIds) ?? []
    state = try container.decode(String.self, forKey: .state)
    baseVersion = try container.decodeIfPresent(Int.self, forKey: .baseVersion)
    submittedBy = try container.decode(String.self, forKey: .submittedBy)
    submittedAt = try container.decode(Date.self, forKey: .submittedAt)
    reviewedBy = try container.decodeIfPresent(String.self, forKey: .reviewedBy)
    reviewedAt = try container.decodeIfPresent(Date.self, forKey: .reviewedAt)
    reviewNote = try container.decodeIfPresent(String.self, forKey: .reviewNote)
    resultingVersion = try container.decodeIfPresent(Int.self, forKey: .resultingVersion)
  }
}
