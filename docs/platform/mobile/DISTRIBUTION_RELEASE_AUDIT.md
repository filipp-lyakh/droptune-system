# Mobile Distribution Release Audit

Status: final identifiers set; store credentials required  
Owners: Product + Mobile Engineering  
Last updated: 2026-11-08
Depends on: `../../core/RELEASE_READINESS_PLAN.md`, `RELEASE_CHECKLIST_MOBILE.md`

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
- DNS INCIDENT RESOLVED — 2026-11-08: the owner confirmed the later Failed host lookup login error was resolved by starting the staging Supabase project; the project had not been running. Closed on owner confirmation, without a new independent agent check. No code fix or new binary was needed. This does not change the separate email quota limitation.
<!-- testflight-staging-2026-10-03:end -->

## Recommended first distribution track

Use the staging Supabase project and the already smoke-tested staging web URL for the first internal TestFlight and Google Play Internal Testing builds. This keeps beta ownership and login data isolated from production while production acquiring/fiscalization is unfinished.

Use a production-like build only after production Supabase readiness is confirmed. A production-like build must use one environment consistently: do not combine staging Supabase with the production web catalog.

The mobile app remains consumption-only: it shows owned albums and plays them. It must not contain checkout, payment initiation, or ownership-issuing calls.

## iOS audit

| Area | Current state | Distribution status |
| --- | --- | --- |
| Bundle identifier | `art.droptune.app` for Runner | Final owner-approved value. App Store Connect and the Apple App ID must use this exact value. |
| Signing | Automatic signing, Team `RNH263F574` | The local machine has no valid code-signing identity or provisioning profile. Install or create Apple Distribution credentials through the approved Apple Developer account. |
| App Store Connect | Cannot be verified from the repository | Create/verify the app record, Agreements/Tax/Banking state as applicable, user roles, TestFlight internal group, export compliance answers, and beta test information. |
| Version | `1.0.0+1` in `pubspec.yaml` | Valid initial values if neither store has received build `1`; every later upload needs a higher build number. Owner must confirm the initial marketing version. |
| App icon | Final owner-provided Droptune artwork installed in every required iPhone/iPad/marketing size | Ready. All generated PNGs are opaque, including the 1024x1024 App Store icon, and an unsigned release build passed. |
| Launch/startup screen | Black native storyboard followed by a Flutter bootstrap screen with the white Droptune logo | Ready for first internal builds. The earlier iOS simulator white-square flash was fixed by removing the logo from the native launch storyboard, keeping the Flutter root view black, and showing the logo from Flutter during initialization. |
| Permissions/privacy strings | `UIBackgroundModes=audio`; no protected camera, microphone, photo, location, contacts, or Bluetooth APIs found | No `NS*UsageDescription` key is currently required by app code. Re-audit after dependency or feature changes. Complete App Privacy answers for account email/user ID and any diagnostics actually collected. |
| Privacy manifest | No app-level `PrivacyInfo.xcprivacy` found | Archive validation must confirm whether current Flutter/plugins supply all required-reason declarations. Do not invent declarations without reviewing the produced archive. |
| Deep link | `droptune` URL scheme registered; Dart parser accepts `droptune://album/{albumId}` | Registration is ready. Re-test cold start, warm start, logged-out, owned, and unowned cases on a physical TestFlight device. |
| Toolchain | Xcode 26.2 is installed | Meets the current App Store Connect requirement to build iOS apps with Xcode 16 or later. |

### App Store Connect setup still required

- Confirm or create an explicit App ID for the final bundle identifier.
- Create an App Store Connect app with the same bundle identifier and SKU.
- Confirm account holder agreements and the roles needed to upload/manage builds.
- Add an internal TestFlight group and internal users.
- Fill Beta App Description, Feedback Email (`hello@droptune.app` if approved), What to Test, export compliance, and review contact/sign-in instructions.
- Use `https://droptune.art/support` and `https://droptune.art/privacy`; keep `https://droptune.art/terms` available for legal metadata.
- Explain in review notes that the app is a music reader/consumption app for previously acquired albums and contains no payment or ownership issuance.

## Android audit

| Area | Current state | Distribution status |
| --- | --- | --- |
| Application ID | `art.droptune.app` | Final owner-approved value. The Play Console app must use this exact value. |
| Namespace/Kotlin package | `art.droptune.app` | Updated together with the application ID, including the `MainActivity.kt` package/path. |
| Release signing | Dedicated upload key created with owner approval; Play App Signing remains recommended | Release builds use private local values or `DROPTUNE_ANDROID_*` environment values and fail instead of falling back to the debug key. The keystore is outside version control and its password is stored in the macOS Keychain. |
| Version | `versionName=1.0.0`, `versionCode=1` from `pubspec.yaml` | Valid only if Play has never received version code `1`; later uploads must increment it. |
| SDK levels | Flutter defaults: compile/target API 36, minimum API 24 | Local Android toolchain is installed and healthy. Meets the Google Play API 36 requirement that starts 2026-08-31. Verify the merged manifest in the final AAB. |
| App icon | Final owner-provided Droptune artwork installed in all legacy density sizes; separate opaque 512x512 Play listing icon prepared | Ready for the first internal build. True adaptive foreground/background resources remain a later polish item because the supplied source is a single flattened composition rather than separate layers. |
| Launch screen | Black native launch background with the centered white Droptune wordmark on Android 11 and earlier | Ready. Android 12+ uses the mandatory system splash treatment: black background with the branded app icon, because the OS masks the central splash icon and cannot safely display the wide wordmark there. |
| Permissions | Main manifest requests `INTERNET`; the merged app also contains `ACCESS_NETWORK_STATE` from dependencies | Appropriate for current streaming/auth behavior; neither is a dangerous runtime permission. Re-audit if notifications, downloads, media library, or a foreground playback service are added. |
| Deep link | One VIEW/BROWSABLE filter for scheme `droptune`, host `album`, path prefix `/`; activity is exported and `singleTop` | Registration is ready for `droptune://album/{albumId}`. Re-test on an installed internal-track build. |

