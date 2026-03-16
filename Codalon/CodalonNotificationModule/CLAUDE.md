# CodalonNotificationModule

## Responsibility
In-app alerts, local notifications, unread/read state,
alert-to-route navigation.

## Uses
- HelaiaNotify
- CodalonCoreModule

## Must not
- Generate alerts itself — consumes events from other modules
- Contain business logic
