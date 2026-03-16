# CodalonDashboardModule

## Responsibility
Main project cockpit. Context-aware widgets. Health surface.
Current priorities. Live summaries. Context-driven UI engine.

## Uses
- HelaiaDesign
- HelaiaAnalytics
- HelaiaNotify
- HelaiaEngine (EventBus)
- CodalonCoreModule

## Must not
- Own any data — reads only from other modules via EventBus or services
- Contain persistence logic
