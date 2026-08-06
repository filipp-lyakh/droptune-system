# Mobile Roadmap Notes

Status: mobile-specific  
Owners: Mobile Engineering  
Last updated: 2026-08-06  
Depends on: `docs/core/RELEASE_READINESS_PLAN.md`

## Current audit result

Mobile audit found no payment initiation and no direct ownership-issuing RPC calls in the app.

Local release-critical fixes completed in the mobile app:
- ownership check before album loading/playback
- deep link protection for unowned albums
- user-facing message for tracks without `audio_url`
- Android `INTERNET` permission
- Android deep-link filter for `droptune://album/...`

Validation reported by mobile audit:
- `flutter test` passed
- `flutter analyze` passed with no issues

## Closed beta staging smoke status

Status: passed for closed beta on 2026-06-23.

Verified:
- iOS simulator build installs and starts with staging config and real staging anon key
- Supabase init completes
- OS-level deep-link dispatch works for the smoke-test album
- logged-out deep link stays on Login and does not expose playback
- beta email login works
- owned library shows purchased album
- owned deep link opens purchased album
- owned track playback works
- logged-in cold-start unowned deep link shows a safe blocked state and does not expose playback
- no payment/checkout/fulfillment logic exists in mobile `lib`
- `flutter test` passed
- `flutter analyze` passed

Fixed:
- album access errors render user-facing text instead of an exception object string

Known follow-up:
- warm unowned link from an already-open owned album did not visibly switch screens in simulator; cold-start logged-in unowned blocking passed safely

## P0 — Before beta/store readiness

- Closed beta staging smoke-test with real Supabase configuration after web closed-beta mock purchase passed:
  - login with beta email OTP
  - owned library
  - deep link to owned album
  - cold-start deep link to unowned album while logged in
  - playback
- Provide real runtime configuration through `--dart-define`:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `WEB_CATALOG_BASE_URL`
- Replace Android placeholder application id/package id (`com.example...`) with final production id. Status: complete; `art.droptune.app` approved and applied on 2026-08-06.
- Configure Android release signing before Play internal testing.
- Configure Apple signing/team before TestFlight.

Distribution audit update (2026-08-06):
- iOS Runner and Android now use the owner-approved identifier `art.droptune.app`; store records must use the exact same value.
- iOS Team `RNH263F574` remains configured; local distribution credentials are required.
- Android release builds no longer fall back to the debug signing key; the owner-approved upload key, local Keychain password, and secure backup are ready. A signed staging AAB was built successfully.
- Google Play organization-account onboarding is waiting for the D-U-N-S application submitted on 2026-08-06.
- Final owner-provided app icon and branded black launch/startup treatment are installed for iOS and Android, and the Play listing asset is ready. iOS startup was verified on simulator after fixing the white-square flash. True Android adaptive layers remain later polish.
- Exact staging and production-like commands and store setup blockers are in `DISTRIBUTION_RELEASE_AUDIT.md`.

## P1 — Before wider beta

- Polish technical error states, especially raw `e.toString()` and placeholder copy such as `Arts error` / `No arts`.
- Prepare store metadata, screenshots, icons, launch screens, privacy labels, and review notes.
- Confirm behavior for no network, expired session, missing media, and unavailable album.

## P2 — After first beta

- Add richer mobile architecture docs after implementation stabilizes.
- Add dedicated video rendering if launch content starts using video `art_containers`.
