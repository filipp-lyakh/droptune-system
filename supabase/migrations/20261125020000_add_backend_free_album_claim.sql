-- Free limited editions: trusted backend only. No client ownership permissions.
-- Risk: adds an issuance entry point. Database price must be exactly zero;
-- album locking serializes requests, including retries for the same owner.
-- Rollback: first disable the web free-claim action, then drop this function.
-- Existing ownership/history must be retained; prefer forward-fixing failures.
-- Smoke: anon/authenticated cannot execute; service_role can. Paid/null prices
-- fail; repeated and concurrent same-user claims return one copy/transaction;
-- different-user claims consume distinct serials and sold-out fails atomically.
BEGIN;

CREATE OR REPLACE FUNCTION public.claim_free_album_copy_for_user(
  p_album_id uuid,
  p_user_id uuid
)
RETURNS TABLE(copy_id uuid, serial integer, album_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public
AS $$
DECLARE
  v_price numeric;
  v_existing_copy_id uuid;
  v_existing_serial integer;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'User id is required';
  END IF;

  -- Also prevents the price changing between validation and issuance.
  SELECT a.price INTO v_price
  FROM public.albums AS a WHERE a.id = p_album_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Album not found';
  END IF;
  IF v_price IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION 'Album is not free';
  END IF;

  SELECT ac.id, ac.serial INTO v_existing_copy_id, v_existing_serial
  FROM public.album_copies AS ac
  JOIN public.copy_ownership AS co ON co.copy_id = ac.id
  WHERE ac.album_id = p_album_id AND co.owner_user_id = p_user_id
  ORDER BY ac.serial LIMIT 1;
  IF FOUND THEN
    RETURN QUERY SELECT v_existing_copy_id, v_existing_serial, p_album_id;
    RETURN;
  END IF;

  RETURN QUERY SELECT claimed.copy_id, claimed.serial, claimed.album_id
  FROM public.claim_album_copy_for_user(p_album_id, p_user_id, 0, 'RUB') AS claimed;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_free_album_copy_for_user(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_free_album_copy_for_user(uuid, uuid)
  TO service_role;

COMMIT;
