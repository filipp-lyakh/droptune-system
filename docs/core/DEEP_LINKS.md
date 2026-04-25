# Deep links and post-purchase handoff

Status: source-of-truth  
Owners: Product + Web + Mobile  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile

## Deep link format

**Album:** `droptune://album/{albumId}`

- `albumId` is the UUID of the album (e.g. from `albums.id`).
- Used to open the Droptune app directly on that album (e.g. after purchase or from "Open in Droptune" on the web).

Example: `droptune://album/550e8400-e29b-41d4-a716-446655440000`

---

## Post-purchase handoff

After a successful payment, the user is shown a **payment success page** (e.g. `/payment/mock-success?order_id=...` in mock mode).

### Primary action: Open in Droptune

- Button **"Open in Droptune"** triggers the deep link `droptune://album/{albumId}` (albumId from the fulfilled order).
- On a device with the Droptune app installed, this opens the app on the purchased album.
- If the app is not installed, the browser or OS may show an error or do nothing; the fallbacks below cover that case.

### Fallback actions

- **Open App Store** — Links to the Droptune app on the App Store. URL is a placeholder until the app is published; replace with the real App Store link when available.
- **Open My Albums on Web** — Links to the user collection page (`/my`) so the user can open owned albums in the browser if they cannot or do not want to open the app.

---

## Where deep links are used (web)

- **Payment success page** — "Open in Droptune" uses `droptune://album/{albumId}`.
- **Album page (owned state)** — When the user already owns the album, the "Open in Droptune" button uses the same deep link to open the app on that album.
