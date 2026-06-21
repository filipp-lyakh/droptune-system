# Droptune Backlog

Status: working backlog  
Owners: Product + Engineering  
Last updated: 2026-06-21

## P1 - Web auth UX polish

- Replace the temporary login layout with a production-quality email OTP flow.
- Make copy unambiguous: users receive and enter a code, not a magic link.
- Add resend-code and change-email actions.
- Keep `/login` from rendering as an active auth form when the browser is already authenticated.
- Improve loading, error, expired-code, and rate-limit states.

## P1 - Staging setup automation

- Document or automate staging Supabase setup: migrations, storage bucket, admin allowlist, beta payment allowlist, and Auth email OTP template.
- Add a pre-smoke checklist that catches magic-link email template configuration before purchase testing.

## P2 - Web entrypoint cleanup

- Replace the default Next.js `/` page with a real Droptune entrypoint or redirect.
