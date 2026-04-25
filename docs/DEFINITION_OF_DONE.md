# Definition of Done (Docs & Architecture)

Change is done only if:

1. **Correct layer updated**
   - Core contract change -> `docs/core/*`
   - Platform-only detail -> `docs/platform/<platform>/*`

2. **Decision trace exists**
   - Major architecture decision has ADR entry (new or superseding).

3. **Entry docs still point correctly**
   - Web/mobile entrypoint docs reference current core files.

4. **No local machine paths**
   - No `/Users/...` absolute paths in docs.
   - Use relative local links (and optional canonical remote links).

5. **Status metadata is current**
   - `Last updated` and `Status` are updated in changed docs.
