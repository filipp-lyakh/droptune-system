# Migrations Folder

Put ordered SQL migration files here.

## File format
- Plain `.sql`
- UTF-8
- ASCII preferred for comments/identifiers

## Template snippet
```sql
-- Migration: YYYYMMDDHHMMSS_short_description
-- Context: why this change is needed
-- Safe to re-run: yes/no

BEGIN;

-- SQL changes

COMMIT;
```

## Baseline
If your current production schema was created manually in Supabase UI, add one baseline migration file documenting the current agreed schema state, then continue with incremental migrations only.
