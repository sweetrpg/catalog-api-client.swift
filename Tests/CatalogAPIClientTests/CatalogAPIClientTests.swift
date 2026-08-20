import Foundation
import XCTest

@testable import CatalogAPIClient

final class CatalogAPIClientTests: XCTestCase {

  func testDecodesVolumeDocumentWithRelationships() throws {
    // Single-line: decodeFirstLine truncates at the first newline (the #121 workaround under
    // test separately below), so fixtures for the happy path must not contain embedded newlines.
    let json = """
      {"data": [{"id": "vol-1", "type": "volumes", "attributes": {"title": "Player's Handbook", "description": "Core rulebook", "notes": null, "tags": [{"name": "core", "value": null}]}, "relationships": {"system": {"data": {"id": "sys-1", "type": "systems"}}, "publisher": {"data": [{"id": "pub-1", "type": "publishers"}]}}}]}
      """
    let doc: JSONAPIDocument<VolumeAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))

    XCTAssertEqual(doc.data.count, 1)
    let resource = doc.data[0]
    XCTAssertEqual(resource.attributes.title, "Player's Handbook")
    XCTAssertEqual(resource.attributes.tags?.first?.displayName, "core")
    XCTAssertEqual(resource.relationships?["system"]?.data?.ids, ["sys-1"])
    XCTAssertEqual(resource.relationships?["publisher"]?.data?.ids, ["pub-1"])
  }

  func testDecodesVolumePropertiesAttribute() throws {
    let json = """
      {"data": [{"id": "vol-1", "type": "volumes", "attributes": {"title": null, "description": null, "notes": null, "tags": null, "properties": [{"name": "Page count", "kind": "string", "value": "320"}]}, "relationships": null}]}
      """
    let doc: JSONAPIDocument<VolumeAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))
    XCTAssertEqual(doc.data[0].attributes.properties?.first?.name, "Page count")
    XCTAssertEqual(doc.data[0].attributes.properties?.first?.value, "320")
  }

  func testDecodesVolumeFormatAttribute() throws {
    let json = """
      {"data": [{"id": "vol-1", "type": "volumes", "attributes": {"title": null, "description": null, "notes": null, "tags": null, "format": "Hardcover"}, "relationships": null}]}
      """
    let doc: JSONAPIDocument<VolumeAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))
    XCTAssertEqual(doc.data[0].attributes.format, "Hardcover")
  }

  func testDecodesVolumeSampleAssetIdsAttribute() throws {
    let json = """
      {"data": [{"id": "vol-1", "type": "volumes", "attributes": {"title": null, "description": null, "notes": null, "tags": null, "sampleAssetIds": ["vol-1-0", "vol-1-1"]}, "relationships": null}]}
      """
    let doc: JSONAPIDocument<VolumeAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))
    XCTAssertEqual(doc.data[0].attributes.sampleAssetIds, ["vol-1-0", "vol-1-1"])
  }

  func testDecodesToManyRelationship() throws {
    let json = """
      {"data": [{"id": "vol-1", "type": "volumes", "attributes": {"title": null, "description": null, "notes": null, "tags": null}, "relationships": {"publisher": {"data": [{"id": "pub-1", "type": "publishers"}, {"id": "pub-2", "type": "publishers"}]}}}]}
      """
    let doc: JSONAPIDocument<VolumeAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))
    XCTAssertEqual(doc.data[0].relationships?["publisher"]?.data?.ids, ["pub-1", "pub-2"])
  }

  /// Regression test for sweetrpg/catalog-api#121: a stray JSON object appended after a
  /// newline (catalog-api leaking an internal cache-write error into the response body) must
  /// not break decoding of the valid document that precedes it.
  func testDecodeFirstLineIgnoresTrailingMalformedObject() throws {
    let json = """
      {"data": [{"id": "n-1", "type": "systems", "attributes": {"name": "D&D 5e", "title": null}, "relationships": null}]}
      {"error": "redis: connection refused", "this is not valid JSON at all
      """
    let doc: JSONAPIDocument<NamedAttributes> = try CatalogAPIClient.decodeFirstLine(
      Data(json.utf8))
    XCTAssertEqual(doc.data.first?.attributes.displayName, "D&D 5e")
  }

  func testDecodeFirstLineFailsOnMalformedFirstLine() {
    let json = "{not json"
    XCTAssertThrowsError(
      try CatalogAPIClient.decodeFirstLine(Data(json.utf8)) as JSONAPIDocument<NamedAttributes>)
  }

  func testNamedAttributesDisplayNameFallsBackToTitle() {
    let attrs = try! JSONDecoder().decode(
      NamedAttributes.self, from: Data(#"{"name": null, "title": "Some Title"}"#.utf8))
    XCTAssertEqual(attrs.displayName, "Some Title")
  }

  func testPersonAttributesDisplayNamePrefersFullName() {
    let attrs = try! JSONDecoder().decode(
      PersonAttributes.self,
      from: Data(
        #"{"name": null, "fullName": "Gary Gygax", "firstName": "Gary", "lastName": "Gygax"}"#
          .utf8))
    XCTAssertEqual(attrs.displayName, "Gary Gygax")
  }

  func testPublisherAttributesDecodesFullShape() {
    let attrs = try! JSONDecoder().decode(
      PublisherAttributes.self,
      from: Data(
        #"{"name": "TSR", "address": "Lake Geneva, WI", "website": "https://example.com", "notes": null, "tags": null}"#
          .utf8))
    XCTAssertEqual(attrs.displayName, "TSR")
    XCTAssertEqual(attrs.address, "Lake Geneva, WI")
  }

  func testStudioAttributesDisplayNameFallsBackToUntitled() {
    let attrs = try! JSONDecoder().decode(
      StudioAttributes.self, from: Data(#"{"name": null}"#.utf8))
    XCTAssertEqual(attrs.displayName, "Untitled")
  }

  func testLicenseAttributesDecodesFullShape() {
    // catalog-api emits snake_case for short_title/legal_code (confirmed live against dev) -
    // this fixture previously used camelCase, matching a decode bug instead of catching it: the
    // two fields silently decoded to nil on every real request without this test noticing.
    let attrs = try! JSONDecoder().decode(
      LicenseAttributes.self,
      from: Data(
        #"""
        {"title": "CC BY 4.0", "short_title": "CC-BY-4.0", "version": "4.0", "deed": "https://example.com/deed",
         "legal_code": "https://example.com/legal", "website": null, "status": "active",
         "availability": "public", "notes": null, "properties": null, "tags": null}
        """#
        .utf8))
    XCTAssertEqual(attrs.displayName, "CC BY 4.0")
    XCTAssertEqual(attrs.status, "active")
    XCTAssertEqual(attrs.shortTitle, "CC-BY-4.0")
    XCTAssertEqual(attrs.legalCode, "https://example.com/legal")
  }

  func testReviewAttributesDisplayFieldsFallBackAcrossAliases() {
    let attrs = try! JSONDecoder().decode(
      ReviewAttributes.self,
      from: Data(
        #"{"authorName": null, "author": null, "name": "A. Reader", "rating": null, "score": 4.5, "body": null, "text": "Great book", "review": null, "content": null}"#
          .utf8))
    XCTAssertEqual(attrs.displayAuthor, "A. Reader")
    XCTAssertEqual(attrs.displayRating, 4.5)
    XCTAssertEqual(attrs.displayText, "Great book")
  }

  // MARK: - Volume write models

  func testPatchVolumeRequestBodyEncodesOnlyProvidedFields() throws {
    // Swift's synthesized Encodable uses encodeIfPresent for Optional properties, so nil
    // fields are omitted from the JSON entirely rather than written as `null` - either shape
    // decodes to nil on catalog-api's Go side (an absent key and a JSON null both unmarshal to
    // a nil *string), so this just documents the actual wire shape.
    let body = PatchVolumeRequestBody(title: "New Title", description: nil, notes: nil)
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(decoded?["title"] as? String, "New Title")
    XCTAssertNil(decoded?["description"])
    XCTAssertNil(decoded?["notes"])
  }

  func testVolumePatchResultDecodesAppliedResponse() throws {
    let json = """
      {"data": {"id": "vol-1", "type": "volumes", "attributes": {"title": "Edited", "description": "d", "notes": null, "tags": null}, "relationships": null}}
      """
    let doc: VolumeDocument = try CatalogAPIClient.decodeFirstLine(Data(json.utf8))
    XCTAssertEqual(doc.data.id, "vol-1")
    XCTAssertEqual(doc.data.attributes.title, "Edited")
  }

  func testVocabularyResponseDecodes() throws {
    let json = """
      {"type": "contribution-type", "values": ["Author", "Illustrator"]}
      """
    let vocabulary = try JSONDecoder().decode(VocabularyResponse.self, from: Data(json.utf8))
    XCTAssertEqual(vocabulary.type, "contribution-type")
    XCTAssertEqual(vocabulary.values, ["Author", "Illustrator"])
  }

  func testCatalogStatsDecodes() throws {
    let json = """
      {
        "volumes": {"count": 42, "last_updated": "2026-08-19T01:22:39Z",
          "most_recent": {"id": "vol-1", "name": "A Glorious Death"}},
        "publishers": {"count": 3, "last_updated": null, "most_recent": null},
        "studios": {"count": 3, "last_updated": null, "most_recent": null},
        "persons": {"count": 3, "last_updated": null, "most_recent": null},
        "licenses": {"count": 3, "last_updated": null, "most_recent": null},
        "systems": {"count": 3, "last_updated": null, "most_recent": null}
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let stats = try decoder.decode(CatalogStats.self, from: Data(json.utf8))
    XCTAssertEqual(stats.volumes.count, 42)
    XCTAssertNotNil(stats.volumes.lastUpdated)
    XCTAssertEqual(stats.volumes.mostRecent?.id, "vol-1")
    XCTAssertEqual(stats.volumes.mostRecent?.name, "A Glorious Death")
  }

  func testCatalogStatsDecodesEmptyType() throws {
    let json = """
      {
        "volumes": {"count": 0, "last_updated": null, "most_recent": null},
        "publishers": {"count": 0, "last_updated": null, "most_recent": null},
        "studios": {"count": 0, "last_updated": null, "most_recent": null},
        "persons": {"count": 0, "last_updated": null, "most_recent": null},
        "licenses": {"count": 0, "last_updated": null, "most_recent": null},
        "systems": {"count": 0, "last_updated": null, "most_recent": null}
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let stats = try decoder.decode(CatalogStats.self, from: Data(json.utf8))
    XCTAssertEqual(stats.licenses.count, 0)
    XCTAssertNil(stats.licenses.lastUpdated)
    XCTAssertNil(stats.licenses.mostRecent)
  }

  func testAddVocabularyValueRequestBodyEncodesValue() throws {
    let body = AddVocabularyValueRequestBody(value: "Cartographer")
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(decoded?["value"] as? String, "Cartographer")
  }

  func testSubmittedVersionResponseDecodes() throws {
    let json = """
      {"version": 2, "state": "submitted", "message": "Change submitted for review"}
      """
    let submission = try JSONDecoder().decode(SubmittedVersionResponse.self, from: Data(json.utf8))
    XCTAssertEqual(submission.version, 2)
    XCTAssertEqual(submission.state, "submitted")
  }

  func testVolumeVersionAttributesDecodesWithISO8601Dates() throws {
    let json = """
      {
        "id": "ver-2",
        "recordId": "vol-1",
        "version": 2,
        "title": "Submitted Title",
        "description": "d",
        "notes": "",
        "format": "",
        "coverAssetId": "",
        "sampleAssetIds": [],
        "state": "submitted",
        "baseVersion": 1,
        "submittedBy": "auth0|submitter",
        "submittedAt": "2026-08-13T05:00:00Z",
        "reviewedBy": null,
        "reviewedAt": null,
        "reviewNote": null,
        "resultingVersion": null,
        "systems": [],
        "properties": []
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let version = try decoder.decode(VolumeVersionAttributes.self, from: Data(json.utf8))
    XCTAssertEqual(version.version, 2)
    XCTAssertEqual(version.state, "submitted")
    XCTAssertEqual(version.baseVersion, 1)
    XCTAssertNil(version.reviewedAt)
  }

  func testVolumeVersionAttributesToleratesNullSampleAssetIds() throws {
    let json = """
      {
        "id": "ver-2",
        "recordId": "vol-1",
        "version": 2,
        "title": "Submitted Title",
        "description": "d",
        "notes": "",
        "format": "",
        "coverAssetId": "",
        "sampleAssetIds": null,
        "state": "submitted",
        "baseVersion": 1,
        "submittedBy": "auth0|submitter",
        "submittedAt": "2026-08-13T05:00:00Z",
        "reviewedBy": null,
        "reviewedAt": null,
        "reviewNote": null,
        "resultingVersion": null
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let version = try decoder.decode(VolumeVersionAttributes.self, from: Data(json.utf8))
    XCTAssertEqual(version.sampleAssetIds, [])
  }

  func testAcceptVersionRequestBodyOmittedFieldsMeansAcceptAll() throws {
    let body = AcceptVersionRequestBody(fields: nil)
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertNil(decoded?["fields"])
  }

  func testAcceptVersionRequestBodyEncodesFieldSubset() throws {
    let body = AcceptVersionRequestBody(fields: ["title"])
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(decoded?["fields"] as? [String], ["title"])
  }

  func testReviewVersionResultDecodesConflicts() throws {
    let json = """
      {"version": 3, "state": "live", "conflicts": ["title"]}
      """
    let result = try JSONDecoder().decode(ReviewVersionResult.self, from: Data(json.utf8))
    XCTAssertEqual(result.version, 3)
    XCTAssertEqual(result.state, "live")
    XCTAssertEqual(result.conflicts, ["title"])
  }

  func testDecodeErrorParsesCatalogAPIErrorBody() {
    let json = """
      {"error": "already_reviewed", "message": "This proposed change has already been reviewed"}
      """
    let error = CatalogAPIClient.decodeError(Data(json.utf8), statusCode: 409)
    XCTAssertEqual(error.statusCode, 409)
    XCTAssertEqual(error.error, "already_reviewed")
    XCTAssertEqual(error.message, "This proposed change has already been reviewed")
  }

  func testDecodeErrorFallsBackGracefullyOnEmptyBody() {
    let error = CatalogAPIClient.decodeError(Data(), statusCode: 404)
    XCTAssertEqual(error.statusCode, 404)
    XCTAssertNil(error.error)
  }
}
