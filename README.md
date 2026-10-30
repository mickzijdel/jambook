# Jambook

A self-hosted songbook for house jam sessions. The host picks the song on their phone, and every guest's phone follows: same song, same key, with each guest's own capo.

> **Status: early.** Everything below is built and tested, but it has not been used at a real jam yet.

## Why

At a jam, everyone looks up their own chord sheet. That means ads, paywalls, versions in different keys, and nobody is sure which song is on. Jambook gives the room one song list and one chord sheet per song, and the host runs the room from a phone. Guests need no app and no account.

## Features

- **Now playing:** the host taps a song, and every guest's screen switches to it within about a second.
- **Room key and your own capo:** the host sets the key the room plays in. Each guest keeps their own capo per song, so when the key changes, their chords move and their capo stays put.
- **One chord sheet per song,** hosted in the app and rendered in the browser. Paste ChordPro, chords over lyrics, or Ultimate Guitar text.
- **Notes per song** that everyone sees and the host can edit mid-song.
- **Song list** with a status (*liked* or *maybe*) and tags, searchable on a phone.
- **Import** a song list from CSV, your Ultimate Guitar saved tabs, or paste chord text into any song.
- **Simple access:** guests type one shared password; the host logs in. Every page sits behind the password and asks search engines not to index it, because chord sheets usually contain copyrighted lyrics.
- **Installable** on a phone's home screen as a web app.

Jambook is one install per host. It is not a hosted multi-user service.

## Built with

- Ruby 4.0.2
- Rails 8.1.4
- SQLite (sqlite3 gem 2.10.1)
- Hotwire: turbo-rails 2.0.23 and stimulus-rails 1.3.4
- importmap-rails 2.2.3, so there is no JavaScript build step
- Solid Cable 4.1.0 for live updates over Action Cable, stored in SQLite
- [ChordSheetJS](https://github.com/martijnversluis/ChordSheetJS) 18.0.0 to parse, transpose and render chord sheets in the browser

## Setup

You need Ruby 4.0.2 (pinned in `.ruby-version`; any Ruby version manager works) and [mise](https://mise.jdx.dev) for the dev tools.

```sh
mise install          # dev tools from mise.toml: hk, gitleaks, Node and others
bundle install
bin/rails db:prepare  # creates the SQLite databases in storage/
```

## Usage

Start the app, then open http://localhost:3000:

```sh
./bin/dev
```

## Running tests

```sh
bin/rails test          # model, controller and integration tests
bin/rails test:system   # browser tests in headless Chrome
```

System tests need Chrome. Set `SYSTEM_TESTS_BROWSER=chrome` to watch them run in a visible window.

Lint and pre-commit checks run through [hk](https://hk.jdx.dev), installed by mise:

```sh
hk run check --all
```

## Self-hosting

Jambook deploys with [Kamal](https://kamal-deploy.org) to one server, with SQLite on a Docker volume.

1. Copy `config/deploy.example.yml` to `config/deploy.<name>.yml` (gitignored) and fill in your server, domain and registry.
2. Point your domain's DNS at the server, then run:
   ```sh
   KAMAL_REGISTRY_PASSWORD=<registry token> bin/kamal setup -d <name>
   ```
   Kamal reads `RAILS_MASTER_KEY` from `config/master.key` (see `.kamal/secrets-common`).
   Behind Cloudflare's proxy, also set `forward_headers: true` (see the example file), or every visitor looks like Cloudflare to the password limits.
3. Create your host login and set the guest password:
   ```sh
   bin/kamal app exec -d <name> -i "bin/rails jambook:host EMAIL=you@example.com"
   ```
   Then sign in at `/session/new` and open Settings from the song list.

## Importing a song list

On the Import page, upload a CSV with this header:

```csv
title,artist,status,tags
Amazing Grace,John Newton,liked,hymn;slow
```

`status` is `liked` or `maybe` (blank means `maybe`). Separate tags with `;`. Songs that already exist gain the tags; nothing is overwritten.

## Importing your Ultimate Guitar tabs (personal use)

Ultimate Guitar has no public API, so this reads the pages your own browser sees. Use it for your own saved tabs.

1. Open your [My tabs](https://www.ultimate-guitar.com/user/mytabs) page, logged in. Set the filter to "All" and scroll to the end of the list.
2. Paste `script/ug/saved_tabs_snippet.js` into the browser console. It downloads `ug-saved-tabs.json` (links only, no tab contents).
3. On your own computer (Ultimate Guitar often blocks servers):
   ```sh
   bin/rails "ug:urls[ug-saved-tabs.json,urls.txt]"   # chord sheets only, one per song
   bin/rails "ug:fetch[urls.txt,bundle.json]"         # one page a second; safe to re-run
   ```
4. Upload `bundle.json` on Jambook's Import page.

Paid (official) tabs are never downloaded: the most-voted free chords version of the same song is used instead, and the song keeps a link to the official one. A tab Ultimate Guitar rates "advanced" comes in as *maybe*. Imports only fill gaps: a song that already has a sheet keeps it.

## License

MIT. See [LICENSE](LICENSE).
