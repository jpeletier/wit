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
mkdir -p data
cp config.example.yaml data/config.yaml
npm start
```

`data/config.yaml` and `data/wit.db` are the ignored runtime configuration and database files. The staging database remains under `db/`. Configure one object per bot; every object gets an independent IRC lifecycle and outbound PRIVMSG/NOTICE queue. Connections retry indefinitely with adapter-owned exponential backoff from 5 to 120 seconds, reset after registration. `outboundDelayMs` defaults to the legacy-compatible 2000 ms and accepts 1 through 300000. `heartbeat.pingIntervalSeconds` defaults to 60 and accepts 1 through 3600; `heartbeat.maxMissedPongs` defaults to 2 and accepts 1 through 100. Ports accept 1 through 65535; network IDs must be positive safe integers; channel names use an IRC prefix (`#`, `&`, `+`, or `!`), are unique per bot, and are limited to 50 UTF-8 bytes. Multiple bots may share a network in different channels, and channel names may repeat on different networks; the same network/channel pair cannot be assigned twice. Unknown configuration fields are rejected. Never commit real passwords.

Wit accepts IRC invitations. Per bot, `channelLifecycle` defaults to `messageIdleMinutes: 360`, `gameIdleMinutes: 2880`, `maxChannels: 15`, and `inviteEvictionIdleMinutes: 60`. A channel is left after six hours without a user message, or after 48 hours of user activity without a game start. Active games are never evicted. At the channel limit, an invitation evicts the channel with the oldest user message only when it has been idle for at least the eviction threshold; otherwise Wit politely refuses. Pending joins count toward the limit.

Environment overrides:

- `WIT_CONFIG`: YAML configuration path, default `data/config.yaml`
- `WIT_DATABASE`: runtime/target database path, default from config or `data/wit.db`
- `WIT_SOURCE_DATABASE`: staging extraction, default `db/trivial.sqlite`
- `WIT_IMPORT_REPORT`: ignored audit report, default `data/import-audit.json`
- `WIT_LOG_LEVEL`: Pino log level, default `info`; use `debug` for IRC and channel diagnostics

Wit writes structured JSON logs to stderr, leaving stdout unused. Every record has a `module` tag: `service`, `irc.connection`, `bot`, or `maintenance.questions`. Connection, channel, game, shutdown, and failure events are logged at `info` or above; individual IRC messages, game ticks, and successful outbound sends are not logged. Invite logs include both `invitedBy` and the requested `channel`; rejected invitations include a reason at `debug` or `info` when the channel limit prevents joining. Do not log raw IRC payloads or configuration because they can contain credentials.

Startup requires the configured database path to already be a regular SQLite file. Before enabling runtime write PRAGMAs, the bot checks migration version 1 and the required runtime tables; it exits on missing, empty, malformed, or newer schemas without creating a replacement database. This is a fast structural check, not a full-table integrity scan.

## Authentication

Authentication is optional and explicit in ignored `data/config.yaml`; no service or NickServ target is inferred. `serverPassword` is sent only as the IRC server `PASS`. `accountAuth` supports SASL PLAIN with the fields `method` (exactly `sasl`), `username`, and `password`. Authentication is intentionally omitted from `config.example.yaml`: add only the required field names to ignored `data/config.yaml`, with real credentials supplied locally rather than password placeholders.

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

New runtime timestamps use legacy Madrid wall time independent of the deployment host timezone. They are stored without an offset as `YYYY-MM-DDTHH:mm:ss.SSS` in `Europe/Madrid`; repeated local times during the autumn DST transition are intentionally ambiguous for compatibility with imported SQL datetime values. Historical rows and one-off import audit timestamps are not rewritten.

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
