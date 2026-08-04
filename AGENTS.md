# AGENTS.md

This file provides guidance to Claude Code, Codex, GitHub Copilot, and other coding agents
working in this repository.

## About This Project

`catalog-api-client.swift` is the Swift client SDK for `catalog-api` (`sweetrpg/catalog-api`):
JSON:API fetch and decoding for volumes, credits, reviews, and name maps. It's an extraction of
`catalog-web`'s previously hand-rolled `CatalogAPIClient`, done via `sweetrpg/platform`'s
`api-client-sdks` OpenSpec change so a second Swift/Vapor consumer of `catalog-api` doesn't have
to duplicate it. `catalog-web` is its first consumer.

Scope is deliberately narrow: HTTP fetch + JSON:API decoding only. Domain model types belong in
`catalog-objects.swift`, not here. Response caching is left to the consumer (unlike
`admin-api-client.swift`, which bakes in caching for a cross-cutting concern every consumer must
handle identically - a domain API client has no such requirement, so caching policy is an
app-level decision).

The response parsing includes a defensive workaround for
[`sweetrpg/catalog-api#121`](https://github.com/sweetrpg/catalog-api/issues/121) (a malformed
error appended after a valid JSON document in some responses) - see the code comment at the call
site before changing that parsing logic.

## Committing Code

[Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`.

## Branches and Workflow

Git-flow (see `docs/git-flow.md` in `sweetrpg/platform`): `develop` is the integration branch,
`master` reflects the latest release. Feature/fix branches off `develop`, PR back into `develop`.

## Running Checks Locally

```bash
swift build
swift test
```
