# Droptune Data Model (Supabase / Postgres)

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-06-06
Consumers: droptune-web, droptune_mobile

Schema baseline: `supabase/migrations/20260425210000_baseline.sql`
Current alignment migration: `supabase/migrations/20260504195200_align_data_model_v1.sql`

## Core tables (current)

### albums
- id (uuid, pk)
- title (text)
- artist_name (text)
- cover_image_url (text, nullable)
- price (numeric, nullable)
- supply_total (integer, nullable)
- release_year (integer, nullable)
- gallery_description (text, nullable)
- video_embed_url (text, nullable)
- hero_background_color (text, nullable)
- background_color (text, nullable)

Notes:
- `background_color` is web album page + hero background (`#RRGGBB` or `RRGGBB`, normalized on client).
- `hero_background_color` is optional gallery modal backdrop tint on web and follows the same color format.
- `supply_total` is display/catalog supply metadata. Copy issuance is still enforced by `album_copies` availability.

### tracks
- id (uuid, pk)
- album_id (uuid, fk -> albums.id)
- title (text)
- audio_url (text)
- track_number (bigint/integer-like)

Notes:
- For admin ingestion, `track_number` must be unique within one album (`album_id + track_number` uniqueness is required at DB level).

### purchases (legacy/MVP source in some flows)
- id (uuid, pk)
- user_identifier (uuid)
- album_id (uuid)
- created_at (timestamp)

### art_containers
- id (uuid, pk)
- album_id (uuid, nullable/optional)
- track_id (uuid)
- type (text)
- content_url (text)
- meta (jsonb)
- order (bigint, nullable)

Web gallery semantics:
- First query tries `id, track_id, content_url, order` + `.order("order")`.
- If that fails (older schema without `order`), retry with `id, track_id, content_url`.
- Rows are sorted in memory with `(order ?? 0)` when field exists.
- `type` is intentionally flexible (`image`, `gif`, `video`, etc.), but current client rendering is image-first (see media compatibility notes below).

### track_previews
- id (uuid, pk)
- track_id (uuid, fk -> tracks.id)
- preview_kind (text)
- content_url (text)
- preview_order (int)
- meta (jsonb, optional)

Web uses `preview_kind = 'blurred_image'`; when present, preview URLs are used over `art_containers` URLs.
Current DB check constraint allows: `blurred_image`, `video_still`, `blurred_video`.

## Media storage convention (MVP admin ingestion)

Status: required for all **new** admin uploads.

### Bucket
- Single public Supabase Storage bucket: `media`.

### Path templates
- Album cover: `albums/{album_id}/cover.{ext}` -> `albums.cover_image_url`
- Track audio: `albums/{album_id}/tracks/{track_number}/audio.{ext}` -> `tracks.audio_url`
- Track art: `albums/{album_id}/tracks/{track_number}/art/{order}.{ext}` -> `art_containers.content_url`
- Track previews: `albums/{album_id}/tracks/{track_number}/previews/{preview_order}.{ext}` -> `track_previews.content_url`

### URL policy
- DB stores full public URL (not storage path), for example:
- `https://<project>.supabase.co/storage/v1/object/public/media/albums/{album_id}/tracks/1/audio.mp3`

### Naming rules
- Lowercase only.
- No spaces.
- Do not use original uploader filenames.
- Do not include artist/title names in paths.
- Allowed characters in filenames: `a-z`, `0-9`, `-`, `_`, `.`
- Ordered assets use numeric filenames: `1.jpg`, `2.jpg`, `3.mp4`, etc.
- File extension must match real content type.

### Mutability policy
- Published album media is immutable in MVP.
- Overwrite is allowed only during draft stage.
- If replacement is needed after publish, create a new album/release instead of overwriting files.

### Legacy paths
- Existing legacy URLs are kept as-is.
- No automatic storage backfill/move is required for MVP.
- All new admin uploads must follow this convention.

## Media compatibility notes (current clients)

### Current rendering behavior
- `droptune-web` gallery currently renders track art via `<img>` URLs.
- `droptune_mobile`/`droptune_mobile2` track gallery currently renders art via `Image.network`.
- Because of this, image formats work in current UI; direct video playback from `art_containers.content_url` is not yet implemented in clients.

