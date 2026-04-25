# Chat Bootstrap (System/Core)

Status: process  
Last updated: 2026-04-25

Use this file as the first entrypoint for any new chat/agent session touching cross-platform decisions.

## Required read order
1. `core/ARCHITECTURE.md`
2. `core/DATA_MODEL.md`
3. `core/DEEP_LINKS.md`
4. `core/ROADMAP.md`
5. `core/BUSINESS_RULES.md`
6. `core/DB_CHANGE_WORKFLOW.md`
7. `adr/README.md`

## Fast rules
- Cross-platform behavior/contract changes: update `docs/core/*` first.
- DB changes: migration-first only (`supabase/migrations/*`).
- Platform-specific implementation notes belong in `docs/platform/*`.
