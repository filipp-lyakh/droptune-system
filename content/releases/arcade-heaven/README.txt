Kid Comet — Arcade Heaven
Published 2026-11-25 (Europe/Moscow)

Production album/draft: e213aa34-fb30-4b63-8734-4f1dc33349fa
Public page: https://www.droptune.art/album/e213aa34-fb30-4b63-8734-4f1dc33349fa
Price: 0 RUB. Edition: 512 serial copies (1 through 512).
The production web smoke test claimed copy 1 for the signed-in owner account.

Music
All eleven tracks were selected by the user after listening. The final track is
Sunrise After Game Over, soft groove audition 04 B. No unselected music was
downloaded. Eleven original WAV masters remain in music/masters; delivery uses
AAC/M4A copies at a 256 kbps target. All delivery files were fully decoded and
checked for stereo, 48 kHz rate and matching duration. Exact prompts, lyrics,
Suno links, master hashes and durations are in music/*.json. The Kid Comet voice
profile is private. The sound is varied electronic indie with relaxed and more
upbeat tracks, occasional synth-pop/8-bit accents and restrained vocal doubling.

Visuals
One cover and 38 track artworks are uploaded. Every track has a story image and
an artist photo. Existing richer packs for tracks 2, 3 and 10 were preserved;
eight missing packs each gained a new scene and matching artist photo. Original
PNGs, optimized WebPs, generation prompts and hashes are saved under art/.
All 50 uploaded media files were fetched and matched to their local SHA-256.

Publication and verification
The backend admin publish flow created 11 tracks, 38 art rows and 512 copies.
Track titles/order and every track-to-art mapping were verified. Production UI
showed the published draft, the free claim button and then the owned state;
the gallery displayed the track cards. The gallery on web is a blurred preview.
The original WAV files and generated art originals remain local; production
contains delivery media. Native mobile playback was not exercised in this test.

Free issuance
ADR-005 and migration 20261125020000_add_backend_free_album_claim.sql add the
backend-only zero-price issuance path. Local tests, web build/lint, staging
concurrency and finite-supply tests passed. Temporary staging fixtures were
removed. The migration is applied on staging and production. Web commit 784daf9
and deployment dpl_9cQG5ypUuPQgwxA3xdAi1SQUSDZs support both album URL variants.
Production claim created one zero-price primary transaction and no payment order.
The current production transaction table lacks a status column; the existing
trusted issuance function remains compatible and no paid-flow backfill was made.

Existing production test content
The earlier Arcade Heaven test release d724b0ef-b54f-49f0-8ca6-9421a7b8ad3e
was preserved with its ownership. Its eleven audio URLs contain four unique
recordings; three match documented unrelated test songs. Those recordings were
not copied into the new edition. Existing paid flows and purchases were not
modified. Further catalog cleanup or another album is separate work.

Evidence
See evidence/admin-ingestion.json, production-publication.json,
staging-free-claim-smoke.json and delivery-audio-verification.json.
release.json is a local content manifest, not an admin API request.
Source concept: ChatGPT chat «Создание вымышленного альбома»,
6a0cb682-f020-83eb-a156-ab69df00b5bb. Original demo art series 01 maps to track 2,
series 02 to track 3, and series 03 to track 10.
