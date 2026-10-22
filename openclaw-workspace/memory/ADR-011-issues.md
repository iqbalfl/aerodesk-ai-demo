# ADR-011 - Issue Tracking Tool (Fictional)

**Status:** Accepted  
**Date:** 2026-10-05

## Decision
Use GitHub Issues in the dedicated public demo repository for the sharing session.

## Reasons
- Issues are adjacent to source code and commits.
- No separate issue-tracker server consumes VPS resources.
- Easily demonstrates issue titles, labels, expected/actual results, and acceptance criteria.

## Trade-offs
- Issue templates and workflows are simpler than dedicated enterprise ticketing.
- Creating issues requires GitHub permission and should follow explicit approval.

## Access policy
Issue writes are restricted to the dedicated fictional demo repository. Never create an issue in a company production repository as part of this demo.
