# Mobile Distribution Release Audit

Status: final identifiers set; store credentials required  
Owners: Product + Mobile Engineering  
Last updated: 2026-08-06  
Depends on: `../../core/RELEASE_READINESS_PLAN.md`, `RELEASE_CHECKLIST_MOBILE.md`

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
