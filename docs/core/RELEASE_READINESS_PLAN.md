# Droptune Release Readiness Plan

Status: working plan  
Owners: Product + Engineering  
Last updated: 2026-11-08
Consumers: droptune-web, droptune_mobile

## Current mobile delivery update — 2026-11-08

First staging iOS delivery is complete: TestFlight 1.0.0 (4) was uploaded, processed, made available internally and installed. On November 8 the owner completed one unified smoke on that build, iPhone 16 Pro / owner-reported iOS 26.6.2: login/library, multitrack playback, links, background/lock, network recovery via Retry, logout/re-login/manual Play and primary screens passed. In-app staging demonstration is ready with documented limits. The SMTP failure was resolved for the test by returning to built-in Supabase mail at owner request; DNS remains closed. Catalog navigation and final screenshots remain outstanding; App Store submission/production gates remain open. No public App Store readiness, new upload or production readiness is implied.

Current mobile results, external owner actions, submission preparation and production transition: [iOS demo readiness](../platform/mobile/IOS_DEMO_READINESS.md). This update supersedes older mobile distribution/signing/warm-link blocker statements below; dated cross-platform snapshots remain historical. Backend/payment status and contracts are unchanged.

## Goal
Bring Droptune to a production-ready state for public web launch and mobile store release:
- public web acquisition works end to end
- mobile app plays owned albums reliably
- payments issue ownership only after trusted backend confirmation
- admin can publish releases without manual DB edits
- release, monitoring, and rollback routines are documented and repeatable

## Current read from system docs
The system docs already define the main MVP shape:
- Supabase/Postgres is the backend source of truth.
- Web handles public album pages, authentication handoff, and payment initiation.
- Mobile consumes owned albums and playback, but never initiates payments or ownership issuance.
- Ownership is modeled through `album_copies`, `copy_ownership`, and `transactions`.
- Trusted fulfillment RPCs are locked down to backend/service role.
- Admin album ingestion has a DB draft model and storage naming convention.

The remaining work is mostly release hardening, production integration, platform parity, and verification.

Mobile audit update (2026-06-14):
- Mobile payment/RPC ownership risks were checked; the app does not initiate payment or call ownership-issuing RPCs.
- Local mobile P0 fixes were applied for ownership-gated album access, unowned deep links, missing `audio_url`, Android internet permission, and Android album deep-link filter.
- Remaining mobile P0s are environment/release blockers: real Supabase `--dart-define` values, staging smoke-test, Android package id, Android release signing, and Apple signing/team.

Web audit update (2026-06-14):
- Local web P0 fixes were applied for production T-Bank webhook handling, token signing, production success/fail pages, sold-out order blocking, and album sold-count correctness.
- Web lint and build passed after local fixes.
- Staging can be deployed for smoke-test when required environment variables are present.
- Production remains blocked until real T-Bank callback smoke-test, duplicate callback verification, production environment configuration, install fallback URL, and Supabase migration verification are complete.

Payment availability update (2026-06-14):
- Real T-Bank test/prod credentials are currently blocked by business setup: acquiring connection requires an оформленное ИП.
- Public production launch with real payments is blocked until acquiring credentials are available and live callback smoke-test passes.
- Real T-Bank staging callback smoke-test is blocked for the same reason.
- Closed beta/internal testing may use staging-only mock payments with `TBANK_MOCK=true`, `MOCK_PAYMENTS_ENABLED=true`, `DROPTUNE_DEPLOY_ENV=staging`, and `BETA_PAYMENT_ALLOWLIST`.
- Mock payments are not real payments and must not be presented as production commerce.

Closed beta smoke update (2026-06-21):
- Web closed beta mock-payment flow passed on staging URL `https://droptune-web-git-staging-beta-filipplyakh.vercel.app`.
- Smoke-test album: `d364cd8c-aafd-4f85-9d4a-d917c6916217`.
- Web verified public album, buy intent login, OTP-code auth, beta allowlist, mock fulfillment, fulfilled `payment_orders`, `copy_ownership`, owned state, and canonical `droptune://album/{albumId}` deep link.
- Remaining closed beta critical path is mobile smoke-test: owned library, owned deep link, playback, and unowned deep-link blocking.

Mobile smoke update (2026-06-23):
- Mobile smoke passed for closed beta on iOS simulator: app builds/starts with staging defines, Supabase initializes, login works, owned library shows the purchased album, owned deep link opens it, playback works, logged-in cold-start unowned deep link is safely blocked, and payment/checkout/fulfillment logic is absent from mobile `lib`.
- `flutter test` and `flutter analyze` passed.
- One smoke-found UX issue was fixed: album access errors now render user-facing text instead of an exception object string.
- Known mobile follow-up: warm unowned link from an already-open owned album did not visibly switch screens in simulator; cold-start logged-in unowned blocking passed safely.

