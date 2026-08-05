import { DatabaseSync } from "node:sqlite";
import { sourceDatabase, targetDatabase } from "./paths.js";

const database = new DatabaseSync(targetDatabase, { readOnly: true });
const source = new DatabaseSync(sourceDatabase, { readOnly: true });
const mappings = {
  authors: "Authors",
  questions: "Questions_Table",
  subjects: "Subjects",
  question_subsets: "QuestionSubsets",
  question_subset_members: "QSubsetMembers",
  dictionary: "Dictionary",
  networks: "IRCNetworks",
  players: "Players",
  channels: "Channels",
  leagues: "Leagues",
  tournaments: "Tournaments",
  games: "Games",
  scores: "ScoresT",
  score_history: "ScoresT_History",
  game_types: "WitGames",
} as const;
const forbiddenTables = [
  "admins",
  "bans",
  "ipbans",
  "mywits",
  "wsnicks",
  "witops",
  "bank_users",
  "teams",
  "sms_contributors",
  "question_votes",
  "cylscores",
];
const requiredIndexes = [
  "idx_questions_selection",
  "idx_players_nick",
  "idx_tournaments_active",
  "idx_games_tournament",
  "idx_scores_ranking",
  "idx_score_history_ranking",
];

try {
  assert(
    (database.prepare("PRAGMA foreign_keys").get() as { foreign_keys: number })
      .foreign_keys === 1,
    "foreign_keys is disabled",
  );
  assert(
    database.prepare("PRAGMA foreign_key_check").all().length === 0,
    "foreign key violations found",
  );
  const counts: Record<string, number> = {};
  for (const [target, origin] of Object.entries(mappings)) {
    const targetCount = count(database, target);
    const sourceCount =
      origin === "Dictionary"
        ? Number(
            (
              source
                .prepare(
                  "SELECT count(*) count FROM Dictionary WHERE status IN ('OK','NF')",
                )
                .get() as { count: number }
            ).count,
          )
        : count(source, origin);
    assert(
      targetCount === sourceCount,
      `${target}: expected ${sourceCount}, got ${targetCount}`,
    );
    const sourceId = idColumn(origin);
    const targetId = "id";
    const targetProjection = projection(database, target, targetId);
    const sourceProjection = projection(
      source,
      origin,
      sourceId,
      origin === "Dictionary" ? "status IN ('OK','NF')" : undefined,
    );
    assert(
      targetProjection === sourceProjection,
      `${target}: ID projection differs`,
    );
    counts[target] = targetCount;
  }
  const tables = new Set(
    (
      database
        .prepare(
          "SELECT lower(name) name FROM sqlite_master WHERE type='table'",
        )
        .all() as Array<{ name: string }>
    ).map((row) => row.name),
  );
  for (const table of forbiddenTables)
    assert(!tables.has(table), `forbidden table present: ${table}`);
  const columns = [
    ...columnsOf(database, "players"),
    ...columnsOf(database, "channels"),
  ];
  for (const forbidden of [
    "externalid",
    "password",
    "adminlevel",
    "ip",
    "secretcode",
  ])
    assert(
      !columns.includes(forbidden),
      `forbidden column present: ${forbidden}`,
    );
  const indexes = new Set(
    (
      database
        .prepare("SELECT name FROM sqlite_master WHERE type='index'")
        .all() as Array<{ name: string }>
    ).map((row) => row.name),
  );
  for (const index of requiredIndexes)
    assert(indexes.has(index), `missing index: ${index}`);
  const malformed = Number(
    (
      database
        .prepare(
          "SELECT count(*) count FROM questions WHERE question IS NULL OR answer IS NULL OR question='' OR answer=''",
        )
        .get() as { count: number }
    ).count,
  );
  assert(malformed === 0, "empty imported questions found");
  const audit = Object.fromEntries(
    (
      database.prepare("SELECT key,value FROM import_audit").all() as Array<{
        key: string;
        value: number;
      }>
    ).map((row) => [row.key, row.value]),
  );
  console.log(JSON.stringify({ verified: true, counts, audit }, null, 2));
} finally {
  database.close();
  source.close();
}

function count(database: DatabaseSync, table: string): number {
  return Number(
    (
      database.prepare(`SELECT count(*) count FROM ${table}`).get() as {
        count: number;
      }
    ).count,
  );
}
function projection(
  database: DatabaseSync,
  table: string,
  id: string,
  where?: string,
): string {
  const row = database
    .prepare(
      `SELECT count(*) count,COALESCE(min(${id}),0) min,COALESCE(max(${id}),0) max,COALESCE(sum(${id}),0) sum FROM ${table}${where === undefined ? "" : ` WHERE ${where}`}`,
    )
    .get() as Record<string, number | bigint>;
  return `${row.count}:${row.min}:${row.max}:${row.sum}`;
}
function idColumn(table: string): string {
  const special: Record<string, string> = {
    Authors: "IdAuthor",
    Questions_Table: "IDQuestion",
    Subjects: "IdSubject",
    QuestionSubsets: "IDQuestionSubset",
    QSubsetMembers: "IDQSubsetMembers",
    Dictionary: "IDWord",
    IRCNetworks: "IDNetwork",
    Players: "IdPlayer",
    Channels: "IdChannel",
    Leagues: "IDLeague",
    Tournaments: "IdTournament",
    Games: "IdGame",
    ScoresT: "IDScore",
    ScoresT_History: "COALESCE(IDScore,rowid)",
    WitGames: "IDWitGame",
  };
  return special[table] ?? "rowid";
}
function columnsOf(database: DatabaseSync, table: string): string[] {
  return (
    database.prepare(`PRAGMA table_info(${table})`).all() as Array<{
      name: string;
    }>
  ).map((row) => row.name.toLowerCase());
}
function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
