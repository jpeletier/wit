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
npm run db:create
npm run db:import
npm run db:verify
cp config.example.json config.json
npm start
```

`config.json`, `.env`, `db/`, logs, backups, binaries, and build output are ignored. Configure one object per bot; every object gets an independent `irc-client-ts` client and reconnect lifecycle. Never commit real passwords.

Environment overrides:

- `WIT_CONFIG`: configuration path, default `config.json`
- `WIT_DATABASE`: runtime/target database path, default from config or `db/wit.sqlite`
- `WIT_SOURCE_DATABASE`: staging extraction, default `db/trivial.sqlite`
- `WIT_IMPORT_REPORT`: ignored audit report, default `db/import-audit.json`

## Commands

Private commands are `HELP`, `DATE`, `TRIVIAL #canal [5-30]`, `CYL #canal [1-30]`, and either game command with `STOP`. Stopping requires current channel operator status from IRC NAMES/PREFIX state. Channel expressions support subsets of `+ - * / ^`, parentheses, decimals, and `NdM` dice. Prefix with `?` to force display. Dice are rejected in Cifras.

Welcome/help notices are sent on every join by default. Set `welcomeOnJoin` to `false` to disable them. Current Trivia questions are intentionally not replayed to late joiners.

## Database Migration

`migrations/001_initial.sql` defines a strict constrained schema with foreign keys, uniqueness, checks, and ranking/selection indexes. `db:import` attaches the staging database read-only by convention and imports only game-domain projections: authors, questions, subjects/subsets, dictionary, networks, players, channels, leagues, tournaments, game history, active scores, and score history. It excludes credentials, admins, IP/bans, operators, external identity, banking/economy, moderation/voting, teams, SMS, and obsolete CYL state.

IDs and historical rows are preserved. New leagues and tournaments are monthly. Player/dictionary lookup uses NFC plus Spanish locale-aware lowercase while preserving accents; IRC identity uses negotiated IRC casemapping separately. The import proposes only strict reversible CP1252-as-UTF-8 repairs that reduce known markers, leaves ambiguous/control data unchanged, records counts in `import_audit`, and writes an ignored report. `db:verify` checks row counts and ID projections against staging, FKs, indexes, forbidden schema, and correction audit data.

Persistence operations use `BEGIN IMMEDIATE` transactions. Failures terminate the affected game visibly rather than continuing with unrecorded state.

## Compatibility Notes

- Trivia answer words are case-insensitive, accent-sensitive, unordered, allow extras, ignore repeated-space empties, and reject answers over ten words.
- Numeric Trivia uses exact safe-expression equality. Hint stages preserve the legacy ASCII/digit/ñ mask behavior. Awarded and displayed scores use VB banker rounding.
- CYL trims words, accepts dictionary statuses `OK` and `NF`, uses accent-insensitive supplied-letter inventory and accent-sensitive dictionary keys. K is worth 8. Definitions append ellipses only when actually truncated.
- Cifras permits number subsets, fractions and noninteger intermediates with exact inventory enforcement. The closest first submission wins ties, including zero-point distant results.
- A bot disconnect ends its games. Cross-bot takeover, autoplay, GUI/tray, DCC, WitSummon, banking/login/Porra, legacy service bots, moderation/admin systems, and obsolete promotion links are deliberately removed.

## Quality Checks

```sh
npm run check
npm run db:verify
```

Tests cover parser safety, dice restrictions, VB rounding, mIRC controls, matching/hints/timers/scoring, CYL generation/inventory/dictionary/scoring, mojibake fixtures, transactional persistence, commands, busy-channel behavior, operator authorization, joins, nick changes, and disconnect finalization.
