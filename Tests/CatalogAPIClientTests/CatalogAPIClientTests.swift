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
}
