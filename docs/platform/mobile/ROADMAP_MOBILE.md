# Mobile Roadmap Notes

Status: mobile-specific  
Owners: Mobile Engineering  
Last updated: 2026-11-08
Depends on: `docs/core/RELEASE_READINESS_PLAN.md`

<!-- testflight-staging-2026-10-03:start -->
## Verified TestFlight work — 2026-10-03

This dated evidence supersedes older iOS distribution blockers below. It does not change production launch readiness or Android status.

FINAL DELIVERY: staging 1.0.0 (4) locally built, uploaded, processed by Apple, available to Staging Internal, and installed on iPhone 16 Pro. Owner confirms logout fixes plus successful OTP re-login and playback after quota recovery. On 2026-11-08 the owner confirmed track switching works. The build number, album and iOS version for this later check were not specified; do not retroactively assign it to build 3 or 4. Link/background tests were performed on build 3, not independently repeated on build 4. Do not label all scenarios passed on a single final build.

- Apple Developer Program verified in the signed-in portal: Filipp Liakh, Team `RNH263F574`, active through 2027-09-24; license agreements accepted. Bundle ID remains `art.droptune.app`.
- App Store Connect record created and verified: Droptune, Apple ID `6818821329`, SKU `droptune-ios`, primary language Russian. No previous builds existed when checked.
- Internal group `Staging Internal` created with automatic distribution disabled; the existing Account Holder Apple Account is added. No new administrative roles were granted. Droptune OTP login still uses the beta email independently of the TestFlight Apple Account.
- Actual staging configuration recovered from the existing ignored local configuration: Supabase project `rncutejdfmqkmxwzfxup`, publishable client key (not service_role), and the approved staging Vercel catalog URL. Auth settings API responds with email auth enabled. Compiled IPA contains all three intended values; no key is included in this document.
- App remains consumption-only; payment/ownership issuance contracts and backend are unchanged. Anonymous catalog access still redirects to Vercel login; deployment protection was not changed.
- Local checks: `flutter analyze --no-pub` passed; `flutter test --no-pub` passed 5/5, including initial/warm navigation regression. These tests do not establish physical-device or real signed-in ownership success.
- Warm-link fix requests a frame while idle. iOS SceneDelegate bridges cold/warm URLs to app_links 6.x; the default Flutter link handler is disabled. For OTP-code auth, Supabase URL-session detection is disabled so it does not consume the initial album link during bootstrap.
- Minimum iOS is now consistently 15.0 (matching the existing Podfile). Xcode 26.2 / iOS SDK 26.2 archive compiled successfully; required plugin/Flutter privacy manifests are included.
- LOCALLY BUILT: signed App Store IPA `1.0.0 (3)` produced. SHA-256 `8f809f59a1bfebfcea956c2bdb1ec8a64ee8545ce7c1ee1ec60aefbacf3436a2`. Distribution export successfully created an App Store provisioning profile for the unchanged team/app ID.
- UPLOADED: `1.0.0 (1)` succeeded at 19:07 MSK, with `testFlightInternalTestingOnly=true` and build renumbering disabled. Build 1 is superseded by the cold-start bootstrap fix and must not be assigned to the tester group. Build 2 upload succeeded at 19:14 MSK, with the same internal-only options.
- Upload warning for builds 1, 2, and 3: missing objective_c.framework dSYM; upload itself succeeded. This affects crash symbolication for that dependency; the original native-asset library has no debug symbols to recover with dsymutil.
- APPLE PROCESSED: build 1 rejected with ITMS-90683 (owner supplied Apple email): audio_session contains microphone permission APIs without NSMicrophoneUsageDescription. App Store Connect also confirms build 2 failed; neither build is distributed.
- Build 3 contains AUDIO_SESSION_MICROPHONE=0 in the CocoaPods audio_session target, per the installed plugin documentation, to exclude unused recording permission APIs. Confirmed that protected selectors recordPermission and requestRecordPermission: are absent throughout Runner.app (both existed in build 2). Build 3 upload succeeded at 19:23 MSK. APPLE PROCESSED: build 3 delivery shows Completed. Owner confirmed standard encryption in addition to Apple's OS and no distribution in France; those exact answers were saved. Missing Compliance cleared, and the build reached Ready to Test, then Testing after assignment to Staging Internal.
- Beta description, public feedback address hello@droptune.app, and privacy URL https://droptune.art/privacy saved in TestFlight. No external/public review was submitted.
- AVAILABLE TO TESTER: confirmed in App Store Connect: build 3 is Testing in Staging Internal (1 build, 1 tester). The existing owner is Invited as of 2026-10-03. Owner subsequently confirmed downloading the app from TestFlight and signing in on the phone.
- INSTALLED: owner confirms installation and the requested update/retest on iPhone 16 Pro with build 4. iOS version has not yet been reported.
- DEVICE SMOKE (build 3): confirmed by owner, with the limits below: successful sign-in, library showing one album, opening the album, audible playback, pause and resume. Track switching was not verified in the 2026-10-03 run because that album had one track. A separate owner confirmation on 2026-11-08 reports switching works, without specifying the build or album. Cold/warm owned links for d364cd8c-aafd-4f85-9d4a-d917c6916217 passed by owner report: the album opens both from the running app and after fully closing it. Cold unowned denial also passed by owner report. LOGOUT FAILED on build 3: the menu item is unreadable, and after signing out the login screen appears but audio and the mini-player remain active. Warm unowned link above the owned album passed by owner report: current build shows Album not found in library. Owner additionally confirmed uninterrupted audio on the home screen and during 15-20 seconds of screen lock, then working app UI and pause after unlocking and returning. Background/lock/return smoke passed. FUTURE MOBILE TASK: native iOS lock-screen Now Playing player with artwork, track/artist, progress and synchronized playback controls; requested by owner, not implemented or verified in build 3. See mobile ROADMAP_MOBILE.md.

