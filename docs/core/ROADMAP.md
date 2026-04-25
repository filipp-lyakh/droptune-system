# Droptune Roadmap

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile

## Phase 1 — Core MVP (Now)
Goal: “Play + ownership without blockchain complexity”
- Stable global player (PlayerService as source of truth)
- Album list from purchases
- Album page: track list + in-page “track view” (animated t 0↔1), morphing mini-player and gray block, 60px bar with optional small art preview
- Track page (optional separate route): arts gallery + mini player; Hero for shared-element transition
- Model: limited copies + ownership history in Postgres
- Payments (web-only first), then unlock in app
- Web shell consistency: single header/footer across routes (layout-level components)
- Artist acquisition landing: `/for-artists` + temporary hub at `/main`

Deliverables:
- Data model v1 (album copies + ownership)
- Purchase flow
- Access control (RLS) for purchases and owned copies
- Playback UX matches mockups

## Phase 2 — Marketplace (Off-chain)
Goal: in-app resale without on-chain
- List owned copies for resale
- Buy/sell transactions in DB
- Royalties + platform fee logic
- Audit log + dispute-ready records

## Phase 3 — NFT layer (Optional / later)
Goal: bring “true ownership” externally when it matters
- Custodial wallets by default
- Lazy mint on first resale / withdraw
- Optional self-custody (withdraw to external wallet)
- Gas strategy + chain selection decision
