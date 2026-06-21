# Closed Beta Runbook

Status: working runbook  
Owners: Product + Engineering  
Last updated: 2026-06-14  
Depends on: `docs/core/RELEASE_READINESS_PLAN.md`

## Scope
This runbook covers closed beta/internal testing while real T-Bank acquiring is blocked by business setup.

Closed beta uses:
- staging Supabase
- staging web deploy
- guarded mock payments
- real backend ownership fulfillment
- mobile playback from real ownership state

Closed beta does not prove real acquiring/card payment behavior.

## Required web staging env

```env
NEXT_PUBLIC_SUPABASE_URL=https://rncutejdfmqkmxwzfxup.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<staging anon key>
SUPABASE_SERVICE_ROLE_KEY=<staging service_role key>

ADMIN_UPLOAD_ALLOWLIST=<admin emails>
BETA_PAYMENT_ALLOWLIST=<closed beta buyer emails>

DROPTUNE_DEPLOY_ENV=staging
TBANK_MOCK=true
MOCK_PAYMENTS_ENABLED=true

NEXT_PUBLIC_DROPTUNE_APP_INSTALL_URL=<TestFlight/internal install link or safe staging fallback>
```

Do not set real T-Bank env values for mock closed beta.

## Supabase Auth email OTP setup

Closed beta web login uses email OTP code entry, not magic links.

Required staging Supabase Auth configuration:
- The sign-in email template must show the OTP code via `{{ .Token }}`.
- The sign-in email template must not be configured as a link-only email using only `{{ .ConfirmationURL }}`.
- The web login page verifies the code in-app and then returns to `/album/{albumId}?buy=1`.
- Clicking a magic link and landing on `/` is a staging configuration bug for this flow.

Smoke check before purchase testing:
1. Open staging `/album/{albumId}` while logged out.
2. Tap Buy.
3. Enter email on `/login?redirect=/album/{albumId}?buy=1`.
4. Confirm the email contains a numeric/login code, not only a `Log In` link.
5. Enter the code on the web login page.
6. Confirm the browser returns to `/album/{albumId}?buy=1`.

## Required mobile staging config

Pass these values through `--dart-define`:

```env
SUPABASE_URL=https://rncutejdfmqkmxwzfxup.supabase.co
SUPABASE_ANON_KEY=<staging anon key>
WEB_CATALOG_BASE_URL=<staging web domain>
```

## Supabase migration verification

Expected migrations:

```text
20260425210000_baseline.sql
20260504195200_align_data_model_v1.sql
20260504202500_lock_down_ownership_fulfillment.sql
20260504203500_revoke_public_execute_on_trusted_rpcs.sql
20260606153000_add_admin_album_drafts_and_track_number_uniqueness.sql
```

Minimum SQL checks:

```sql
select version from supabase_migrations.schema_migrations order by version;

select
  has_function_privilege('anon', 'public.fulfill_payment_order(uuid)', 'EXECUTE') as anon_fulfill,
  has_function_privilege('authenticated', 'public.fulfill_payment_order(uuid)', 'EXECUTE') as auth_fulfill,
  has_function_privilege('service_role', 'public.fulfill_payment_order(uuid)', 'EXECUTE') as service_fulfill;

select
  has_table_privilege('authenticated', 'public.payment_orders', 'SELECT') as auth_select_orders,
  has_table_privilege('authenticated', 'public.payment_orders', 'INSERT') as auth_insert_orders,
  has_table_privilege('authenticated', 'public.payment_orders', 'UPDATE') as auth_update_orders;

select
  has_table_privilege('authenticated', 'public.admin_album_drafts', 'SELECT') as auth_admin_drafts,
  has_table_privilege('service_role', 'public.admin_album_drafts', 'SELECT') as service_admin_drafts;
```

Expected:
- `anon_fulfill=false`
- `auth_fulfill=false`
- `service_fulfill=true`
- authenticated can `SELECT`/`INSERT` `payment_orders`
- authenticated cannot `UPDATE` `payment_orders`
- authenticated cannot `SELECT` `admin_album_drafts`
- service role can `SELECT` `admin_album_drafts`

## Closed beta smoke-test

1. Open staging `/album/{albumId}` without login.
2. Tap Buy.
3. Verify redirect to `/login?redirect=/album/{albumId}?buy=1`.
4. Log in with an email from `BETA_PAYMENT_ALLOWLIST`.
5. Verify return to `/album/{albumId}?buy=1`.
6. Verify Buy opens `/payment/mock-success?order_id=...`.
7. Verify the page clearly says this is closed beta mock payment and no real charge occurred.
8. Verify `payment_orders`:

```sql
select id, user_id, album_id, status, provider_payment_id, paid_at, fulfilled_at, copy_id, transaction_id
from payment_orders
where album_id = '<albumId>'
order by created_at desc
limit 5;
```

Expected:
- `status='fulfilled'`
- `provider_payment_id` starts with `mock_`
- `paid_at`, `fulfilled_at`, `copy_id`, and `transaction_id` are present

9. Verify ownership:

```sql
select co.copy_id, co.owner_user_id, co.acquired_via, co.last_tx_id, ac.album_id, ac.serial
from copy_ownership co
join album_copies ac on ac.id = co.copy_id
where ac.album_id = '<albumId>';
```

Expected:
- exactly one new ownership copy for the beta buyer
- `last_tx_id` is present

10. Reopen `/album/{albumId}` as the same user.
11. Verify Buy is replaced by Open in Droptune.
12. Verify Open in Droptune points to `droptune://album/{albumId}`.
13. Log into mobile as the same user.
14. Verify the album appears in owned library.
15. Verify the album opens from deep link.
16. Verify tracks play.
17. Verify an unowned album deep link does not expose playback.

## Safety requirements

- Closed beta staging only.
- `DROPTUNE_DEPLOY_ENV=staging` is required for mock payments.
- `MOCK_PAYMENTS_ENABLED=true` is required for mock payments.
- `BETA_PAYMENT_ALLOWLIST` is required for mock buyers.
- Production must not set `TBANK_MOCK=true`.
- Production must not set `MOCK_PAYMENTS_ENABLED=true`.
- Production must not set `BETA_PAYMENT_ALLOWLIST`.

## Production blockers

- Complete ИП/acquiring setup.
- Obtain T-Bank test/prod credentials.
- Run real provider callback smoke-test.
- Verify duplicate callback idempotency with live provider payload.
- Set final install/store fallback URL.
