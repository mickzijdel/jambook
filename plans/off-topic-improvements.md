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

- **Browser tests lose events when run in parallel** (cause not found; browser tests now run one at a time, `parallelize(workers: 1)` in ApplicationSystemTestCase). With 4 to 6 workers, 1 to 8 tests per run fail: a click on Save that never sends its POST (no request in the log), typing that never triggers the Stimulus action, a Turbo frame that never loads, live updates that never land. Serial runs always pass. Ruled out on 2026-10-31: slow pages (a 5 s Capybara wait changed nothing; the suite takes ~15 s), resync refreshes (none recorded in failing tests), cable leaking between workers (the test adapter is in-process `async`), the sign-in rate limit (~3 sign-ins per worker), the CSP warnings (report-only), the service worker (empty). Next: tag the test log per worker and record page events before the session resets (the teardown hook ran after `about:blank`). Found on 2026-10-31 for "a half-written note survives a refresh" (it also failed alone, 4 of 6, while the laptop was busy; 0 of 20 once quiet): after the test's refresh morph, the note form is gone and ~100 ms later the page fetches /notes/edit again, which matches Turbo's 100 ms hover prefetch of the "Add note" link reappearing under the pointer. So the morph replaced the frame's form despite its unsaved input. Removing either the chord bar wrap or the chord card from songs/_sheet made it pass 5 of 5 in that busy period. One suspect to test: Turbo dispatches turbo:before-morph-element on <html> when the element is no longer connected, but resync listens on <body> and reads event.target, so such a removal would never be vetoed; listening on the document and reading event.detail.currentElement would close that gap.
- **Words read as chords get transposed in the sheet** (found 2026-10-31 while checking chord diagrams against the local library): the Ultimate Guitar parser takes some lyric or label lines for chord lines ("From", "Californication", "Farquaad:", "Ah-Ah,"), so with a key set they show as "Ebrom", "Bbalifornication". Chord boxes already skip them (`findShapes` returns null); the sheet could do the same by keeping a "chord" that `findShapes` rejects as lyrics.
