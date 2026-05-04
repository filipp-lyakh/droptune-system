-- Migration: 20260504203500_revoke_public_execute_on_trusted_rpcs
-- Context: Postgres grants EXECUTE on functions to PUBLIC by default. The
-- previous lock-down migration revoked client roles explicitly, but PUBLIC still
-- made trusted RPCs executable by anon/authenticated through role inheritance.
-- Safe to re-run: yes
--
-- Rollback / forward-fix:
-- - Forward-fix preferred: explicitly grant narrowly scoped RPCs to client roles
--   only when a product flow requires them.
-- - Do not re-grant PUBLIC execute on ownership or payment fulfillment RPCs.

BEGIN;

REVOKE ALL ON FUNCTION public.claim_album_copy(uuid, numeric, text)
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.claim_album_copy_for_user(uuid, uuid, numeric, text)
  FROM PUBLIC, anon, authenticated;

REVOKE ALL ON FUNCTION public.fulfill_payment_order(uuid)
  FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.claim_album_copy(uuid, numeric, text)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_album_copy_for_user(uuid, uuid, numeric, text)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.fulfill_payment_order(uuid)
  TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated;

COMMIT;
