import { DatabaseSync } from "node:sqlite";

export function openDatabase(path: string): DatabaseSync {
  const database = new DatabaseSync(path);
  database.exec(
    "PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA journal_mode = WAL;",
  );
  return database;
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
        { cause: primaryError },
      );
    }
    throw primaryError;
  }
}
