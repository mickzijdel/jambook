# CLAUDE.md

## What this app is

Jambook is a self-hosted songbook for house jam sessions. It is MIT licensed and written to be open-sourced. The host pushes "now playing" and a synced room key from their phone; every guest's phone follows, and each guest keeps their own capo per song. Each song has one hosted chord sheet, rendered in the browser with ChordSheetJS, and notes that the host edits live. Guests get in with one shared password; the host logs in. Most of this is not built yet.

UI: phone-first, dark theme by default, and every host action works one-handed on a phone.

## Read first

- Design: `docs/superpowers/specs/2026-10-30-jambook-design.md`. Read §6.4 "Spike-proven gotchas" before you touch live updates, the layout or the chord view.
- Plan: `docs/superpowers/plans/2026-10-30-jambook.md`. Its Global Constraints apply to every change; the main ones are below.
- `.claude/current_plan.md`, when it exists, names the last finished plan task. Resume from there.
- Before any Rails work, read the `rails-toolkit:rails-core` skill and the area skill the plan task names (`rails-toolkit` is enabled in `.claude/settings.local.json`). Where the plan and a skill disagree, the plan wins only where it says why.

## Run

- Setup: `mise install`, `bundle install`, `bin/rails db:prepare`.
- App: `bin/dev` (runs `bin/rails server` on port 3000).
- Development uses Solid Cable on SQLite (`storage/development_cable.sqlite3`). The test environment uses the `async` adapter so system tests get broadcasts in-process.

## Tests

- One file: `t test/models/song_test.rb` (or `file:line`). On this machine a hook blocks plain `bin/rails test`; use `t`.
- Full suite: `t` **and** `t test/system/*_test.rb`. Bare `t` skips system tests.
- CI runs `bin/rails test` and `bin/rails test:system` as separate jobs.
- System tests run headless Chrome at 390×844; `SYSTEM_TESTS_BROWSER=chrome` shows the browser.
- Minitest with fixtures only. One behaviour per test, at most 4 assertions, sentence names (`test "guests need the password"`). Shared helpers go in `test/test_helpers/`.

## Lint and hooks

- hk comes from mise. The pre-commit hook runs every linter in `hk.pkl` (rubocop, tests, herb, brakeman, bundler-audit, debride, flay, jscpd, gitleaks and more).
- Check changed files with `hk run check`, the whole repo with `hk run check --all`.
- RuboCop: rubocop-rails-omakase + rubocop-minitest + rubocop-mick. Run `bin/rubocop`; autofix with `bin/rubocop -A`.

## Rules not to break

- **Broadcasts are synchronous.** Use `broadcast_refresh` (for example `after_update_commit :broadcast_refresh`). Never `broadcasts_refreshes` or any `_later` broadcast: they go through Active Job, so a change made from a console or `bin/rails runner` never reaches guests.
- **Refresh meta tags go directly in the layout `<head>`:** `turbo_refresh_method_tag :morph`, `turbo_refresh_scroll_tag :preserve`, `turbo_exempts_page_from_cache_tag`. Never `turbo_refreshes_with` or `turbo_exempts_page_from_cache`: they `provide :head`, print nothing when called after `yield :head`, and Turbo silently falls back to replacing the whole page.
- **Nothing copyrighted or personal in git.** Fixtures and demo seeds use public-domain songs only (Amazing Grace, House of the Rising Sun, Scarborough Fair). Never commit song lists, Ultimate Guitar exports or bundles, `config/deploy.<dest>.yml`, `.kamal/secrets.<dest>` or `fnox.toml`.
- **Resources, not custom actions.** A state change gets its own controller (`Songs::PlaysController#create`, `Rooms::KeysController#update`). Each action gets a one-line route comment (`# PATCH /room/key`).
- **Never edit an existing fixture.** Add a new one.
- **Wrap every `localStorage` access in try/catch,** with an in-memory fallback (private browsing throws).
- **Access is deny-by-default.** Controllers require the host; guest-readable actions opt in with `allow_unauthenticated_access only:` and then pass `require_guest_access`.
- **Gems:** `rails new` defaults, the dev-env standard, `csv`, `strong_migrations` and `webmock` (test). Ask before adding any other.
- Bang method names only where a non-bang twin exists.
- Deploys need Mick's explicit go.

## Key package versions

Read from `.ruby-version` and `Gemfile.lock` on 2026-10-30. Update this list when you upgrade one.

- Ruby 4.0.2
- Rails 8.1.4
- turbo-rails 2.0.23
- stimulus-rails 1.3.4
- importmap-rails 2.2.3
- solid_cable 4.1.0
- sqlite3 2.10.1
- ChordSheetJS 18.0.0: planned, to be pinned with `bin/importmap pin chordsheetjs@18.0.0`