Domain setup update (2026-06-29):
- `droptune.art` and `www.droptune.art` were added in Vercel with valid DNS.
- `droptune.art` is now live after the pre-acquiring production deploy.
- `www.droptune.art` should resolve/redirect according to Vercel domain settings.
- `droptune-web.vercel.app` is present in Vercel; do not use it as the canonical launch URL.
- `staging.droptune.art` was added against the `staging-beta` branch but is currently invalid; closed beta continues to use the working Vercel preview URL `https://droptune-web-git-staging-beta-filipplyakh.vercel.app`.
- Do not replace the closed beta staging URL or update staging Auth/payment/mobile config until `staging.droptune.art` is intentionally fixed and smoke-tested.
- Do not change production environment variables until real T-Bank smoke, duplicate callback verification, production Supabase readiness, and launch approval are complete.

Web domain/legal readiness update (2026-08-05):
- `droptune-web` commit `613f7d5` (`Add launch support legal pages`) is on `staging-beta`.
- Launch-safe `/support`, `/privacy`, and `/terms` pages exist and were manually checked on Vercel preview.
- Shared footer links to Support, Privacy, and Terms were manually checked on Vercel preview.
- Support email: `hello@droptune.app`.
- `npm run lint` passed with existing `<img>` warnings only.
- `npm run build` passed.
- `droptune-web` worktree was reported clean after the web task.
- These pages are live on `droptune.art` after the pre-acquiring production deploy.

Pre-acquiring public site update (2026-08-05):
- T-Bank acquiring onboarding requires a working public website that explains what the company/product does.
- `droptune.art` may be deployed before full commerce launch as an informational pre-acquiring site.
- This pre-acquiring site must not expose real payments, mock payments, or misleading purchase claims.
- Root `/` is now the canonical public landing page; legacy `/main` redirects to `/`.
- Catalog/acquisition CTAs on root `/` are disabled with a "catalog later" tooltip until commerce launch.
- App Store CTA on root `/` is disabled with an "app link later" tooltip until an install URL exists.
- Public header hides login and public footer hides personal-account links during pre-acquiring review; `/login` and `/my` routes remain available.
- `/support`, `/privacy`, and `/terms` copy and footer labels are Russian.
- Before the T-Bank DEMO setup, production Vercel environment variables were checked empty for pre-acquiring launch safety.
- `npm run lint` and `npm run build` passed after the pre-acquiring landing changes, with existing `<img>` warnings only.
- Minimum public surface:
  - root `/` explains Droptune as a limited digital album/music ownership product
  - `/for-artists` explains artist/listener positioning if kept public
  - `/support`, `/privacy`, and `/terms` are reachable from the footer
  - album/purchase CTAs are hidden, disabled, or clearly marked as not publicly available until acquiring is approved
- Production commerce remains blocked until production T-Bank terminal credentials, fiscalization/Receipt requirements, duplicate callback verification, live small-amount smoke-test, and launch approval are complete.

T-Bank DEMO acquiring update (2026-08-05):
- Production `droptune.art` was used for a successful T-Bank DEMO end-to-end payment smoke-test.
- `/payment/success` and `/payment/fail` are Russian.
- `GET /api/tbank/webhook` returns a health-check JSON response; real notifications are accepted via `POST`.
- Production Vercel env now contains DEMO T-Bank settings, `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_UPLOAD_ALLOWLIST`, and `NODE_EXTRA_CA_CERTS=./certs/russian-trusted-ca-bundle.pem`.
- Production mock flags are explicitly disabled: `TBANK_MOCK=false`, `MOCK_PAYMENTS_ENABLED=false`.
- T-Bank `Init` succeeded against `https://securepay.tinkoff.ru/v2/Init`.
- Provider `CONFIRMED` notification was received and processed.
- `payment_orders` reached `status = fulfilled` with populated `paid_at`, `fulfilled_at`, `copy_id`, and `transaction_id`.
- `copy_ownership` was created with `acquired_via = primary_purchase` for album `9798906d-baeb-4a53-806f-b0e213c45dd4`.
- Rejected DEMO payment path was also checked and produced `payment_orders.status = failed`.
- TLS issue with T-Bank API was fixed by adding a Russian Trusted Root/Sub CA bundle to the web runtime.
- Basic T-Bank acquiring integration is working on the production URL with DEMO credentials.
- Public launch with real money remains blocked until production terminal credentials, fiscalization/receipt requirements, and a small live-payment smoke-test are complete.

