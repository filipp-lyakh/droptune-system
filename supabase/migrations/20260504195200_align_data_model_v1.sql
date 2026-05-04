-- Migration: 20260504195200_align_data_model_v1
-- Context: align the physical schema with docs/core/DATA_MODEL.md v1.
-- Safe to re-run: yes
--
-- Risk note:
-- - Additive columns are nullable or have safe defaults/backfills.
-- - RPC bodies are replaced to populate the new ownership/transaction fields.
-- - background_color constraint is widened from #RRGGBB-only to optional #RRGGBB.
--
-- Rollback / forward-fix:
-- - Forward-fix preferred: add a follow-up migration correcting constraints/RPCs.
-- - Emergency rollback can restore previous RPC bodies and ignore the new nullable
--   columns; do not drop populated columns in production without a data export.
--
-- Smoke checks after apply:
-- - select supply_total, hero_background_color, background_color from public.albums limit 1;
-- - select acquired_via, last_tx_id from public.copy_ownership limit 1;
-- - select status, completed_at from public.transactions limit 1;
-- - complete a mock/staging paid order and verify payment_orders.transaction_id =
--   copy_ownership.last_tx_id and transactions.status = 'completed'.

BEGIN;

ALTER TABLE public.albums
  ADD COLUMN IF NOT EXISTS supply_total integer,
  ADD COLUMN IF NOT EXISTS hero_background_color text;

ALTER TABLE public.albums
  DROP CONSTRAINT IF EXISTS albums_background_color_check;

ALTER TABLE public.albums
  ADD CONSTRAINT albums_background_color_check
  CHECK (
    background_color IS NULL
    OR background_color ~ '^#?([A-Fa-f0-9]{6})$'
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'albums_hero_background_color_check'
      AND conrelid = 'public.albums'::regclass
  ) THEN
    ALTER TABLE public.albums
      ADD CONSTRAINT albums_hero_background_color_check
      CHECK (
        hero_background_color IS NULL
        OR hero_background_color ~ '^#?([A-Fa-f0-9]{6})$'
      );
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'albums_supply_total_check'
      AND conrelid = 'public.albums'::regclass
  ) THEN
    ALTER TABLE public.albums
      ADD CONSTRAINT albums_supply_total_check
      CHECK (supply_total IS NULL OR supply_total >= 0);
  END IF;
END;
$$;

ALTER TABLE public.copy_ownership
  ADD COLUMN IF NOT EXISTS acquired_via text NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS last_tx_id uuid;

ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'completed',
  ADD COLUMN IF NOT EXISTS completed_at timestamp with time zone;

UPDATE public.transactions
SET completed_at = created_at
WHERE status = 'completed'
  AND completed_at IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'transactions_status_check'
      AND conrelid = 'public.transactions'::regclass
  ) THEN
    ALTER TABLE public.transactions
      ADD CONSTRAINT transactions_status_check
      CHECK (status = ANY (ARRAY['pending'::text, 'completed'::text, 'failed'::text, 'canceled'::text]));
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'copy_ownership_last_tx_id_fkey'
      AND conrelid = 'public.copy_ownership'::regclass
  ) THEN
    ALTER TABLE public.copy_ownership
      ADD CONSTRAINT copy_ownership_last_tx_id_fkey
      FOREIGN KEY (last_tx_id) REFERENCES public.transactions(id) ON DELETE SET NULL;
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS copy_ownership_last_tx_id_idx
  ON public.copy_ownership USING btree (last_tx_id);

CREATE INDEX IF NOT EXISTS transactions_status_idx
  ON public.transactions USING btree (status);

CREATE OR REPLACE FUNCTION public.claim_album_copy(
  p_album_id uuid,
  p_price numeric DEFAULT NULL::numeric,
  p_currency text DEFAULT NULL::text
)
RETURNS TABLE(copy_id uuid, serial integer, album_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
declare
  v_user_id uuid;
  v_copy_id uuid;
  v_serial integer;
  v_transaction_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = p_album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at,
    acquired_via
  )
  values (
    v_copy_id,
    v_user_id,
    now(),
    'claim'
  );

  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    status,
    created_at,
    completed_at
  )
  values (
    v_copy_id,
    null,
    v_user_id,
    p_price,
    p_currency,
    'primary',
    'completed',
    now(),
    now()
  )
  returning id into v_transaction_id;

  update public.copy_ownership
  set last_tx_id = v_transaction_id
  where copy_ownership.copy_id = v_copy_id;

  return query
  select v_copy_id, v_serial, p_album_id;
