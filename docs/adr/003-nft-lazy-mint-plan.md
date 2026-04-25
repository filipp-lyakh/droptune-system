# ADR-003: NFT via custodial + lazy mint (future)

Status: Proposed  
Date: 2026-03-03

## Context
We want NFT “under the hood” without crypto UX for users.
Gas costs and wallet setup are friction.

## Decision (future)
- Custodial wallet per user (managed by backend/provider)
- Lazy mint:
  - no mint at primary sale
  - mint on first resale or withdraw-to-external-wallet

## Consequences
- MVP is fully web2
- Later we can add token_id, chain, contract_address fields to album_copies
