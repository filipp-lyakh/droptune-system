# ADR Index

| ID | Status | Date | Title | Summary |
|---|---|---|---|---|
| ADR-001 | Accepted | 2026-03-03 | PlayerService as single source of truth | Centralized playback ownership in player layer |
| ADR-002 | Accepted | 2026-03-03 | Two-table ownership model | `album_copies` + `copy_ownership` + `transactions` |
| ADR-003 | Proposed | 2026-03-03 | NFT via custodial + lazy mint | Future optional web3 layer without crypto UX |
| ADR-004 | Accepted | 2026-04-25 | Shared layout-level header and footer | Unified global shell for web routes |

## Rules
- Новое системное решение оформляется отдельным ADR.
- Изменение уже принятого решения оформляется новым ADR (supersedes), а не переписыванием истории.
- Ссылки на связанные PR/implementation changes добавляются в соответствующий ADR.