### Practical support in MVP now
- Cover/preview/art images: `jpg`, `jpeg`, `png`, `webp` are safe defaults.
- Animated images:
  - `gif` works on web and is generally supported on mobile image widgets.
  - Animated `webp` support can vary by client/runtime and should be validated on target devices before mass usage.
- Video files (`mp4`, `webm`, `mov`) can be stored in `art_containers`, but current clients will not render them as video without explicit player logic.

### Admin upload validation policy (MVP)
- Admin ingestion must **not** block video files for `art_containers`.
- Allowed `art_containers` upload classes: static images, animated images (including `gif`), and video files.
- Validation in admin flow should enforce only file presence/basic upload correctness for `art_containers` (no image-only restriction).
- UI rendering can remain image-first in clients until dedicated video rendering is implemented.

## Ownership model

### album_copies
- id (uuid, pk)
- album_id (uuid, fk)
- serial (int, unique within album)
- created_at (timestamp)

### copy_ownership
- copy_id (uuid, pk/unique fk -> album_copies.id)
- owner_user_id (uuid)
- acquired_at (timestamp)
- acquired_via (text, non-null; current defaults/backfill use `unknown`)
- last_tx_id (uuid, nullable fk -> transactions.id)

Notes:
- `copy_ownership` is the current ownership snapshot.
- `last_tx_id` points to the transaction that most recently produced the current owner.
- Current primary issuance values use `primary_purchase` for paid fulfillment, `claim` for authenticated direct claims, and `admin_claim` for service/admin claims.

### transactions
- id (uuid, pk)
- copy_id (uuid, fk)
- from_user_id (uuid, nullable)
- to_user_id (uuid)
- price (numeric)
- currency (text)
- type (text)
- status (text; `pending`, `completed`, `failed`, `canceled`)
- created_at (timestamp)
- completed_at (timestamp, nullable)

Notes:
- Primary fulfillment writes completed transactions immediately.
- Future resale flows may use `pending` before settlement.

## Payment Orders

### payment_orders
Represents payment lifecycle for album purchases and links payment process with ownership issuance.

Lifecycle:
- `created -> payment_pending -> paid -> fulfilled`
- alternative terminal states: `failed`, `canceled`

Core columns:
- id, user_id, album_id, amount, currency
- provider, provider_payment_id, provider_order_id
- status
- copy_id, transaction_id
- metadata (including `metadata.debug`)
- created_at, paid_at, fulfilled_at, failed_at, canceled_at

Rules:
- Table tracks payment process, not ownership itself.
- Ownership is issued only by trusted backend fulfillment flow.

Debug fields (`metadata.debug`):
- `stage`
- `last_error`
- `updated_at`

Main stages:
- `redirect_ready`
- `mock_success_started`
- `paid_marked`
- `fulfill_success`
- `fulfill_failed`

## Admin ingestion model (MVP)

### admin_album_drafts
- id (uuid, pk)
- status (text; `draft`, `uploading`, `ready_to_publish`, `publishing`, `published`, `failed`)
- payload (jsonb)
- created_by (uuid, fk -> auth.users.id)
- published_album_id (uuid, nullable fk -> albums.id)
- last_error (text, nullable)
- created_at, updated_at (timestamp)

Rules:
- Table is backend-admin only (service role). Public/client roles have no access.
- Used as draft workspace for admin upload flow before writing final rows into `albums`, `tracks`, `art_containers`, `track_previews`, `album_copies`.

## DB change notes

### 2026-05-04 — Data model v1 alignment

Migration: `supabase/migrations/20260504195200_align_data_model_v1.sql`

Purpose:
- Add documented album presentation/supply fields missing from the baseline schema.
- Add ownership provenance (`acquired_via`, `last_tx_id`) and transaction lifecycle fields (`status`, `completed_at`).
- Replace ownership-issuing RPC bodies so new rows keep `copy_ownership.last_tx_id`, `payment_orders.transaction_id`, and `transactions.status` in sync.

Verification minimum after applying:
- Query new columns on `albums`, `copy_ownership`, and `transactions`.
- Complete a staging/mock paid order and verify the fulfilled order has a `copy_id`, `transaction_id`, matching `copy_ownership.last_tx_id`, and a `completed` transaction.
