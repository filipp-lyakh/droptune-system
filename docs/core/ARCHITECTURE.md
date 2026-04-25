# Droptune Architecture (core)

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile

## High-level
Droptune = music player + limited collectible albums.  
Backend: Supabase (Postgres + Storage + Auth + RLS).  
Clients: **Flutter** (player app) and **Next.js** (public web: catalog, album landing, purchase).

## Web app (Next.js) — `droptune-web`

### Routes (album-related)
- **`/album/[id]`** — primary public album page: hero, stickers, purchase / “Open in Droptune”, related albums, “What is Droptune”, footer. Links from catalog and “My albums” point here.
- **`/albums/[id]`** — separate slim purchase-focused screen; does **not** mirror full album UI or theming from `background_color`.

### Routes (marketing/navigation)
- **`/for-artists`** — artist-focused marketing landing page (explanation of release model, value proposition, CTA).
- **`/main`** — temporary hub page (navigation entrypoint for key web sections); intended to evolve into a full “split entry” page.

### Global app shell (layout)
- `Header` and `SiteFooter` are rendered from root layout (`src/app/layout.tsx`) on all routes.
- Header horizontal paddings are unified to **32px** to match album-page reference spacing.
- Header logo uses SVG assets from `public/`: `logo_black.svg` on light surfaces and `logo_white.svg` on dark surfaces (artist landing and dark album hero).
- Footer is a single shared component (`src/components/SiteFooter.tsx`), based on album footer links/style.
- Layout uses a flex column shell (`body` + content container) so footer behavior is consistent: if content is short, footer sticks to viewport bottom; if content is long, footer stays after content.

### Data loading (`src/app/album/[id]/page.tsx`)
- Album row is loaded with a **progressive `select()` chain**: longest field list first, then shorter lists if PostgREST returns undefined-column errors (`42703`). This keeps older DB schemas working.
- Order accounts for optional columns: e.g. attempts with **`background_color` but without `hero_background_color`** so the page still gets a page background if only one of the two columns exists.
- **Normalization:** `background_color` may be stored as `RRGGBB` without `#`; the client prepends `#` when it matches six hex digits.

### Page background and contrast
- **`albums.background_color`** drives `backgroundColor` on the album page root and hero (see **docs/core/DATA_MODEL.md**).
- If the color is a **dark** `#RRGGBB` (relative luminance below a fixed threshold), the hero block sets **`data-hero-dark-bg="true"`** and CSS switches title/artist/year (and related hero copy) to light text.
- **Header:** the layout renders `Header` **outside** the album page tree. The album page dispatches a browser event **`droptune:album-header-light`** (`detail: { on: boolean }`) so the header can switch logo and nav links to light colors on dark album backgrounds.

### Cover gallery modal
- **Desktop (≥768px):** horizontal scroll of cards; `scrollLeft` drives blurred-image index cycling on track cards.
- **Mobile (≤767px):** vertical column, **8px** gap between cards; text card height follows content (no inner scroll). Same scroll-driven art index using **`scrollTop`**.
- Modal backdrop color: `hero_background_color` if set, else page background color.

### Responsive album page (≤767px)
- Rules live mainly in global CSS: no white “stack” stripes on cover, **8px** side inset for cover vs **24px** for other blocks, hero flex spacers with ratio **0.25X : X : X : 2X**, compact stickers, related/droptune typography.
- Shared footer vertical stack on mobile with **32px** horizontal inset for nav/copy.

### Typography
- **Inter** (`next/font/google`, subsets `latin` + `cyrillic`), CSS variable **`--font-inter`**.
- **Geist Mono** remains for monospace tokens only.

### Other references
- Purchase redirect and ownership: see sections below.
- Deep links: **docs/core/DEEP_LINKS.md**.

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

## Debug and tracing (payments)
Payment progress/errors are recorded in `payment_orders.metadata.debug`:
- `stage`
- `last_error`
- `updated_at`
