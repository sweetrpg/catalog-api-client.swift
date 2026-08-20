## [0.4.1] - 2026-08-20

Corrects a mis-versioned release: two independent sessions each fixed the same
Contribution.roles bug, and one merged from a stale pre-0.4.0 branch, causing the
release automation to compute 0.0.13 - a downgrade that broke catalog-web's
`from: "0.4.0"` SwiftPM pin. No code change from what 0.0.13 published; version
number only.

### 🐛 Bug Fixes

- *(contribution)* Decode roles instead of nonexistent role/credit/title fields
- *(contribution)* Decode the real roles array, not nonexistent role/credit/title

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v1.0.0
- *(release)* Merge master into develop after v0.4.0
- *(release)* Merge master into develop after v0.0.12
## [0.0.12] - 2026-08-16
## [0.4.0] - 2026-08-19

### 🚀 Features

- *(stats)* Replace volume-only CatalogStats with per-type shape

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v0.3.1
## [0.3.1] - 2026-08-19

### 🐛 Bug Fixes

- *(volume-version)* Tolerate a null sample_asset_ids in version records

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v0.3.0
## [0.3.0] - 2026-08-19

### 🚀 Features

- *(stats)* Add fetchCatalogStats() for GET /stats

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v0.2.1
## [0.2.1] - 2026-08-18

### 🐛 Bug Fixes

- *(license)* Add CodingKeys for short_title/legal_code

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v0.2.0
## [0.2.0] - 2026-08-18

### 🚀 Features

- *(license)* Expose properties attribute on LicenseAttributes

### 🐛 Bug Fixes

- *(tracing)* Actually inject trace context into outgoing requests

### ⚙️ Miscellaneous Tasks

- *(release)* Merge master into develop after v0.1.0
## [0.1.0] - 2026-08-18

### 🚀 Features

- Generic entity version endpoints, remove proposed_changes-based methods
- Generic entity version endpoints, port onto reorganized file layout

### 🐛 Bug Fixes

- *(ci)* Update workflows to use new release procedure

### 💼 Other

- Catch up with develop (reorg+tracing) after reconciling task-8.1 work

### 🚜 Refactor

- *(tracing)* Use kebab-case for span names

### 📚 Documentation

- Add initial CHANGELOG.md file

### 🎨 Styling

- Swift-format

### ⚙️ Miscellaneous Tasks

- *(ci)* Replace CI/PR workflows with standard
- Remove bump-version workflow