Google Play organization-account onboarding is waiting for the D-U-N-S record for the Russian individual entrepreneur. The owner submitted the D-U-N-S application to Interfax–D&B on 2026-08-06. The signed staging AAB can be uploaded after the Play Console account and app record are available.

## Store-policy boundary

The app currently has an `Открыть каталог` action that launches `WEB_CATALOG_BASE_URL` in the system browser. The production site currently has commerce disabled, so this does not initiate payment in the present beta. Before enabling production commerce or submitting for public review, Product must decide the store-compliant reader-app/link strategy. Apple and Google generally restrict leading users to external payment for digital content unless the applicable reader/external-link program and regional requirements are satisfied.

For the first internal builds, keep the destination on the staging informational/beta surface and do not expose an active payment path from the app.

## Build commands

Run from the mobile repository root. Replace key placeholders locally; never commit keys or resolved secrets.

### iOS staging TestFlight build

```bash
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=SUPABASE_URL=https://rncutejdfmqkmxwzfxup.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<STAGING_SUPABASE_ANON_KEY> \
  --dart-define=WEB_CATALOG_BASE_URL=https://droptune-web-git-staging-beta-filipplyakh.vercel.app
```

### iOS production-like TestFlight build

```bash
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=SUPABASE_URL=<PRODUCTION_SUPABASE_URL> \
  --dart-define=SUPABASE_ANON_KEY=<PRODUCTION_SUPABASE_ANON_KEY> \
  --dart-define=WEB_CATALOG_BASE_URL=https://droptune.art
```

Upload after successful local validation:

```bash
xcrun altool --validate-app --type ios --file build/ios/ipa/*.ipa \
  --apiKey <APP_STORE_CONNECT_API_KEY_ID> \
  --apiIssuer <APP_STORE_CONNECT_ISSUER_ID>
xcrun altool --upload-app --type ios --file build/ios/ipa/*.ipa \
  --apiKey <APP_STORE_CONNECT_API_KEY_ID> \
  --apiIssuer <APP_STORE_CONNECT_ISSUER_ID>
```

Alternatively, open `build/ios/archive/Runner.xcarchive`, then use Xcode Organizer: Validate App, Distribute App, App Store Connect, Upload.

### Android signing setup

The owner-approved upload key is stored outside version control and its password is in the macOS Keychain. Local macOS builds should use `tool/with_android_signing.sh`; CI may provide the documented `DROPTUNE_ANDROID_*` environment values. Prefer Play App Signing and keep a separate secure backup of the upload key and password.

### Android staging Internal Testing build

```bash
tool/with_android_signing.sh flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=SUPABASE_URL=https://rncutejdfmqkmxwzfxup.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<STAGING_SUPABASE_ANON_KEY> \
  --dart-define=WEB_CATALOG_BASE_URL=https://droptune-web-git-staging-beta-filipplyakh.vercel.app
```

### Android production-like Internal Testing build

```bash
tool/with_android_signing.sh flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=1 \
  --dart-define=SUPABASE_URL=<PRODUCTION_SUPABASE_URL> \
  --dart-define=SUPABASE_ANON_KEY=<PRODUCTION_SUPABASE_ANON_KEY> \
  --dart-define=WEB_CATALOG_BASE_URL=https://droptune.art
```

Upload `build/app/outputs/bundle/release/app-release.aab` in Play Console under Testing, Internal testing, create/select a release, add the AAB, review, and start rollout to the internal track.

## Owner decisions

1. Confirm `1.0.0` as the initial marketing version and whether build/version code `1` is unused in both stores.
2. Provide/approve final square app artwork and launch-screen treatment.
3. Confirm the Apple Developer team/app record and install Apple Distribution credentials on the build machine.
4. Android upload-key creation and secure backup: complete with owner approval.
5. First Android internal build environment: staging selected. Choose the environment again for later builds; production-like remains a separate explicit choice.
6. Decide the public store reader-app/external catalog link policy before production commerce becomes reachable.

## Local validation result

- `flutter analyze`: passed with no issues on 2026-08-06.
- `flutter analyze lib/main.dart`: passed with no issues after the iOS startup polish on 2026-08-06.
- `flutter test`: all tests passed on 2026-08-06.
- Unsigned iOS device release compile: passed with Xcode 26.2 after the final ID change; produced `Runner.app` for `art.droptune.app`.
- iOS simulator startup polish: passed on build `1.0.0+3`; fresh install on iPhone 16e simulator removed the previous white-square flash and showed the black startup with white Droptune logo.
- Signed IPA/archive validation: not run because the audited machine has no valid Apple signing identity/profile.
- Android toolchain: passed `flutter doctor` with Android SDK 36, Java 17, and all licenses accepted.
- Android debug APK compile: passed after the final ID change; confirmed package `art.droptune.app`, version `1.0.0+1`, target/compile API 36, minimum API 24, and launch activity `art.droptune.app.MainActivity`.
- Signed Android release AAB compile: passed with the dedicated upload key; signature verification passed.
- Uploadable staging AAB: rebuilt successfully with the final branded icon and launch screen on 2026-08-06 using the real staging Supabase publishable key and staging web catalog URL. Output: `build/app/outputs/bundle/release/app-release.aab`, version `1.0.0+1`, SHA-256 `55b324f3660d57c3ede691f2278692f78ce0f780821f70cbef0dadb478bd6fdc`.
