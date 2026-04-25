# Supabase Migration Workflow

This folder is the versioned source of truth for database evolution.

## Structure
- `migrations/` — ordered SQL migrations
- `MIGRATION_POLICY.md` — process and safety rules

## Naming
Use sortable timestamp prefixes:
- `YYYYMMDDHHMMSS_description.sql`

Example:
- `20260425193000_add_background_color_to_albums.sql`

## Authoring rules
1. One logical change per migration file.
2. Prefer additive changes; avoid destructive SQL in the same PR as feature code.
3. Keep migrations idempotent where possible (`IF EXISTS` / `IF NOT EXISTS`).
4. If behavior contract changes, update:
   - `docs/core/DATA_MODEL.md`
   - `docs/core/ARCHITECTURE.md` (if flow changes)
   - ADR (for major architecture decisions)

## Apply flow (recommended)
1. Draft SQL migration.
2. Review SQL + contract docs update together.
3. Apply on staging.
4. Verify queries/flows.
5. Apply on production.

## Current state note
If legacy manual UI changes exist, first create a baseline migration snapshot file and mark it as adopted reference before adding new incremental migrations.
