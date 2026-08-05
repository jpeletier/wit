import assert from "node:assert/strict";
import test from "node:test";
import { runQuestionMaintenance } from "../src/app/maintenance.js";

test("question maintenance succeeds without logging", () => {
  let ages = 0;
  const logs: string[] = [];
  runQuestionMaintenance(
    () => ages++,
    (message) => logs.push(message),
  );
  assert.equal(ages, 1);
  assert.deepEqual(logs, []);
});

test("question maintenance logs a concise Error message", () => {
  const logs: string[] = [];
  runQuestionMaintenance(
    () => {
      throw new Error("database busy");
    },
    (message) => logs.push(message),
  );
  assert.deepEqual(logs, ["Question maintenance failed: database busy"]);
});

test("question maintenance collapses multiline and control error details", () => {
  const logs: string[] = [];
  runQuestionMaintenance(
    () => {
      throw new Error("database\r\n\0\nbusy");
    },
    (message) => logs.push(message),
  );
  assert.deepEqual(logs, ["Question maintenance failed: database busy"]);
  assert.doesNotMatch(logs[0]!, /[\r\n\0]/u);
});

test("question maintenance normalizes non-Error failures", () => {
  const logs: string[] = [];
  runQuestionMaintenance(
    () => {
      // eslint-disable-next-line @typescript-eslint/only-throw-error -- exercise hostile callback behavior
      throw 503;
    },
    (message) => logs.push(message),
  );
  assert.deepEqual(logs, ["Question maintenance failed: 503"]);
});

test("question maintenance contains hostile non-Error conversion", () => {
  const logs: string[] = [];
  const hostile = {
    toString(): string {
      throw new Error("conversion failed");
    },
  };
  runQuestionMaintenance(
    () => {
      // eslint-disable-next-line @typescript-eslint/only-throw-error -- exercise hostile callback behavior
      throw hostile;
    },
    (message) => logs.push(message),
  );
  assert.deepEqual(logs, ["Question maintenance failed: unknown failure"]);
});

test("question maintenance can succeed on a later invocation", () => {
  let attempts = 0;
  const logs: string[] = [];
  const age = (): void => {
    attempts++;
    if (attempts === 1) throw new Error("temporary failure");
  };
  runQuestionMaintenance(age, (message) => logs.push(message));
  runQuestionMaintenance(age, (message) => logs.push(message));
  assert.equal(attempts, 2);
  assert.deepEqual(logs, ["Question maintenance failed: temporary failure"]);
});
