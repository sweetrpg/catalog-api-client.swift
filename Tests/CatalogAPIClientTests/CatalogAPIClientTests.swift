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
    let attrs = try! JSONDecoder().decode(
      LicenseAttributes.self,
      from: Data(
        #"""
        {"title": "CC BY 4.0", "shortTitle": "CC-BY-4.0", "version": "4.0", "deed": "https://example.com/deed",
         "legalCode": "https://example.com/legal", "website": null, "status": "active",
         "availability": "public", "notes": null, "tags": null}
        """#
        .utf8))
    XCTAssertEqual(attrs.displayName, "CC BY 4.0")
    XCTAssertEqual(attrs.status, "active")
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

  func testAcceptProposalRequestBodyOmittedFieldsMeansAcceptAll() throws {
    let body = AcceptProposalRequestBody(fields: nil)
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertNil(decoded?["fields"])
  }

  func testAcceptProposalRequestBodyEncodesFieldSubset() throws {
    let body = AcceptProposalRequestBody(fields: ["title"])
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(decoded?["fields"] as? [String], ["title"])
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

  func testAddVocabularyValueRequestBodyEncodesValue() throws {
    let body = AddVocabularyValueRequestBody(value: "Cartographer")
    let data = try JSONEncoder().encode(body)
    let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(decoded?["value"] as? String, "Cartographer")
  }

  func testProposedChangeSubmissionDecodes() throws {
    let json = """
      {"proposalId": "abc123", "status": "pending", "message": "Change proposed for review"}
      """
    let submission = try JSONDecoder().decode(ProposedChangeSubmission.self, from: Data(json.utf8))
    XCTAssertEqual(submission.proposalId, "abc123")
    XCTAssertEqual(submission.status, "pending")
  }

  func testProposedChangeSummaryDecodesWithISO8601Dates() throws {
    let json = """
      {
        "id": "prop-1",
        "recordType": "volume",
        "recordId": "vol-1",
        "diff": {"title": {"old": "Old", "new": "New", "status": "pending"}},
        "status": "pending",
        "submittedBy": "auth0|submitter",
        "submittedAt": "2026-08-11T05:00:00Z",
        "reviewedBy": null,
        "reviewedAt": null,
        "reviewNote": null
      }
      """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let summary = try decoder.decode(ProposedChangeSummary.self, from: Data(json.utf8))
    XCTAssertEqual(summary.id, "prop-1")
    XCTAssertEqual(summary.diff["title"]?.old, "Old")
    XCTAssertEqual(summary.diff["title"]?.new, "New")
    XCTAssertNil(summary.reviewedAt)
  }

  func testReviewProposalResultDecodesConflicts() throws {
    let json = """
      {"proposalId": "prop-1", "status": "pending", "applied": [], "rejected": [], "conflicts": ["title"]}
      """
    let result = try JSONDecoder().decode(ReviewProposalResult.self, from: Data(json.utf8))
    XCTAssertEqual(result.conflicts, ["title"])
    XCTAssertEqual(result.applied, [])
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
