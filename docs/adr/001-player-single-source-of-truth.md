# ADR-001: PlayerService as single source of truth

Status: Accepted  
Date: 2026-03-03

## Context
We observed race conditions and inconsistent playback when pages directly controlled audio source.
Also UI navigation created “delayed queues”.

## Decision
All playback actions go through PlayerService:
- setQueue / playTrackById / toggle / next / prev
Pages must not call setAudioSource.

## Consequences
- Easier debugging via PlayerService logs
- Fewer duplicated “who owns playback” issues
- Some refactors needed when adding advanced UX (crossfade, preload, etc.)
