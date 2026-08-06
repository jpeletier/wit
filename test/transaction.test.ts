import assert from "node:assert/strict";
import type { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { transaction } from "../src/db/database.js";

test("transaction returns successful operation result and commits once", () => {
  const calls: string[] = [];
  const result = { committed: true };
  const actual = transaction(
    database((sql) => calls.push(sql)),
    () => result
  );
  assert.equal(actual, result);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE", "COMMIT"]);
});

test("BEGIN failure propagates directly without rollback", () => {
  const calls: string[] = [];
  const failure = new Error("begin failed");
  const thrown = capture(() =>
    transaction(
      database((sql) => {
        calls.push(sql);
        throw failure;
      }),
      () => assert.fail("operation must not run")
    )
  );
  assert.equal(thrown, failure);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE"]);
});

test("operation failure is rethrown by identity after rollback", () => {
  const calls: string[] = [];
  const failure = {
    toString(): string {
      throw new Error("hostile conversion");
    },
  };
  const thrown = capture(() =>
    transaction(
      database((sql) => calls.push(sql)),
      () => {
        // eslint-disable-next-line @typescript-eslint/only-throw-error -- verify hostile database callbacks
        throw failure;
      }
    )
  );
  assert.equal(thrown, failure);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE", "ROLLBACK"]);
});

test("COMMIT failure is rethrown by identity after rollback", () => {
  const calls: string[] = [];
  const failure = new Error("commit failed");
  const thrown = capture(() =>
    transaction(
      database((sql) => {
        calls.push(sql);
        if (sql === "COMMIT") {
          throw failure;
        }
      }),
      () => 42
    )
  );
  assert.equal(thrown, failure);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE", "COMMIT", "ROLLBACK"]);
});

test("rollback failure aggregates hostile operation failure first", () => {
  const calls: string[] = [];
  const primary = Object.create(null) as object;
  const rollback = new Error("rollback failed");
  const thrown = capture(() =>
    transaction(
      database((sql) => {
        calls.push(sql);
        if (sql === "ROLLBACK") {
          throw rollback;
        }
      }),
      () => {
        // eslint-disable-next-line @typescript-eslint/only-throw-error -- verify hostile database callbacks
        throw primary;
      }
    )
  );
  assert.ok(thrown instanceof AggregateError);
  assert.equal(thrown.message, "Transaction failed and rollback failed");
  assert.equal(thrown.cause, primary);
  assert.deepEqual(thrown.errors, [primary, rollback]);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE", "ROLLBACK"]);
});

test("rollback failure aggregates COMMIT failure first", () => {
  const calls: string[] = [];
  const primary = new Error("commit failed");
  const rollback = new Error("rollback failed");
  const thrown = capture(() =>
    transaction(
      database((sql) => {
        calls.push(sql);
        if (sql === "COMMIT") {
          throw primary;
        }
        if (sql === "ROLLBACK") {
          throw rollback;
        }
      }),
      () => "result"
    )
  );
  assert.ok(thrown instanceof AggregateError);
  assert.equal(thrown.cause, primary);
  assert.deepEqual(thrown.errors, [primary, rollback]);
  assert.deepEqual(calls, ["BEGIN IMMEDIATE", "COMMIT", "ROLLBACK"]);
});

function database(exec: (sql: string) => void): DatabaseSync {
  return { exec } as unknown as DatabaseSync;
}

function capture(action: () => unknown): unknown {
  try {
    action();
  } catch (error) {
    return error;
  }
  throw new Error("Expected action to throw");
}