end;
$$;

CREATE OR REPLACE FUNCTION public.claim_album_copy_for_user(
  p_album_id uuid,
  p_user_id uuid,
  p_price numeric DEFAULT NULL::numeric,
  p_currency text DEFAULT NULL::text
)
RETURNS TABLE(copy_id uuid, serial integer, album_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
declare
  v_copy_id uuid;
  v_serial integer;
  v_transaction_id uuid;
begin
  if p_user_id is null then
    raise exception 'User id is required';
  end if;

  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = p_album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at,
    acquired_via
  )
  values (
    v_copy_id,
    p_user_id,
    now(),
    'admin_claim'
  );

  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    status,
    created_at,
    completed_at
  )
  values (
    v_copy_id,
    null,
    p_user_id,
    p_price,
    p_currency,
    'primary',
    'completed',
    now(),
    now()
  )
  returning id into v_transaction_id;

  update public.copy_ownership
  set last_tx_id = v_transaction_id
  where copy_ownership.copy_id = v_copy_id;

  return query
  select v_copy_id, v_serial, p_album_id;
end;
$$;

CREATE OR REPLACE FUNCTION public.fulfill_payment_order(p_order_id uuid)
RETURNS TABLE(order_id uuid, copy_id uuid, serial integer, transaction_id uuid, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
declare
  v_order record;
  v_copy_id uuid;
  v_serial integer;
  v_transaction_id uuid;
  v_existing_copy_id uuid;
begin
  select *
  into v_order
  from public.payment_orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'Payment order not found';
  end if;

  if v_order.status = 'fulfilled' then
    return query
    select
      v_order.id,
      v_order.copy_id,
      ac.serial,
      v_order.transaction_id,
      v_order.status
    from public.album_copies ac
    where ac.id = v_order.copy_id;
    return;
  end if;

  if v_order.status <> 'paid' then
    raise exception 'Payment order is not paid';
  end if;

  select co.copy_id
  into v_existing_copy_id
  from public.copy_ownership co
  join public.album_copies ac on ac.id = co.copy_id
  where co.owner_user_id = v_order.user_id
    and ac.album_id = v_order.album_id
  limit 1;

  if v_existing_copy_id is not null then
    raise exception 'User already owns a copy of this album';
  end if;

  select ac.id, ac.serial
  into v_copy_id, v_serial
  from public.album_copies ac
  where ac.album_id = v_order.album_id
    and not exists (
      select 1
      from public.copy_ownership co
      where co.copy_id = ac.id
    )
  order by ac.serial
  limit 1
  for update skip locked;

  if v_copy_id is null then
    raise exception 'No copies left';
  end if;

  insert into public.copy_ownership (
    copy_id,
    owner_user_id,
    acquired_at,
    acquired_via
  )
  values (
    v_copy_id,
    v_order.user_id,
    now(),
    'primary_purchase'
  );

  insert into public.transactions (
    copy_id,
    from_user_id,
    to_user_id,
    price,
    currency,
    type,
    status,
    created_at,
    completed_at
  )
  values (
    v_copy_id,
    null,
    v_order.user_id,
    v_order.amount,
    v_order.currency,
    'primary',
    'completed',
    now(),
    now()
  )
  returning id into v_transaction_id;

  update public.copy_ownership
  set last_tx_id = v_transaction_id
  where copy_ownership.copy_id = v_copy_id;

  update public.payment_orders
  set
    status = 'fulfilled',
    copy_id = v_copy_id,
    transaction_id = v_transaction_id,
    fulfilled_at = now()
  where id = v_order.id;

  return query
  select
    v_order.id,
    v_copy_id,
    v_serial,
    v_transaction_id,
    'fulfilled'::text;
end;
$$;

COMMIT;
