import assert from "node:assert/strict";
import {
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import {
  openDatabase,
  REQUIRED_RUNTIME_TABLES,
  validateRuntimeSchema,
} from "../src/db/database.js";

const migration = readFileSync(resolve("migrations/001_initial.sql"), "utf8");

test("runtime schema validation accepts migration version 1", () => {
  const database = new DatabaseSync(":memory:");
  try {
    database.exec(migration);
    database.exec(
      "INSERT INTO schema_migrations(version,applied_at) VALUES(1,'test')",
    );
    validateRuntimeSchema(database);
  } finally {
    database.close();
  }
});

test("openDatabase rejects missing, directory and empty file paths", () => {
  withTemporaryDirectory((directory) => {
    const missing = join(directory, "missing.sqlite");
    assert.throws(() => openDatabase(missing), /not accessible/u);
    assert.equal(existsSync(missing), false);
    assert.throws(() => openDatabase(directory), /not a regular file/u);

    const empty = join(directory, "empty.sqlite");
    writeFileSync(empty, "");
    assert.throws(
      () => openDatabase(empty),
      /schema_migrations table is missing/u,
    );
  });
});

test("runtime schema validation rejects absent markers and runtime tables", () => {
  const noMarker = new DatabaseSync(":memory:");
  try {
    noMarker.exec("CREATE TABLE networks(id INTEGER)");
    assert.throws(
      () => validateRuntimeSchema(noMarker),
      /schema_migrations table is missing/u,
    );
  } finally {
    noMarker.close();
  }

  const missingTable = new DatabaseSync(":memory:");
  try {
    missingTable.exec(migration);
    missingTable.exec(
      "INSERT INTO schema_migrations(version,applied_at) VALUES(1,'test'); DROP TABLE dictionary",
    );
    assert.throws(
      () => validateRuntimeSchema(missingTable),
      /runtime table is missing: dictionary/u,
    );
  } finally {
    missingTable.close();
  }
});

test("runtime schema validation requires exactly integer version 1", () => {
  const cases: Array<[string, readonly (number | string)[], RegExp]> = [
    ["empty", [], /exactly one migration marker/u],
    ["version zero", [0], /version 0 is unsupported/u],
    ["future version", [2], /version 2 is unsupported/u],
    ["additional version", [1, 2], /exactly one migration marker/u],
    ["text version", ["1"], /version must be an integer/u],
  ];
  for (const [name, versions, pattern] of cases) {
    const database = structuralDatabase(versions);
    try {
      assert.throws(() => validateRuntimeSchema(database), pattern, name);
    } finally {
      database.close();
    }
  }
});

test("openDatabase validates before enabling runtime PRAGMAs", () => {
  withTemporaryDirectory((directory) => {
    const path = join(directory, "valid.sqlite");
    const created = new DatabaseSync(path);
    created.exec(migration);
    created.exec(
      "INSERT INTO schema_migrations(version,applied_at) VALUES(1,'test')",
    );
    created.close();

    const database = openDatabase(path);
    try {
      assert.equal(pragmaNumber(database, "foreign_keys"), 1);
      assert.equal(pragmaNumber(database, "busy_timeout"), 5_000);
      const journal = database.prepare("PRAGMA journal_mode").get() as {
        journal_mode: string;
      };
      assert.equal(journal.journal_mode, "wal");
    } finally {
      database.close();
    }
  });
});

function structuralDatabase(
  versions: readonly (number | string)[],
): DatabaseSync {
  const database = new DatabaseSync(":memory:");
  database.exec("CREATE TABLE schema_migrations(version)");
  for (const table of REQUIRED_RUNTIME_TABLES)
    database.exec(`CREATE TABLE ${table}(id INTEGER)`);
  const insertText = database.prepare(
    "INSERT INTO schema_migrations(version) VALUES(?)",
  );
  for (const version of versions) {
    if (typeof version === "number")
      database.exec(
        `INSERT INTO schema_migrations(version) VALUES(${version})`,
      );
    else insertText.run(version);
  }
  return database;
}

function pragmaNumber(database: DatabaseSync, name: string): number {
  const row = database.prepare(`PRAGMA ${name}`).get() as Record<
    string,
    number
  >;
  return Object.values(row)[0]!;
}

function withTemporaryDirectory(action: (directory: string) => void): void {
  const directory = mkdtempSync(join(tmpdir(), "wit-database-"));
  try {
    action(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}
