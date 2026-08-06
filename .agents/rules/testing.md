# Testing Rules

Run the full test suite before committing behavior changes:

```bash
npm run test
npm run typecheck
```

Tests run against compiled output in `dist/`. The `test` script builds first (`npm run build && node --test dist/test/*.test.js`), so TS errors fail the test step before any test runs.

When fixing a bug, add a regression test that fails before the fix and passes after it. Put the test in `test/`, mirroring the source area it covers.

Test files live in `test/` with one focused file per source module or behavior area:

- `test/auth.test.ts` for SASL and service authentication.
- `test/bot.test.ts` for bot lifecycle, channels, and game orchestration.
- `test/config.test.ts` for configuration loading and validation.
- `test/core.test.ts` for shared core helpers.
- `test/cyl.test.ts` and `test/trivia.test.ts` for game logic.
- `test/database*.test.ts` for persistence and repositories.
- `test/irc-state.test.ts`, `test/outbound-queue.test.ts`, `test/reconnect-controller.test.ts` for IRC adapter behavior.
- `test/time.test.ts`, `test/transaction.test.ts`, `test/maintenance.test.ts` for supporting systems.

Tests use Node's built-in test runner (`node --test`). Prefer small unit tests with explicit in-memory mocks over real IRC servers, real databases, or real timers. Mock timing boundaries and external dependencies directly in the test file.

When adding a feature, add tests for the public behavior, not implementation trivia. Cover the happy path and the important failure or edge path.

Write assertions that prove what users or callers observe:

- Returned values and thrown errors.
- Outbound IRC messages and their ordering.
- State changes that are part of the public contract.

Avoid weak assertions such as `toBeDefined()` when a concrete value, message, or behavior can be checked.

Place future test policy and testing conventions in this file.
