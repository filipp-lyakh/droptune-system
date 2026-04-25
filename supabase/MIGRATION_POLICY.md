# Migration Policy

Status: active  
Last updated: 2026-04-25

## Core policy
- Schema, RLS, RPC, trigger, and index changes must be delivered through SQL migration files in `supabase/migrations/`.
- Supabase UI is allowed for inspection and emergency operations only; emergency UI changes must be backfilled into a migration file ASAP.

## Required artifacts per DB change
1. SQL migration file
2. Data-contract docs update (if semantics changed)
3. Verification notes (what was checked after apply)

## Safety requirements
- Avoid destructive operations without explicit approval and rollback plan.
- Separate risky data backfills from schema shape changes when possible.
- Never rely on memory/chat history for DB state; migration files are source-of-truth.

## Rollback expectation
Each migration PR should include at least one of:
- Safe rollback SQL
- Explicit statement why rollback is not safe and what forward-fix strategy is

## Checklist before merge
- [ ] Migration filename uses timestamp prefix
- [ ] SQL reviewed
- [ ] Core docs updated if contract changed
- [ ] Staging verification plan is present