Mobile distribution setup update (2026-08-06):
- Owner approved the final mobile identifiers for both platforms: iOS Bundle Identifier and Android applicationId are `art.droptune.app`.
- Mobile remains consumption-only: no checkout, payment initiation, or ownership issuance logic was added.
- Android release signing is configured locally with an owner-approved upload key stored outside version control; signed staging AAB generation and signature verification passed.
- Google Play Console organization onboarding is blocked on D-U-N-S for the Russian individual entrepreneur profile; the Interfax-D&B application was submitted on 2026-08-06.
- iOS TestFlight is blocked on Apple Developer Program enrollment/account support and local Apple Distribution signing credentials.
- Final owner-provided Droptune app icon assets were installed for iOS and Android.
- iOS startup polish was fixed after simulator verification: native launch is black and Flutter shows the white Droptune logo during app bootstrap, avoiding the previous white-square flash.
- First internal mobile builds should use staging Supabase and the closed-beta staging web URL until production Supabase/acquiring readiness is explicitly approved.

## Release blockers

### P0 — Must finish before public launch
- Obtain real T-Bank production terminal credentials and complete fiscalization/Receipt setup. Status: DEMO terminal smoke passed; production terminal pending.
- Replace mock payment completion with production provider callback/webhook flow. Status: DEMO provider E2E passed on `droptune.art`; production terminal smoke pending.
- Define and verify payment idempotency for duplicate provider callbacks. Status: implementation expected; live duplicate callback test still required.
- Confirm `payment_orders` transitions in production mode: `created -> payment_pending -> paid -> fulfilled` with real provider callbacks. Status: DEMO `CONFIRMED -> fulfilled` passed; production terminal smoke pending.
- Confirm T-Bank fiscalization/receipt requirements and online cash-register setup before real public sales.
- Verify clients cannot update payment lifecycle fields or execute ownership-issuing RPCs.
- Replace App Store placeholder fallback with real store/testflight/install link strategy.
- Verify mobile handles `droptune://album/{albumId}` cold start, warm start, logged-out state, and missing ownership state with real staging data. Status: closed beta staging smoke passed; warm unowned-link UX follow-up remains.
- Define mobile release readiness docs under `docs/platform/mobile/*`. Status: initial docs added.
- Verify mobile never initiates payment or direct ownership claim. Status: mobile audit passed.
- Verify mobile uses owned-copy entitlement checks before playback/library access. Status: closed beta staging smoke passed.
- Confirm production Supabase project has every migration in `supabase/migrations/*` applied in order.
- Smoke-test public album page, auth redirect, purchase, fulfillment, owned web state, and mobile handoff on staging. Status: closed beta mock-payment path passed; real T-Bank path pending.
- Establish production environment variables and secret ownership for web, backend payment endpoints, Supabase, and admin allowlist.
- Set web payment production environment values:
  - `TBANK_MOCK` must not be `true`
  - `TBANK_NOTIFICATION_URL=https://droptune.art/api/tbank/webhook`
  - `TBANK_SUCCESS_URL=https://droptune.art/payment/success`
  - `TBANK_FAIL_URL=https://droptune.art/payment/fail`
  - `NEXT_PUBLIC_DROPTUNE_APP_INSTALL_URL` must be real or intentionally routed through a launch-safe install page
- Add production Supabase Auth redirects after launch approval:
  - `https://droptune.art/auth/callback`
  - `https://www.droptune.art/auth/callback` only if `www` can reach auth before redirecting
- Set production mobile builds with `WEB_CATALOG_BASE_URL=https://droptune.art` only after production web launch is approved.
- Publish launch-ready support/legal URLs for store metadata. Status: pages are live on production domain:
  - `https://droptune.art/support`
  - `https://droptune.art/privacy`
  - `https://droptune.art/terms`

### Pre-acquiring public site — Allowed before payment launch
- Deploy `droptune.art` as an informational website for acquiring review.
- Keep `TBANK_MOCK=false` or unset in production.
- Keep `MOCK_PAYMENTS_ENABLED=false` or unset in production.
- Keep `DROPTUNE_DEPLOY_ENV=staging` unset in production.
- Do not expose active Buy/payment flow publicly until real T-Bank smoke passes.
- Root `/` must not be the default Next.js page. Status: replaced with canonical public landing page.
- Footer must link to `/support`, `/privacy`, and `/terms`.
- The site must make clear what Droptune sells/plans to sell without pretending payments are already live.

