# ADR-007 - Database Technology Decision (Fictional)

**Status:** Accepted for future implementation  
**Date:** 2026-10-01  
**Owners:** Backend Team and Product Analytics

## Context
AeroDesk needs consistent customer and airport-operation reporting, relationships between customers and activities, transaction history, and predictable SQL joins.

## Decision
Use **PostgreSQL** as the planned primary transactional/reporting database when the production architecture is implemented.

## Alternatives considered
- MongoDB: document flexibility, but cross-entity reporting would be less natural for this workload.
- MySQL: viable SQL option; PostgreSQL was preferred for the team's existing reporting queries and data-type requirements.
- SQLite: ideal for a prototype or local development, but not the target multi-user service datastore.

## Rationale
- Relational constraints simplify data consistency for linked entities.
- SQL joins and reporting align with downstream analytics.
- Migration tooling is mature.

## Trade-offs
- Database schema changes require planned migrations.
- PostgreSQL administration is an operational responsibility.
- This decision may be revisited as usage grows.

## IMPORTANT: actual implementation state
**The currently running AeroDesk demo API does not use PostgreSQL.** Customer records are generated in memory. ADR-007 is an architectural decision for the hypothetical future implementation. Never claim the application already connects to PostgreSQL without separate evidence.