- DEVICE LINK BLOCKER RESOLVED: owner identified and removed a second, nonworking Droptune installation. Retrying the warm unowned link now opens the current app and shows Album not found in library. Build 3 remained Testing; no new binary was needed for this device blocker. A conflict with the old installation is consistent with the result, but its bundle ID and URL registration were not independently inspected.

- BUILD 4 AVAILABLE: fixed logout menu contrast; global auth changes now stop playback, clear queue/current-track metadata, invalidate in-flight loads/seeks, and dismiss previous-account routes. Analyze passed and all 8 tests passed, including logout playback and async-race regressions. Archive and signed App Store IPA 1.0.0 (4) succeeded. IPA SHA-256: 9aed9ae8e022e99fe4dba7c996a1e732af8f18ac20525a4ad542e1943e15d39b. Bundle ID, build number, embedded staging values and exclusion of microphone permission API verified. Upload succeeded at 20:07 MSK on 2026-10-03 with internal-only options; the known objective_c dSYM warning persists. Apple processing completed. Export-compliance answers reused the owner-confirmed unchanged encryption and France scope. Build 4 assigned to Staging Internal and status Testing confirmed in App Store Connect. Owner confirmed update and physical logout regression on build 4: logout label is readable, audio stops, mini-player disappears, login screen appears. Sign-in and playback before logout also passed in this scenario. Re-login after the cleared session initially hit HTTP 429 / over_email_send_rate_limit; after waiting, the owner confirmed OTP delivery, re-login and playback all work on build 4. Link/background results above belong to build 3 and were not independently repeated on build 4. Lock-screen player remains a future task.

- OTP DELIVERY BLOCKER RESOLVED FOR THIS ATTEMPT: build 4 re-login hit Supabase email-send rate limiting (owner screenshot). After waiting for quota recovery, owner confirmed new code delivery, re-login and playback. After owner login, Dashboard inspection of Droptune Staging (rncutejdfmqkmxwzfxup) confirms the built-in email provider and an email sending limit of 2 emails/hour/project; the limit field is disabled and custom SMTP is not configured. The owner waited and completed the remaining re-login check; exact quota reset time is unknown. The quota itself remains unchanged and can recur. Repeated testing requires a separately configured mail provider. No rate limits or authentication protections changed and no extra OTP requests sent by the agent. Follow up on staging mail configuration and user-friendly error UI; raw exception copy remains in build 4. References: https://supabase.com/docs/guides/auth/rate-limits and https://supabase.com/docs/guides/auth/auth-smtp.

- OWNER DECISION: wait for email quota refill without changing SMTP or limits. One-time follow-up scheduled for 2026-10-03 21:20 MSK to ask for one OTP request, re-login and playback on build 4. This is a retry time, not a guaranteed reset. The one-time follow-up ran at 21:34 MSK; owner subsequently confirmed all requested steps work. Re-login is passed; no further reminder created.
- RELEASE SCOPE DECISION — 2026-11-08: the owner deferred native lock-screen Now Playing controls, email provider configuration, and user-facing input/auth error messages to the post-v1 backlog. They are not requirements for the first version. Existing mail quotas and raw error messages remain accepted limitations; no mail settings or authentication protections changed.
- PRE-COMMIT VALIDATION — 2026-11-08: Flutter analyze passed; all 8 Flutter tests passed; Info.plist and Xcode project passed plutil lint; Podfile passed Ruby syntax validation. No new archive or upload was performed during this check.
<!-- testflight-staging-2026-10-03:end -->

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
