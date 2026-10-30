# Off-topic improvements

Noticed while building; not part of the plan.

- **herb rules:** `.herb.yml` targets herb 0.10.1; the installed 0.11.1 has 66 newer rules switched off. `bundle exec herb lint --upgrade` turns on the ones with no offences.
- **Room page polish:** the `#room-key` line and the chord status line both say "Room key X"; the capo buttons sit tight against the first chord row. Worth a design pass once it's used at a jam.
- **Song with no detectable key** (seen on real data: one of 103 sheets): the edit page could offer the most common chord as a one-tap key suggestion instead of a blank select.
- **`Song#playing?`** loads `Room.instance` on every call; fine at house scale, but pass the room in if it ever runs in a loop.

## Deferred from the final review (2026-10-30)

- Deleting any song refreshes every guest; a guest on the deleted song's own page gets a 404. Broadcast only when it was playing; send a missing song to `/`.
- With browser storage blocked, the capo resets on Turbo navigation (the in-memory copy belongs to one controller instance). A module-level map would keep it per tab.
- The "Now playing" banner isn't sticky and lacks "tap to join" (spec §6.3).
- Notes lose their line breaks (`simple_format` or `white-space: pre-line`).
- The search form drops the tag filter, and there's no tag control or way to clear it.
- Key −/+ buttons show for a song with no key and do nothing visible (silent 422): hide them.
- Import results: a needs-paste entry for a song that already has a sheet is listed as needing a paste; a song created and then matched in one bundle shows under both.
- `ug:fetch` still stops on network errors (timeouts, DNS); a re-run resumes, but it could record them like page errors.
- Missing regression tests: cable with a stale guest cookie or a host session; guests calling key, notes, bundle import or delete.
- The login page's inline `style=` will break once the CSP is enforced.
