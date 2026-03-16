# CodalonApp

## Responsibility
App entry point. Bootstraps HelaiaEngine, registers all modules,
sets up root window and navigation shell.

## Uses
- HelaiaEngine (ModuleRegistry, ServiceContainer, HelaiaRouter)
- HelaiaLogger
- HelaiaAnalytics

## Must not
- Contain any business logic
- Contain any UI beyond the root shell
- Import product modules directly — use routing only
