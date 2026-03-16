# CodalonAppStoreModule

## Responsibility
App Store Connect authentication, app linking, builds,
TestFlight, metadata completeness, readiness contribution.

## Uses
- HelaiaKeychain
- HelaiaLogger
- CodalonCoreModule

## Must not
- Contain release UI — feeds data into CodalonReleaseModule via events
- Store credentials anywhere except HelaiaKeychain
