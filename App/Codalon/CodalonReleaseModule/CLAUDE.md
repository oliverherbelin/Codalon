# CodalonReleaseModule

## Responsibility
Release model, release checklist, blockers, readiness scoring,
release cockpit, launch flow, export.

## Uses
- HelaiaStorage
- HelaiaNotify
- HelaiaShare
- CodalonCoreModule

## Must not
- Contain ASC API calls — reads ASC data via CodalonAppStoreModule events
- Contain GitHub API calls — reads GitHub data via CodalonGitHubModule events
