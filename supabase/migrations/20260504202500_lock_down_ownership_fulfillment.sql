-- Migration: 20260504202500_lock_down_ownership_fulfillment
-- Context: enforce backend-only ownership issuance and payment fulfillment.
-- Safe to re-run: yes
--
-- Risk note:
-- - Client roles lose EXECUTE on ownership-issuing RPCs.
-- - Authenticated users keep SELECT/INSERT on payment_orders for the web buy flow.
-- - Backend service_role keeps EXECUTE on trusted RPCs and table access.
--
-- Rollback / forward-fix:
-- - Forward-fix preferred: explicitly grant a narrowly scoped RPC if a future
--   client flow needs it.
-- - Emergency rollback can re-grant EXECUTE to authenticated on a specific RPC,
--   but do not re-open fulfill_payment_order to client roles.
--
-- Smoke checks after apply:
-- - has_function_privilege('anon', 'public.fulfill_payment_order(uuid)', 'EXECUTE') = false
-- - has_function_privilege('authenticated', 'public.fulfill_payment_order(uuid)', 'EXECUTE') = false
-- - has_function_privilege('service_role', 'public.fulfill_payment_order(uuid)', 'EXECUTE') = true
-- - authenticated has SELECT/INSERT, but not UPDATE/DELETE, on public.payment_orders

BEGIN;

REVOKE ALL ON FUNCTION public.claim_album_copy(uuid, numeric, text)
  FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.claim_album_copy_for_user(uuid, uuid, numeric, text)
  FROM anon, authenticated;

REVOKE ALL ON FUNCTION public.fulfill_payment_order(uuid)
  FROM anon, authenticated;

GRANT EXECUTE ON FUNCTION public.claim_album_copy(uuid, numeric, text)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.claim_album_copy_for_user(uuid, uuid, numeric, text)
  TO service_role;

GRANT EXECUTE ON FUNCTION public.fulfill_payment_order(uuid)
  TO service_role;

-- New RPCs should not become client-callable by default. Expose client RPCs
-- explicitly in the same migration that introduces them.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM anon, authenticated;

-- Ownership and transaction writes are backend-only. Existing RLS policies still
-- control which rows authenticated users can read.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.album_copies
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE ON TABLE public.copy_ownership
  FROM anon, authenticated;

REVOKE INSERT, UPDATE, DELETE ON TABLE public.transactions
  FROM anon, authenticated;

-- Clients may create their own payment order and read their own rows, but cannot
-- mark orders paid/fulfilled or mutate lifecycle fields.
REVOKE ALL ON TABLE public.payment_orders
  FROM anon;

REVOKE UPDATE, DELETE ON TABLE public.payment_orders
  FROM authenticated;

GRANT SELECT, INSERT ON TABLE public.payment_orders
  TO authenticated;

COMMIT;
