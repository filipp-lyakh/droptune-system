# iOS demo readiness — 2026-11-08

Status: BLOCKED at OTP; first TestFlight delivery remains completed, unified demo verification is not completed. No App Review submission or publication.

## Current evidence

- Owner identifies installed **1.0.0 (4)** on **iPhone 16 Pro / iOS 26.6.2**. OS value is recorded as reported, not independently verified. Bundle ID `art.droptune.app`, Team `RNH263F574`, internal group `Staging Internal`, App Apple ID `6818821329` unchanged.
- Build 4 was locally archived/exported, uploaded, processed by Apple, assigned internally and installed in October. A fresh App Store Connect status check is blocked by an endlessly loading sign-in form, confirmed by owner. No new upload or new invitation.
- Current unified smoke attempt: OTP fails with HTTP 500 `unexpected_failure`, `Error sending magic link email`. Further playback/link/network/visual checks in this run are pending. Do not convert prior build 3/4 results into a pass for this run.
- DNS incident is closed on owner confirmation after starting staging Supabase; no new diagnostic was performed on that incident.
- Historical email limit was 2/hour. Web documents dated October 4 instead describe enabled custom SMTP with 30/hour and REG.RU rejection `535 5.7.0 Invalid login or password`. After the owner restored Dashboard access, the fresh Auth log at `08 Nov 26 01:16:25` (UI time) confirms POST `/otp`, HTTP 500, `535 "5.7.0 Invalid login or password"`. SMTP authentication is rejected; delivery remains blocked until corrected and retested. Do not treat HTTP 500 as proof of quota exhaustion, promise that waiting fixes it, change providers, or alter auth protections. Owner/backend action: inspect the latest Auth error, correct existing delivery only if its cause is confirmed, then perform one owner-requested OTP delivery/login check. Never send passwords/OTP in chat.
- Anonymous staging root returns HTTP 200 without Vercel SSO; browser shows an informational landing with disabled catalog CTAs. Direct `/albums` loads three album links anonymously. Mobile opens the base/root URL; phone transition remains pending. Vercel-login blocker is superseded; the landing/catalog mismatch remains.
- Multitrack fixture is already prepared by the web team: `9ef711a1-1a7d-4e30-b58b-c4164d72b46b`, three tracks (72/401/349 s), beta user `filipp.lyakh@gmail.com`. Keep `81ee8dc9-f0f0-471d-abc1-e89825ea2201` unowned. No backend/payment/ownership changes in this task.

## Deliverables and next checks

- [Unified smoke and short demo script](../../../../droptune_mobile2/docs/platform/mobile/IOS_DEMO_SMOKE.md): OTP, library, multitrack controls and natural completion, cold/warm owned/unowned links, background/lock/return, logout/re-login, network loss/recovery and visual checks, all on one recorded build.
- [App Store preparation packet](../../../../droptune_mobile2/docs/platform/mobile/APP_STORE_PREPARATION.md): RU marketing draft for approval, EN review-notes template, code/SDK-backed privacy inventory, official Apple requirements, production checklist. No answers saved to Apple.
- Screenshots requested from the physical device; files not yet received. Large-iPhone and iPad final assets/QA remain required for the current universal target. Do not present the screenshot plan as completed assets.
- Demo readiness is not confirmed until login and the unified smoke succeed. Candidate stays build 4 unless a concrete app defect or configuration change requires a new build.

## External owner actions

Owner confirms the mailbox password is unknown. Current SMTP UI confirms custom SMTP enabled at `mail.hosting.reg.ru:465`; stored password is hidden. No setting was changed. Resume only after owner/mail operator recovers access to the existing mailbox and updates credentials directly, followed by one successful OTP check. No automatic password reset or SMTP disable: earlier UI warned that disabling resets templates/limits.

1. Owner/backend: Dashboard access was restored and the failed email's Auth log inspected. Fresh Auth logs confirm the SMTP credential rejection; owner must correct the existing mailbox credentials directly in the dashboard, then confirm one successful OTP delivery. Do not rotate credentials, disable SMTP or alter templates/limits without explicit owner involvement.
2. Web: provide an anonymous informational staging destination reachable from the agreed root, with demo browsing/return but no mobile-initiated checkout. Do not silently change the mobile base URL to the existing purchase-capable `/albums` path, expose other previews or modify production.
3. Web/operations: verify `https://droptune.art/support`, `/privacy`, `/terms` from an external network. Requests from the agent environment timed out resolving the public host, including outside sandbox; web reader also failed. Not proven globally down. Confirm active support mailbox (`hello@droptune.app` and SMTP `hello@droptune.art` appear in different historical records).
4. Product/backend before App Review: account deletion flow, reliable reviewer access, privacy data/log-retention answers, content licenses/territories and age questionnaire. Mobile before submission: accessible privacy entrypoint and agreed deletion/external-link behavior. These are submission issues, not deferred UI polish.

## Production boundary

Build 4 is staging/internal-only, not a production submission candidate. Before submission: backend/rights/data and deletion readiness → stable legal/support URLs and region/link decision → separate production client configuration → necessary app changes → new monotonically numbered production archive with current Apple SDK requirements and without internal-only restriction → internal TestFlight processing → full iPhone/iPad smoke and final screenshots → owner approval of all Apple answers and marketing → separate authorization for App Review. Never mix staging Supabase with production ownership or use service_role in mobile.

Lock-screen Now Playing controls, a new mail provider and general input/auth error-message polish remain post-v1 backlog by owner decision. The existing mail-delivery failure is a concrete demo blocker; this does not authorize a mail migration.

## Git and validation

At task start mobile HEAD `d28431b` included `a3c8a9f`; system HEAD `d5213b6` included `a12d102`. Direct `git ls-remote` checks on November 8 showed remote main still at mobile `d841d9d` and system `7705d4f`: those two commits in each repository were local. No push performed.

The earlier same-day Flutter analyze and 8 tests passed; this continuation changes documentation only. Recheck document diff, local links, secret/path exclusions and commit only task changes. Existing system core/web/fixture edits must remain unstaged. Commit hashes for this continuation are reported in the chat/git log rather than self-referential documentation.