### Closed beta path — Allowed before real acquiring is ready
- Use staging Supabase only.
- Use `TBANK_MOCK=true` only with explicit staging safeguards:
  - `MOCK_PAYMENTS_ENABLED=true`
  - `DROPTUNE_DEPLOY_ENV=staging`
  - `BETA_PAYMENT_ALLOWLIST=<closed beta emails>`
- Mock fulfillment must still call `fulfill_payment_order` only from server/service-role code.
- Verify web mock purchase creates exactly one ownership row. Status: web staging smoke passed on 2026-06-21.
- Verify mobile can open/play the owned album via `droptune://album/{albumId}`. Status: closed beta staging smoke passed on 2026-06-23.
- Do not deploy this configuration to public production.
- Keep closed beta on `https://droptune-web-git-staging-beta-filipplyakh.vercel.app` unless `staging.droptune.art` is explicitly fixed, configured, and smoke-tested.
- If `staging.droptune.art` is fixed later, add it to staging Supabase Auth redirect URLs and update staging mobile `WEB_CATALOG_BASE_URL` only after confirming it serves the staging build with staging env.

### P1 — Should finish before store submission / serious beta
- Add production monitoring for payment failures, fulfillment failures, and admin publish failures.
- Add operational runbook for stuck orders in `payment_pending`, `paid`, and failed fulfillment states.
- Fix success page order display when T-Bank return URL does not include the app `order_id`.
- Clean stale `metadata.debug.last_error` when later provider status succeeds/fails with a newer stage.
- Restore/decide Vercel GitHub auto-deploy; latest production deploy was run manually with `npx vercel --prod`.
- Add release checklist for web deploy and mobile store builds.
- Define media QA checklist for album cover, audio, track art, previews, and storage URL validity.
- Decide whether `art_containers` video content is blocked from launch content or rendered in clients.
- Reconcile `purchases` as legacy/MVP table: either document exact remaining use or plan migration to ownership-only reads.
- Verify web `/album/[id]`, `/albums/[id]`, `/for-artists`, `/`, `/main` redirect, `/my`, login callback, and payment success routes.
- Verify email OTP auth copy and callback behavior on mobile browsers.
- Confirm legal/commercial launch basics: refund/support contact, privacy policy, terms, store metadata, age/content rating.

### P2 — Can follow after first production release
- Marketplace resale flow.
- NFT/custodial/lazy-mint layer.
- Dedicated video rendering for `art_containers`.
- Richer mobile platform architecture docs after implementation stabilizes.
- Data cleanup for legacy URLs and optional storage backfill.

## Workstreams

### 1. Production payments and fulfillment
Target outcome: a real payment can be completed once, fulfilled once, and audited.

Tasks:
- Implement provider callback/webhook endpoint using backend credentials only.
- Validate provider signature/token before marking an order paid.
- Make callback handling idempotent when provider retries the same event.
- Call `fulfill_payment_order` only from trusted backend/service role.
- Persist provider ids and error/debug metadata on every transition.
- Add smoke checks for successful payment, duplicate callback, canceled payment, failed payment, sold-out album, and already-owned album.

Docs to update:
- `docs/core/ARCHITECTURE.md`
- `docs/core/DATA_MODEL.md` if metadata semantics change
- new ADR if provider callback architecture or trust boundary changes materially

### 2. Web launch surface
Target outcome: public acquisition and owned-state behavior works without developer intervention.

Tasks:
- Keep `droptune.art` and `www.droptune.art` configured in Vercel, but do not run a production deployment before launch approval.
- For acquiring review, a limited production deployment is allowed only as a pre-acquiring informational site with payments disabled.
- Keep `www.droptune.art` redirecting to `droptune.art` as the canonical production host.
- Leave closed beta staging on the existing Vercel preview URL until there is a deliberate `staging.droptune.art` cutover.
- Verify unauthenticated public album viewing.
- Verify buy intent survives login redirect via `/login?redirect=/album/{albumId}?buy=1`.
- Verify owned album replaces Buy with Open in Droptune.
- Verify `/my` exists and shows owned albums if it remains a fallback.
- Replace mock success dependency with production success/failure pages.
- Replace placeholder store fallback with final install route or store URL.
- Keep `/main` as a legacy redirect to `/`.
- Add no-content and error states for missing album, unavailable media, sold out, auth failure, and payment failure.

Docs to update:
- `docs/platform/web/ARCHITECTURE_WEB.md`
- `docs/platform/web/ROADMAP_WEB.md`
- `docs/core/DEEP_LINKS.md` for final store fallback

### 3. Mobile app release surface
Target outcome: the app passes store review and reliably opens/plays owned albums.

