# DB Change Workflow (Core)

Status: source-of-truth  
Owners: Engineering  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile, backend operations

## Goal
Eliminate manual schema drift and make DB changes reviewable/reproducible.

## Workflow
1. Draft SQL migration in `supabase/migrations/`.
2. Update `docs/core/DATA_MODEL.md` if field semantics/contract changed.
3. Update `docs/core/ARCHITECTURE.md` if flow/behavior changed.
4. Add/adjust ADR for major architecture decisions.
5. Apply and verify on staging.
6. Promote to production.

## Rules
- No schema/RLS/RPC changes should live only in Supabase UI history.
- Emergency UI changes must be backfilled into migration files.
- Migration file order is timestamp-based and immutable.

## Verification minimum
- Query-level sanity checks for new/changed columns.
- Flow-level check if purchase/ownership/deeplink behavior can be affected.
