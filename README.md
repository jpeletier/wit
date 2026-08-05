# Wit IRC Games

Wit is a headless Node.js 24 IRC game bot for Spanish-language Trivial and Cifras y Letras. This tree replaces the historical VB6/COM/ADO application while preserving the public game behavior and mIRC formatting that remain useful.

## Requirements

- Node.js 24 or newer (the database uses built-in `node:sqlite`)
- The audited staging extraction at `db/trivial.sqlite` for a historical import
- An IRC server with TLS support

## Setup

```sh
npm install
npm run build
npm run db:audit
npm run db:create
npm run db:import
npm run db:verify
cp config.example.json config.json
npm start
```

`config.json`, `.env`, `db/`, logs, backups, binaries, and build output are ignored. Configure one object per bot; every object gets an independent IRC lifecycle and outbound PRIVMSG/NOTICE queue. Connections retry indefinitely with adapter-owned exponential backoff from 5 to 120 seconds, reset after registration. `outboundDelayMs` defaults to the legacy-compatible 2000 ms and must be positive. Never commit real passwords.

Environment overrides:

- `WIT_CONFIG`: configuration path, default `config.json`
- `WIT_DATABASE`: runtime/target database path, default from config or `db/wit.sqlite`
- `WIT_SOURCE_DATABASE`: staging extraction, default `db/trivial.sqlite`
- `WIT_IMPORT_REPORT`: ignored audit report, default `db/import-audit.json`

## Authentication

Authentication is optional and explicit in ignored `config.json`; no service or NickServ target is inferred. `serverPassword` is sent only as the IRC server `PASS`. `accountAuth` supports SASL PLAIN with `method: "sasl"`, `username`, and `password`.

Post-registration service authentication is separate under `serviceAuth`. It requires single-token `target` and `password` values, accepts an optional single-token `command` (default `IDENTIFY`) and optional `account`, and supports explicit targets such as `nick@server`. It is paced as the first outbound item after each successful registration, before configured channels are joined.

## Commands

Private commands are `HELP`, `DATE`, `TRIVIAL #canal [5-30]`, `CYL #canal [1-30]`, and either game command with `STOP`. The bot must already be joined to the requested channel. Stopping affects only the named game type and requires current channel operator status from IRC NAMES/PREFIX state. Unrecognized game counts default to 20; Trivia counts below five clamp to five, while nonpositive CYL counts are rejected. Each bot permits at most two concurrent Trivia games and blocks CYL while both slots are occupied.

Channel expressions support subsets of `+ - * / ^`, parentheses, decimals, and `NdM` dice. Powers are left-associative for legacy compatibility. Prefix with `?` to force display. Numeric Trivia retains deterministic safe dice expressions; dice are rejected only in Cifras. Legacy `count#expression` repetition syntax is intentionally omitted because it returns a list rather than a numeric expression.

Welcome/help notices are sent on every join by default. Set `welcomeOnJoin` to `false` to disable them. Current Trivia questions are intentionally not replayed to late joiners.

## Database Migration

`migrations/001_initial.sql` defines a strict constrained schema with foreign keys, uniqueness, checks, and ranking/selection indexes. `db:import` attaches the staging database read-only by convention and imports only game-domain projections: authors, questions, subjects/subsets, dictionary, networks, players, channels, leagues, tournaments, game history, active scores, and score history. It excludes credentials, admins, IP/bans, operators, external identity, banking/economy, moderation/voting, teams, SMS, and obsolete CYL state.

IDs and historical rows are preserved. League IDs use the legacy March 2001 epoch (`305` for August 2026). Trivia reuses the current league tournament and its subset; a new tournament inherits the channel's default Trivia subset and becomes the new default. CYL always uses subset 34. Player/dictionary lookup uses NFC plus Spanish locale-aware lowercase while preserving accents; IRC identity uses negotiated IRC casemapping separately.

`npm run db:audit` writes an ignored audit-only report before applying changes. The importer proposes only strict reversible CP1252-as-UTF-8 repairs that reduce known markers, leaves ambiguous/control data unchanged, records table/ID/column/original/corrected details locally, and stores counts in `import_audit`. `db:verify` streams every projected field from all imported rows against its transformed source value, then checks ranking equivalence, FKs, indexes, correction counts, and forbidden schema/data.

Persistence operations use `BEGIN IMMEDIATE` transactions. Failures terminate the affected game visibly rather than continuing with unrecorded state.

## Compatibility Notes

- Trivia answer words are case-insensitive, accent-sensitive, unordered, allow extras, ignore repeated-space empties, and reject answers over ten words.
- Questions are selected at round start through shared weighted-subject, IFS-position, per-subject FIFO buffers. Buffered rows increment `Repeats` and receive a new `rndnum`; the obsolete `score` field is not used for selection.
- Numeric Trivia uses exact safe-expression equality and two independent random draws for numeric hints. Hint stages preserve the legacy ASCII/digit/ñ mask behavior. Awarded and displayed scores use VB banker rounding.
- CYL trims words, accepts dictionary statuses `OK` and `NF`, folds accented vowels and Ü to their base vowel for supplied-letter inventory, and keeps Ñ distinct from N. Dictionary keys remain accent-sensitive. K and Ñ are worth 8. Definitions sanitize unsafe line controls, budget 100 Unicode code points from the source, then expand legacy separators and append ellipses only when truncated.
- Cifras permits number subsets, fractions and noninteger intermediates with exact supplied-literal inventory enforcement. Exact means `distance === 0`; the closest first submission wins ties, including zero-point distant results.
- Per-game standings retain insertion order for ties, print after every round, and completion output includes persistent tournament rank and total for up to ten players.
- A bot disconnect ends its games. Cross-bot takeover, autoplay, GUI/tray, DCC, WitSummon, banking/login/Porra, legacy service bots, moderation/admin systems, and obsolete promotion links are deliberately removed.

## Quality Checks

```sh
npm run check
npm run db:verify
```

Tests include raw full-game transcript hashes plus parser limits, weighted selector/FIFO mutations, imported tournament continuity, ranking/scoring transactions, persistence failures, exact timer stages, legacy random boundaries, joined-channel/operator state, self-kicks, nick changes, and disconnect finalization.
