# AGENTS: droptune-system

## Purpose
This repository is the cross-platform source of truth for architecture, data contracts, deep links, roadmap, and ADRs.

## Golden rules
1. Any cross-platform decision is documented here first.
2. Do not keep implementation-heavy web/mobile details in `docs/core/*`.
3. Platform specifics belong to `docs/platform/web/*` or `docs/platform/mobile/*`.
4. Never rewrite ADR history; supersede with a new ADR when a decision changes.

## Required update points
- `docs/core/ARCHITECTURE.md` for system flow/contract changes.
- `docs/core/DATA_MODEL.md` for schema semantics and field meaning changes.
- `docs/core/DEEP_LINKS.md` for deep-link contract changes.
- `docs/core/ROADMAP.md` for product/cross-platform milestone changes.
- `docs/adr/*` for major architectural decisions.
- `supabase/migrations/*` for schema/RLS/RPC/index/trigger changes.

## Change policy
- Small wording fixes: update file directly.
- Contract/behavior changes: update core doc + add/update ADR when needed.
- Platform execution details: update only corresponding platform doc.
- DB changes: add SQL migration + update DATA_MODEL semantics when affected.

## Review checklist for every PR
- Is this change cross-platform? If yes, is core doc updated?
- Is this decision architectural? If yes, is ADR updated/added?
- Are links in entrypoint docs still valid?
- Are statuses/dates updated where relevant?

## Database change policy (mandatory)
- Any schema/RLS/RPC/index/trigger change must be delivered via SQL migration files in `supabase/migrations/*`.
- No UI-only Supabase changes are accepted as final state.
- If emergency UI change was made, create migration backfill ASAP.
- For DB changes, require:
  1) migration file
  2) updated `docs/core/DATA_MODEL.md` when semantics/contract changed
  3) risk note + rollback/forward-fix strategy
  4) post-apply smoke-check notes
