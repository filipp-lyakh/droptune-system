# ADR-004: Shared layout-level header and footer

Status: Accepted  
Date: 2026-04-25

## Context
Header/footer variants had diverged between routes, and short pages did not always keep footer at viewport bottom.
This produced inconsistent navigation chrome and spacing.

## Decision
- Render one shared `Header` and one shared `SiteFooter` from root layout (`src/app/layout.tsx`).
- Normalize header horizontal paddings to 32px across routes (album reference spacing).
- Use route-aware logo/theme switching inside shared header (dark/light surfaces).
- Use flex-column app shell so footer behavior is deterministic on short and long pages.

## Consequences
- Navigation and branding become consistent across the web app.
- Route pages should not render their own standalone footer/header unless explicitly justified.
- Future visual tweaks to global chrome are centralized in two components.
