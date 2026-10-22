# AeroDesk - AI Second Brain (fictional demo)

This workspace contains curated demo-only project memory for the sharing session. Answer in Bahasa Indonesia.

## Durable decisions
- **ADR-007**: the team chose **PostgreSQL for a proposed future implementation** because relational reporting and data integrity matter. Alternatives included MongoDB, MySQL and SQLite. Trade-offs: migrations and database operations. Source: `memory/ADR-007-postgresql.md`.
- **ADR-011**: use GitHub Issues instead of hosting a separate issue tracker for the demo, minimizing infrastructure. Source: `memory/ADR-011-issues.md`.

## QA requirement
- **QA-012**: `/api/customers?page=1&limit=3` must return three results. Current demo bug returns ten items while reporting meta.limit=3. Source: `memory/QA-012-pagination.md`.

## Evidence & limitations
- The running Express app uses in-memory fixture data; PostgreSQL is **NOT installed or connected by this demo application**.
- The sample API code is in `app/server.js` of the dedicated fictional GitHub repo.
- GitHub Issues must only be created in the explicitly authorized demo repository after presenter approval.
- Do not invent a GitHub issue URL; only show one returned by a successful actual creation tool call.
