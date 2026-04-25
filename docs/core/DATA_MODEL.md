# Droptune Data Model (Supabase / Postgres)

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile

## Core tables (current)

### albums
- id (uuid, pk)
- title (text)
- artist_name (text)
- cover_image_url (text, nullable)
- price (numeric/int)
- supply_total (int, nullable)
- release_year (int, nullable)
- gallery_description (text, nullable)
- video_embed_url (text, nullable)
- hero_background_color (text, nullable)
- background_color (text, nullable)

Notes:
- `background_color` is web album page + hero background (`#RRGGBB` or `RRGGBB`, normalized on client).
- `hero_background_color` is optional gallery modal backdrop tint on web.

### tracks
- id (uuid, pk)
- album_id (uuid, fk -> albums.id)
- title (text)
- audio_url (text)
- track_number (int)

### purchases (legacy/MVP source in some flows)
- id (uuid, pk)
- user_identifier (uuid/text)
- album_id (uuid)
- created_at (timestamp)

### art_containers
- id (uuid, pk)
- album_id (uuid, nullable/optional)
- track_id (uuid)
- type (text)
- content_url (text)
- meta (jsonb)
- order (int)

Web gallery semantics:
- First query tries `id, track_id, content_url, order` + `.order("order")`.
- If that fails (older schema without `order`), retry with `id, track_id, content_url`.
- Rows are sorted in memory with `(order ?? 0)` when field exists.

### track_previews
- id (uuid, pk)
- track_id (uuid, fk -> tracks.id)
- preview_kind (text)
- content_url (text)
- preview_order (int)
- meta (jsonb, optional)

Web uses `preview_kind = 'blurred_image'`; when present, preview URLs are used over `art_containers` URLs.

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
- acquired_via (text)
- last_tx_id (uuid, nullable)

### transactions
- id (uuid, pk)
- copy_id (uuid, fk)
- from_user_id (uuid, nullable)
- to_user_id (uuid)
- price (numeric/int)
- currency (text)
- type (text)
- status (text)
- created_at
- completed_at

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
