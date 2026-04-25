# Droptune Business Rules (Core)

Status: source-of-truth  
Owners: Product + Engineering  
Last updated: 2026-04-25  
Consumers: droptune-web, droptune_mobile

## Product model
- Droptune is focused on limited album releases with direct fan support.
- Album purchase value is tied to edition/ownership, not only streaming access.

## Purchase policy
- Purchases are web-initiated.
- Mobile app does not initiate payment and does not issue ownership.
- Ownership is granted only after trusted backend confirmation.

## Ownership policy
- `copy_ownership` is the current ownership snapshot.
- `transactions` is immutable transfer history.
- Users can only read ownership data they are authorized to access via RLS.

## Deep-link policy
- Canonical app album deep link: `droptune://album/{albumId}`.
- Web success and owned states should use this format consistently.
