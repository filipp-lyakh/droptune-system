# Droptune System Docs

Единый источник правды по кросс-платформенной архитектуре Droptune.

## Scope
- Product/system architecture
- Data contracts (Supabase schema semantics)
- Deep links and handoff flow
- Architecture Decision Records (ADR)
- Supabase DB migration workflow and policies

## Repositories consuming these docs
- `droptune-web`
- `droptune_mobile` (and related mobile repos)

## Workflow
1. Сначала фиксируем системное решение в `docs/core/*` или в новом ADR.
2. Затем вносим реализацию в web/mobile/backend.
3. Если меняется data contract или flow, обновление core docs обязательно в том же change set.

## Structure
- `docs/core` — кросс-платформенная истина
- `docs/adr` — архитектурные решения
- `docs/platform/web` — web-специфика (поверх core)
- `docs/platform/mobile` — mobile-специфика (поверх core)
- `docs/templates` — шаблоны для решений/доков
- `supabase/migrations` — versioned SQL changes for DB schema/RLS/RPC
- `supabase/MIGRATION_POLICY.md` — migration-first rules
