# ADR-005: Backend-only claims for free limited editions

Status: Accepted; deployed 2026-11-25
Date: 2026-11-25

## Context

Arcade Heaven is a free release with 512 copies. The payment flow rejects zero
amounts. A free edition still needs finite serials, ownership and transaction
history so it can appear in the mobile library.

## Decision

- An album with an explicit numeric price of zero is free. A null price means
  unavailable, not free. Positive prices continue through the payment flow.
- Web offers an authenticated server action to claim a free copy. The server
  derives the recipient from the authenticated session; the client supplies
  only the album ID. No payment order or provider session is created.
- A service-role-only `claim_free_album_copy_for_user` RPC locks the album,
  checks its current price and returns an existing owned copy or atomically
  issues the next available serial. Concurrent requests cannot give the same
  user multiple copies through this RPC or exceed the edition's inventory.
- Issuance uses the existing ownership and transaction contract: `admin_claim`,
  a completed primary transaction with price zero and RUB currency.
- Mobile keeps its existing library and deep-link behavior. It never initiates
  payment or ownership issuance.

## Consequences

Paid fulfillment and free issuance have separate server paths. Both preserve
backend-only ownership writes. The migration and server deployment must precede
publishing a free edition with a working claim action. No existing RPC is opened
to client roles. See the migration for risk, rollback and smoke-check notes.

## Verification

The migration passed local PostgreSQL tests and staging checks, including twelve
concurrent same-user requests, finite inventory and denied client RPC access. It
was applied to staging and production. Production web claim issued one copy with
a zero-price primary transaction and no payment order. The existing production
transaction schema lacks a status column; the new RPC delegates to the existing
trusted issuance function and does not require that column.
