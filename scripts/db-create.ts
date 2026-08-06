import { mkdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { targetDatabase } from "./paths.js";

mkdirSync(dirname(targetDatabase), { recursive: true });
const database = new DatabaseSync(targetDatabase);
try {
  database.exec("PRAGMA foreign_keys=ON");
  const present = database
    .prepare(
      "SELECT count(*) count FROM sqlite_master WHERE type='table' AND name='schema_migrations'"
    )
    .get() as { count: number };
  if (present.count !== 0) {
    throw new Error(`Target already has a schema: ${targetDatabase}`);
  }
  database.exec(readFileSync(resolve("migrations/001_initial.sql"), "utf8"));
  database
    .prepare("INSERT INTO schema_migrations(version,applied_at) VALUES(1,?)")
    .run(new Date().toISOString());
  console.log(`Created ${targetDatabase}`);
} finally {
  database.close();
}