Tasks:
- Document mobile architecture details: routes, auth, owned library, deep links, player lifecycle, offline/background expectations.
- Verify `PlayerService` is the only audio playback controller.
- Verify AlbumPage queue ordering uses `track_number`.
- Verify TrackPage does not start playback by itself.
- Verify owned album library reads from ownership model, not insecure legacy purchase state.
- Verify app behavior for no network, missing audio URL, expired session, and user without ownership.
- Implement and test platform deep-link registration for iOS and Android.
- Prepare app icons, launch screens, permissions, privacy labels, store screenshots, and review notes.

Docs to update:
- `docs/platform/mobile/README.md` or dedicated mobile architecture/roadmap docs
- `docs/core/DEEP_LINKS.md` if link formats or fallbacks change

### 4. Admin release ingestion
Target outcome: a new album can be prepared, uploaded, published, and verified without manual DB edits.

Tasks:
- Verify `/admin` allowlist and service-role-only draft access.
- Verify signed upload session flow for cover, audio, art, and previews.
- Verify storage paths follow the `media/albums/{album_id}/...` convention.
- Verify publish creates albums, tracks, art containers, previews, and album copies atomically enough for launch.
- Add validation for required album fields, duplicate track numbers, missing audio, and invalid public URLs.
- Add publish smoke-check notes for every new release.

Docs to update:
- `docs/platform/web/ARCHITECTURE_WEB.md`
- `docs/core/DATA_MODEL.md` if draft payload semantics become contractual

### 5. Supabase security and operations
Target outcome: production data is protected and schema drift is controlled.

Tasks:
- Apply all migrations to staging, then production.
- Run documented privilege checks for trusted RPCs and `admin_album_drafts`.
- Verify public SELECT policies are intentional for album/media catalog data.
- Verify users can only select their own `payment_orders`, `copy_ownership`, and related `transactions`.
- Verify no schema/RLS/RPC changes exist only in Supabase UI.
- Decide backup, restore, and forward-fix procedure for launch week.

Docs to update:
- `docs/core/DB_CHANGE_WORKFLOW.md`
- `supabase/MIGRATION_POLICY.md` only if workflow changes

### 6. QA matrix
Target outcome: release confidence is based on repeatable flows, not memory.

Minimum staging matrix:
- Web anonymous album view.
- Web login redirect with buy intent.
- Web successful payment and fulfillment.
- Web failed/canceled payment.
- Web sold-out album.
- Web already-owned album.
- Mobile login.
- Mobile owned library.
- Mobile deep link to owned album.
- Mobile deep link to unowned album.
- Mobile playback controls: play, pause, next, previous, background/lock-screen behavior if supported.
- Admin draft creation, upload, publish, and published album consumption on web/mobile.

## Suggested execution order
1. Freeze contracts: update stale roadmap dates, define mobile docs, finalize deep-link fallback.
2. While real acquiring is blocked, deploy closed-beta staging web with guarded mock payments. Status: done for staging.
3. Run staging Supabase migration verification. Status: done enough for web smoke; keep as preflight for future staging resets.
4. Run end-to-end closed beta smoke-test: web mock purchase -> server fulfillment -> ownership -> web owned state -> mobile deep link/playback. Status: passed for closed beta staging.
5. Obtain production T-Bank terminal credentials and confirm fiscalization/Receipt setup.
6. Deploy staging web with production-like payment callback configuration.
7. Run real T-Bank staging smoke-test: provider callback -> paid/fulfilled -> duplicate callback idempotency.
8. Harden mobile store build configuration: final package/bundle ids, signing, and real `--dart-define` values.
9. Harden web acquisition, success/failure states, and owned-state handoff based on smoke-test findings.
10. Validate admin ingestion with one real release candidate album.
11. Deploy web production only after real callback smoke-test passes.
12. Submit mobile beta/TestFlight/internal testing.
13. Submit mobile store release after beta smoke checks.

## Open decisions
- Which production payment provider mode and callback contract is final for launch?
- Is `/main` part of the public launch, or should the album/artist pages be the only entrypoints?
- Is `/my` a real web library for launch, or only a fallback placeholder?
- Should video art be launch-supported in clients, or should launch content avoid video art until rendering exists?
- Will launch use custom scheme only (`droptune://...`) or also universal/app links?
- What is the final store fallback URL before App Store / Play Store approval?
- What support/refund policy is shown after purchase?

## Done when
- Every P0 item is complete and smoke-tested on staging.
- Production migration state matches `supabase/migrations/*`.
- Web production purchase creates exactly one fulfilled ownership record.
- Mobile opens an owned album from the post-purchase handoff and plays its ordered queue.
- Admin can publish a release candidate album without manual DB edits.
- Store submission metadata, privacy disclosures, and support links are ready.
