# Off-topic improvements

Noticed while building; not part of the plan.

- **herb rules:** `.herb.yml` targets herb 0.10.1; the installed 0.11.1 has 66 newer rules switched off. `bundle exec herb lint --upgrade` turns on the ones with no offences.
- **Room page polish:** the `#room-key` line and the chord status line both say "Room key X"; the capo buttons sit tight against the first chord row. Worth a design pass once it's used at a jam.
- **Song with no detectable key** (seen on real data: one of 103 sheets): the edit page could offer the most common chord as a one-tap key suggestion instead of a blank select.
- **`Song#playing?`** loads `Room.instance` on every call; fine at house scale, but pass the room in if it ever runs in a loop.

## Deferred from the final review (2026-10-30)

- Deleting any song refreshes every guest; a guest on the deleted song's own page gets a 404. Broadcast only when it was playing; send a missing song to `/`.
- The "Now playing" banner isn't sticky and lacks "tap to join" (spec §6.3).
- Notes lose their line breaks (`simple_format` or `white-space: pre-line`).
- The search form drops the tag filter, and there's no tag control or way to clear it.
- Key −/+ buttons show for a song with no key and do nothing visible (silent 422): hide them.
- Import results: a needs-paste entry for a song that already has a sheet is listed as needing a paste; a song created and then matched in one bundle shows under both.
- `ug:fetch` still stops on network errors (timeouts, DNS); a re-run resumes, but it could record them like page errors.
- Missing regression tests: cable with a stale guest cookie or a host session; guests calling key, notes, bundle import or delete.
- The login page's inline `style=` will break once the CSP is enforced.

## Seen during the design pass (2026-10-30)

- **Browser tests flake with 6 parallel workers on the laptop** (and on the commit before the design fixes too; once in a serial run on 2026-10-31, "the host edits the note live"): 1 to 4 failures in about half of the runs, always a click that never lands (sign in, guest password, Save) or a live update that never arrives. The test log shows no slow requests, a serial run (`PARALLEL_WORKERS=1 bin/rails test:system`) passes, and CI passes. Suspect `resync_controller` calling `Turbo.session.refresh` (cable reconnect or `visibilitychange`) while a form submit is in flight, or Capybara's 2 s wait. If it's the refresh, a real host could lose a form submit too.
- **Words read as chords get transposed in the sheet** (found 2026-10-31 while checking chord diagrams against the local library): the Ultimate Guitar parser takes some lyric or label lines for chord lines ("From", "Californication", "Farquaad:", "Ah-Ah,"), so with a key set they show as "Ebrom", "Bbalifornication". Chord boxes already skip them (`findShapes` returns null); the sheet could do the same by keeping a "chord" that `findShapes` rejects as lyrics.
- **The official-tab stand-in can be a different song** (found 2026-10-31): `Ug::Search.best_free_chords` takes the most-voted free Chords result from the search without checking its title, so "Red Hot Chili Peppers Cant Stop" became Californication. 7 of 16 saved official tabs got the wrong song (Seasons of Love, Can't Stop, I Can See You, Dreams, Old Time Rock and Roll, Murder on the Dancefloor, This Must Be the Place). Fix: keep only results whose song name matches the official title; then re-fetch those 7 and replace them in production.
