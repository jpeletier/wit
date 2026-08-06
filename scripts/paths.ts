import { resolve } from "node:path";

export const sourceDatabase = resolve(process.env.WIT_SOURCE_DATABASE ?? "db/trivial.sqlite");
export const targetDatabase = resolve(process.env.WIT_DATABASE ?? "db/wit.sqlite");
export const auditReport = resolve(process.env.WIT_IMPORT_REPORT ?? "db/import-audit.json");
