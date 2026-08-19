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
