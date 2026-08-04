# catalog-api-client.swift

[![Coverage](https://img.shields.io/endpoint?url=https://sweetrpg.github.io/catalog-api-client.swift/coverage-badge.json)](https://sweetrpg.github.io/catalog-api-client.swift/)

Swift client SDK for `catalog-api`: JSON:API fetch and decoding for volumes, credits, and
reviews.

## Scope

`CatalogAPIClient` covers HTTP fetch and JSON:API response decoding only - not domain model
types (those live in `catalog-objects.swift`) and not response caching (left to the consumer,
since caching backends and policies vary by app). This is deliberately different from
`admin-api-client.swift`, which bakes in caching for a cross-cutting concern every consumer must
handle identically; a domain API client has no such cross-cutting requirement.

`fetchVolumes`, `fetchCredits`, `fetchReviews`, and the name-map fetchers each return decoded
JSON:API resources. Response parsing defensively reads only the first line of the response body
to work around [`sweetrpg/catalog-api#121`](https://github.com/sweetrpg/catalog-api/issues/121),
where a malformed error can be appended after a valid JSON document.

## Usage

```swift
import CatalogAPIClient

let client = CatalogAPIClient(baseURL: ProcessInfo.processInfo.environment["CATALOG_API_URL"]!)
let volumes = try await client.fetchVolumes()
```
