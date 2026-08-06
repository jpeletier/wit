import { statSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";

export const SUPPORTED_SCHEMA_VERSION = 1;
export const REQUIRED_RUNTIME_TABLES = Object.freeze([
  "networks",
  "authors",
  "game_types",
  "subjects",
  "channels",
  "question_subsets",
  "question_subset_members",
  "questions",
  "dictionary",
  "players",
  "leagues",
  "tournaments",
  "games",
  "scores",
] as const);

export function openDatabase(path: string): DatabaseSync {
  let file;
  try {
    file = statSync(path);
  } catch (cause) {
    throw new Error(`Database file is not accessible: ${path}`, { cause });
  }
  if (!file.isFile()) {
    throw new Error(`Database path is not a regular file: ${path}`);
  }

  let database: DatabaseSync;
  try {
    database = new DatabaseSync(path, { enableForeignKeyConstraints: false });
  } catch (cause) {
    throw new Error(`Unable to open database file: ${path}`, { cause });
  }
  try {
    validateRuntimeSchema(database);
    database.exec(
      "PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA journal_mode = WAL;"
    );
    return database;
  } catch (primaryError) {
    try {
      database.close();
    } catch (closeError) {
      throw new AggregateError(
        [primaryError, closeError],
        "Database startup failed and close failed",
        { cause: primaryError }
      );
    }
    throw primaryError;
  }
}

export function validateRuntimeSchema(database: DatabaseSync): void {
  let tables: Array<{ name: string }>;
  try {
    tables = database
      .prepare("SELECT name FROM sqlite_schema WHERE type='table'")
      .all() as unknown as Array<{ name: string }>;
  } catch (cause) {
    throw new Error("Database schema could not be inspected", { cause });
  }
  const names = new Set(tables.map((table) => table.name));
  if (!names.has("schema_migrations")) {
    throw new Error("Database schema_migrations table is missing");
  }

  let migrations: Array<{ version: unknown; versionType: unknown }>;
  try {
    migrations = database
      .prepare("SELECT version,typeof(version) versionType FROM schema_migrations")
      .all() as unknown as Array<{ version: unknown; versionType: unknown }>;
  } catch (cause) {
    throw new Error("Database migration marker is malformed", { cause });
  }
  if (migrations.length !== 1) {
    throw new Error("Database must contain exactly one migration marker");
  }
  const migration = migrations[0]!;
  if (
    migration.versionType !== "integer" ||
    typeof migration.version !== "number" ||
    !Number.isSafeInteger(migration.version)
  ) {
    throw new Error("Database migration version must be an integer");
  }
  if (migration.version !== SUPPORTED_SCHEMA_VERSION) {
    throw new Error(`Database schema version ${String(migration.version)} is unsupported`);
  }

  const missing = REQUIRED_RUNTIME_TABLES.find((table) => !names.has(table));
  if (missing !== undefined) {
    throw new Error(`Database runtime table is missing: ${missing}`);
  }
}

export function transaction<T>(database: DatabaseSync, operation: () => T): T {
  database.exec("BEGIN IMMEDIATE");
  try {
    const result = operation();
    database.exec("COMMIT");
    return result;
  } catch (primaryError) {
    try {
      database.exec("ROLLBACK");
    } catch (rollbackError) {
      throw new AggregateError(
        [primaryError, rollbackError],
        "Transaction failed and rollback failed",
        { cause: primaryError }
      );
    }
    throw primaryError;
  }
}
