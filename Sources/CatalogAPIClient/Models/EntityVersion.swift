import Foundation

/// One version of a publisher/studio/person/license's field snapshot, plus its submission/review
/// audit trail - the generic counterpart of `VolumeVersionAttributes` (see that type's doc
/// comment for why relationship/website fields are omitted: this is a safe subset for a
/// version-history view, not a lossy one, and `url.URL` fields don't round-trip through
/// `encoding/json` as plain strings the way this SDK's other models assume).
public protocol EntityVersionAttributes: Codable, Sendable, Identifiable {
  var id: String { get }
  var recordId: String { get }
  var version: Int { get }
  var state: String { get }
  var submittedBy: String { get }
  var submittedAt: Date { get }
}

public struct PublisherVersionAttributes: EntityVersionAttributes {
  public let id: String
  public let recordId: String
  public let version: Int
  public let name: String
  public let address: String
  public let notes: String
  public let state: String
  public let baseVersion: Int?
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?
  public let resultingVersion: Int?
}

public struct StudioVersionAttributes: EntityVersionAttributes {
  public let id: String
  public let recordId: String
  public let version: Int
  public let name: String
  public let notes: String
  public let state: String
  public let baseVersion: Int?
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?
  public let resultingVersion: Int?
}

public struct PersonVersionAttributes: EntityVersionAttributes {
  public let id: String
  public let recordId: String
  public let version: Int
  public let name: String
  public let notes: String
  public let state: String
  public let baseVersion: Int?
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?
  public let resultingVersion: Int?
}

public struct LicenseVersionAttributes: EntityVersionAttributes {
  public let id: String
  public let recordId: String
  public let version: Int
  public let title: String
  public let shortTitle: String
  public let licenseVersion: String
  public let deed: String
  public let legalCode: String
  public let status: String
  public let availability: String
  public let notes: String
  public let state: String
  public let baseVersion: Int?
  public let submittedBy: String
  public let submittedAt: Date
  public let reviewedBy: String?
  public let reviewedAt: Date?
  public let reviewNote: String?
  public let resultingVersion: Int?
}
