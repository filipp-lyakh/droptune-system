# ADR-002: Two-table ownership model (album_copies + copy_ownership)

Status: Accepted  
Date: 2026-03-03

## Context
We need limited editions with resale later.
Need history of transfers and current owner.

## Decision
- album_copies: defines the finite set of copies per album (serial within album)
- copy_ownership: current owner snapshot (1 row per copy)
- transactions: immutable history of transfers (primary + resale)

## Consequences
- Easy to query current ownership
- Clean audit trail
- Ready for NFT mapping later (token_id can be added to album_copies)
