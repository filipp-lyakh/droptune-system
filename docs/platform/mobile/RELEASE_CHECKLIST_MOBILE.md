# Mobile Release Checklist

Status: working checklist; closed beta mobile smoke passed  
Owners: Mobile Engineering  
Last updated: 2026-08-06  
Depends on: `docs/core/DEEP_LINKS.md`, `docs/core/BUSINESS_RULES.md`

Distribution audit and commands: `DISTRIBUTION_RELEASE_AUDIT.md`.

## Build configuration

- Final Android application id is set. Status: complete; owner-approved value is `art.droptune.app`.
- Android release signing is configured. Status: complete locally; dedicated owner-approved upload key created outside version control, password stored in macOS Keychain, secure backup completed, and signed release AAB validation passed.
- Google Play organization account is verified. Status: pending; D-U-N-S application submitted to Interfax–D&B on 2026-08-06.
- Final app icon is installed. Status: complete for iOS required sizes, Android legacy launcher sizes, and the 512x512 Play listing asset; adaptive Android layers remain optional polish for a later build.
- Branded launch screen is installed. Status: complete; iOS native launch is black and Flutter shows the white Droptune logo during bootstrap, Android pre-12 uses black background with white Droptune wordmark, and Android 12+ uses the required system splash treatment with the branded app icon.
- iOS bundle id is final. Status: complete; owner-approved Runner value is `art.droptune.app`.
- Apple team/signing is configured. Status: Team `RNH263F574` is set, but the audited machine has no signing identity/profile.
- App version and build number are set. Status: currently `1.0.0+1`; owner must confirm that build/version code `1` is unused.
- Production/staging values are passed with `--dart-define`:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `WEB_CATALOG_BASE_URL`
  - Status: real staging values were used to build the first uploadable Android AAB on 2026-08-06.

## Security and ownership

- Mobile does not initiate payments.
- Mobile does not call ownership-issuing RPCs.
- Mobile checks ownership before album access/playback.
- Library reads from current ownership state, not legacy `purchases`.
- Unowned deep links do not expose track playback.

## Deep links

- iOS handles `droptune://album/{albumId}`.
- Android handles `droptune://album/{albumId}`.
- Cold start deep link works.
- Warm start deep link works.
- Logged-out deep link routes through auth or a safe blocked state.
- Unowned album deep link shows a safe blocked state.

## Playback

- `PlayerService` is the single playback owner.
- Album queue is ordered by `track_number`.
- Track without `audio_url` shows a user-facing message.
- Play, pause, next, and previous work.
- Missing/invalid media URL shows a useful error state.

## Smoke-test matrix

- Login with real Supabase. Status: passed for closed beta staging.
- Open owned library. Status: passed for closed beta staging.
- Open an owned album. Status: passed for closed beta staging.
- Open an unowned album.
- Open owned album from deep link. Status: passed for closed beta staging.
- Open unowned album from deep link. Status: cold-start logged-in safe blocking passed; warm-link UX follow-up remains.
- Play first track. Status: passed for closed beta staging.
- Switch tracks.
- Background/lock-screen behavior is verified if supported.

## Store readiness

- App icon is final. Status: complete for first internal builds; iOS required sizes, Android legacy launcher sizes, and Play 512x512 listing asset are installed. True Android adaptive layers remain optional polish.
- Launch screen is final. Status: complete for first internal builds; iOS white-square startup flash was fixed with a black native launch screen plus Flutter bootstrap logo.
- Privacy labels/disclosures are prepared.
- Store screenshots are prepared.
- Support URL is available. Status: complete; `https://droptune.art/support`.
- Privacy policy URL is available. Status: complete; `https://droptune.art/privacy`.
- Review notes explain that purchases happen on the web and mobile only plays owned albums. Status: draft required before store submission.
