import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension CatalogAPIClient {

  /// Lists a shared vocabulary's values (`contribution-type`, `property-name`, or `format`) -
  /// any edit-capable role, enforced by catalog-api. `format` is further restricted to
  /// editor/admin - a submitter's token gets a 403, same as any other role check here.
  public func fetchVocabulary(type: String, token: String) async throws -> VocabularyResponse {
    let (data, status) = try await send(
      method: "GET", path: "/vocabularies/\(type)", token: token, body: nil)
    guard status == 200 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(VocabularyResponse.self, from: data)
  }

  /// Adds a new value to a shared vocabulary - editor/admin only for every type, enforced by
  /// catalog-api. Returns the vocabulary's full value list after the add.
  public func addVocabularyValue(type: String, value: String, token: String) async throws
    -> VocabularyResponse
  {
    let body = try JSONEncoder().encode(AddVocabularyValueRequestBody(value: value))
    let (data, status) = try await send(
      method: "POST", path: "/vocabularies/\(type)", token: token, body: body)
    guard status == 201 else { throw Self.decodeError(data, statusCode: status) }
    return try JSONDecoder().decode(VocabularyResponse.self, from: data)
  }
}
