-- Migration: 20260606153000_add_admin_album_drafts_and_track_number_uniqueness
-- Context: add admin ingestion draft storage and enforce deterministic track numbering.
-- Safe to re-run: yes
--
-- Risk note:
-- - Unique index on tracks(album_id, track_number) will fail if duplicate track_number
--   already exists for one album. A pre-check raises a descriptive exception first.
-- - admin_album_drafts is backend-admin only: no anon/authenticated table privileges.
--
-- Smoke checks after apply:
-- - select id, status, payload from public.admin_album_drafts limit 1;
-- - verify has_table_privilege('authenticated', 'public.admin_album_drafts', 'SELECT') = false
-- - verify has_table_privilege('service_role', 'public.admin_album_drafts', 'SELECT') = true
-- - verify unique track numbers per album are enforced on public.tracks

BEGIN;

CREATE TABLE IF NOT EXISTS public.admin_album_drafts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status = ANY (ARRAY[
      'draft'::text,
      'uploading'::text,
      'ready_to_publish'::text,
      'publishing'::text,
      'published'::text,
      'failed'::text
    ])),
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  published_album_id uuid REFERENCES public.albums(id) ON DELETE SET NULL,
  last_error text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS admin_album_drafts_status_idx
  ON public.admin_album_drafts(status);

CREATE INDEX IF NOT EXISTS admin_album_drafts_created_by_idx
  ON public.admin_album_drafts(created_by);

CREATE INDEX IF NOT EXISTS admin_album_drafts_published_album_id_idx
  ON public.admin_album_drafts(published_album_id);

ALTER TABLE public.admin_album_drafts ENABLE ROW LEVEL SECURITY;

-- Backend-only access.
REVOKE ALL ON TABLE public.admin_album_drafts FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.admin_album_drafts TO service_role;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM (
      SELECT album_id, track_number
      FROM public.tracks
      GROUP BY album_id, track_number
      HAVING COUNT(*) > 1
    ) d
  ) THEN
    RAISE EXCEPTION
      'Cannot enforce unique (album_id, track_number): duplicate track numbers exist in public.tracks';
  END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS tracks_album_id_track_number_uidx
  ON public.tracks(album_id, track_number);

COMMIT;
