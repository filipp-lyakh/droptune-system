# Droptune Architecture (core)

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-06-06
Consumers: droptune-web, droptune_mobile

## High-level
Droptune = music player + limited collectible albums.  
Backend: Supabase (Postgres + Storage + Auth + RLS).  
Clients: **Flutter** (player app) and **Next.js** (public web: catalog, album landing, purchase).

## Web app (contract-level)

### Public routes
- `/album/[id]` is the canonical public album route for acquisition and post-purchase owned-state behavior.
- `/albums/[id]` may exist as a separate purchase-focused route and is not required to mirror full album presentation.
- `/for-artists` is the artist-focused acquisition/education route.
- `/main` is a generic navigation entrypoint.

### Contract expectations
- Web must support unauthenticated viewing of public album pages.
- Buy intent must survive auth redirect and continue purchase after callback.
- Owned albums must expose “Open in Droptune” behavior through canonical deep-link format.
- Web consumes optional album presentation fields with safe fallbacks (see `docs/core/DATA_MODEL.md`).

### Implementation details
- Web-specific routing, layout, CSS behavior, and component-level notes are documented in:
  - `docs/platform/web/ARCHITECTURE_WEB.md`

---

## Flutter app
The following sections describe the **mobile app** unless noted otherwise.

## Playback architecture (critical)
### Single source of truth
**PlayerService** is the only component allowed to control audio playback:
- owns `AudioPlayer` (just_audio)
- owns playback queue and current index
- exposes streams for UI: nowPlayingStream, playerStateStream

### Rules
- Pages (AlbumPage, TrackPage, MyAlbumsPage) **must not** call `player.setAudioSource` directly.
- Pages can only call:
  - `PlayerService.instance.setQueue(...)`
  - `PlayerService.instance.playTrackById(...)`
  - `PlayerService.instance.toggle()/next()/prev()`

### Queue ownership
- AlbumPage builds the queue for an album (ordered by track_number).
- Tap on a track: switches to in-page "track view" and triggers playback via PlayerService.

### UI responsibilities
- **MiniPlayer** is UI-only and invokes PlayerService controls.
- **AlbumPage** shows either "album view" or "track view" in one animated layout.
- **TrackPage** renders arts + MiniPlayer; it does not start playback by itself.

## Supabase integration principles
- Auth: email OTP
- RLS must prevent reading purchases of other users
- Storage: public URLs currently used for audio

## Admin ingestion (MVP)
- Album media ingestion is done through internal admin flow (draft -> upload -> publish).
- New admin uploads must follow the canonical storage convention in `docs/core/DATA_MODEL.md` (bucket/path templates + URL policy).
- Published albums are immutable in MVP (no media overwrite/edit flow after publish).
- Legacy media paths remain valid; no automatic backfill is required for MVP.

## Web acquisition and purchase flow

### Public acquisition flow
- Users reach a public album page at `/album/[id]`.
- The album page is viewable without authentication.
- If unauthenticated user taps Buy, they are redirected to `/login?redirect=/album/{albumId}?buy=1`.
- After login callback, user returns to `/album/{albumId}?buy=1`.
- The album page sees `buy=1` + authenticated user and continues purchase automatically.

### Web payment flow
1. **createPaymentOrder(albumId)** creates `payment_orders` row with `status = created`.
2. **initTbankPayment(orderId)** creates provider session, sets `payment_pending`, returns payment URL.
3. Lifecycle: `created → payment_pending → paid → fulfilled` (alt terminals: `failed`, `canceled`).
4. Mock success page calls **completeMockPayment(orderId)**, marks paid, then calls **fulfill_payment_order** RPC.
5. **fulfill_payment_order** is backend-only.

### Ownership behavior on web
- If user already owns album (`copy_ownership` exists), page shows owned state and Buy is replaced by **Open in Droptune**.

### Post-purchase handoff
- After success, user sees payment success page.
- Primary action: deep link `droptune://album/{albumId}`.
- Fallbacks: App Store placeholder + My Albums on Web (`/my`).

## Purchase policy
- Digital album purchases are **web-only**.
- Mobile app never initiates payment and never claims copies.
- Ownership is granted only after backend-confirmed payment.

## Security rules for purchases
- Clients may create payment orders but cannot mark them paid/fulfilled.
- Clients must never call `fulfill_payment_order` directly.
- Ownership issuance is backend-only.
- Client roles (`anon`, `authenticated`) must not have `EXECUTE` on ownership-issuing RPCs:
  - `claim_album_copy`
  - `claim_album_copy_for_user`
  - `fulfill_payment_order`
- `authenticated` may `SELECT` and `INSERT` its own `payment_orders` rows through RLS, but must not `UPDATE` payment lifecycle fields.
- `service_role` is the trusted backend role for payment status transitions and ownership fulfillment.

Security alignment migrations:
- `supabase/migrations/20260504202500_lock_down_ownership_fulfillment.sql`
- `supabase/migrations/20260504203500_revoke_public_execute_on_trusted_rpcs.sql`

## Debug and tracing (payments)
Payment progress/errors are recorded in `payment_orders.metadata.debug`:
- `stage`
- `last_error`
- `updated_at`
