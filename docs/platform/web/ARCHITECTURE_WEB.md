# Droptune Web Architecture Notes

Status: web-specific  
Owners: Web Engineering  
Last updated: 2026-06-06  
Depends on: `docs/core/ARCHITECTURE.md`, `docs/core/DATA_MODEL.md`, `docs/core/DEEP_LINKS.md`

## Scope
This document contains implementation details specific to `droptune-web` (Next.js).
Core system contracts remain in `docs/core/*`.

## Routes
- `/album/[id]` — primary public album page (hero, stickers, purchase/open-in-app, related albums, droptune block).
- `/albums/[id]` — separate slim purchase-focused screen.
- `/for-artists` — artist-focused marketing page.
- `/main` — temporary hub.

## Global shell
- `Header` and `SiteFooter` render from `src/app/layout.tsx`.
- Header paddings are unified to 32px.
- Header logo switches:
  - `public/logo_black.svg` on light surfaces
  - `public/logo_white.svg` on dark surfaces (`/for-artists` and dark album hero)
- Layout is a flex column shell so footer behavior is deterministic for short/long pages.

## Album page data loading (`src/app/album/[id]/page.tsx`)
- Progressive `select()` chain with fallback for missing columns (`42703`).
- Select order explicitly includes attempts with `background_color` but without `hero_background_color`.
- `background_color` is normalized from `RRGGBB` to `#RRGGBB` when needed.

## Album page visuals
- `albums.background_color` drives album page root + hero background.
- Dark surface detection sets `data-hero-dark-bg="true"` for light hero text.
- Album page dispatches `droptune:album-header-light` so global header can switch to light theme.

## Gallery modal (`src/components/album-gallery/AlbumGalleryModal.tsx`)
- Desktop: horizontal card scroller (`scrollLeft`-driven preview index behavior).
- Mobile: vertical column (`scrollTop`-driven behavior), 8px card gap, text card grows with content.
- Backdrop color: `hero_background_color` when present, else page background.

## Responsive notes (mobile ≤767px)
- Main rules in `src/app/globals.css`:
  - cover stack simplification
  - hero spacer ratio `0.25X : X : X : 2X`
  - compact stickers
  - section typography adjustments
  - shared footer stacked layout with 32px horizontal insets

## Typography
- Inter (`--font-inter`) as primary sans font.
- Geist Mono retained for monospace tokens only.

## Internal admin upload (MVP)
- Route: `/admin`.
- Access policy: authenticated user + email allowlist (`ADMIN_UPLOAD_ALLOWLIST`).
- API surface under `src/app/api/admin/*`:
  - draft CRUD (`/drafts`, `/drafts/[id]`)
  - upload session and finalize (`/uploads/session`, `/uploads/complete`)
  - publish (`/drafts/[id]/publish`)
- Upload flow:
  1. Create signed upload URL on backend (`service_role`).
  2. Browser uploads directly to Supabase Storage signed target.
  3. Backend persists resulting media URL into draft payload.
- Publish writes from draft payload into `albums`, `tracks`, `art_containers`, `track_previews`, and `album_copies`.
