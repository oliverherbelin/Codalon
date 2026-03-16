# CodalonSettingsModule

## Responsibility
App settings, integration settings, AI settings,
notifications settings, feature flags, diagnostics.

## Uses
- HelaiaEngine
- HelaiaDesign
- HelaiaAI
- HelaiaSync
- CodalonCoreModule

## Must not
- Contain integration logic — links to connection flows in other modules
- Contain persistence beyond settings values
