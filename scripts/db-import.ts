import { writeFileSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { lookupKey, repairMojibake } from "../src/core/text.js";
import { auditReport, sourceDatabase, targetDatabase } from "./paths.js";

const database = new DatabaseSync(targetDatabase);
let proposed = 0;
let applied = 0;
database.function("wit_key", { deterministic: true }, (value) =>
  lookupKey(String(value)),
);
database.function("wit_repaired_key", { deterministic: true }, (value) =>
  lookupKey(repairMojibake(String(value)).value),
);
database.function("wit_text", { deterministic: true }, (value) => {
  if (value === null) return null;
  const result = repairMojibake(String(value));
  if (result.proposed) proposed++;
  if (result.applied) applied++;
  return result.value;
});

const imports = [
  [
    "networks",
    `INSERT INTO networks SELECT IDNetwork,wit_text(COALESCE(NetworkName,'')),wit_text(COALESCE(Description,'')),AllowJOIN_SC,COALESCE(JoinFree,1) FROM source.IRCNetworks`,
  ],
  [
    "authors",
    `INSERT INTO authors SELECT IdAuthor,wit_text(COALESCE(NULLIF(trim(Author),''),'(sin autor)')) FROM source.Authors`,
  ],
  [
    "game_types",
    `INSERT INTO game_types SELECT IDWitGame,wit_text(COALESCE(GameName,'')) FROM source.WitGames`,
  ],
  [
    "subjects",
    `INSERT INTO subjects SELECT IdSubject,wit_text(Subject),COALESCE(cnt,0),IDWitGame FROM source.Subjects`,
  ],
  [
    "channels",
    `INSERT INTO channels SELECT IdChannel,IDNetwork,wit_text(Name),wit_repaired_key(Name),LastUsed FROM source.Channels`,
  ],
  [
    "question_subsets",
    `INSERT INTO question_subsets SELECT IDQuestionSubset,wit_text(COALESCE("DESC",'')),COALESCE(Multiplier,1),IDChannel FROM source.QuestionSubsets`,
  ],
  [
    "question_subset_members",
    `INSERT INTO question_subset_members SELECT IDQSubsetMembers,IDQuestionSubset,IDSubject,MAX(COALESCE(weight,1),1) FROM source.QSubsetMembers`,
  ],
  [
    "questions",
    `INSERT INTO questions SELECT IDQuestion,wit_text(Question),wit_text(Answer),Source,MAX(COALESCE(Repeats,0),0),IDSubject,IDAuthor,COALESCE(IFS,0),COALESCE(rndnum,0),COALESCE(score,0) FROM source.Questions_Table`,
  ],
  [
    "dictionary",
    `INSERT INTO dictionary SELECT IDWord,wit_text(word),wit_repaired_key(word),wit_text(meaning),status FROM source.Dictionary WHERE status IN ('OK','NF')`,
  ],
  [
    "players",
    `INSERT INTO players SELECT IdPlayer,IDNetwork,wit_text(NickName),wit_repaired_key(NickName),LastUsed FROM source.Players`,
  ],
  [
    "leagues",
    `INSERT INTO leagues SELECT IDLeague,wit_text(COALESCE("DESC",'')),DateInit,DateEnd FROM source.Leagues`,
  ],
  [
    "tournaments",
    `INSERT INTO tournaments SELECT IdTournament,wit_text(COALESCE("Desc",'')),DateInit,DateEnd,IdChannel,IDLeague,IDQuestionSubset,IDWitGame FROM source.Tournaments`,
  ],
  [
    "games",
    `INSERT INTO games SELECT IdGame,IdTournament,MAX(COALESCE(NumQuestions,0),0),COALESCE(DateInit,''),DateEnd,wit_text(COALESCE("Desc",'')) FROM source.Games`,
  ],
  [
    "scores",
    `INSERT INTO scores SELECT IDScore,IDPlayer,IDTournament,IDSubject,MAX(QuestionsAnswered,0),Score FROM source.ScoresT`,
  ],
  [
    "score_history",
    `INSERT INTO score_history SELECT COALESCE(IDScore,rowid),IDPlayer,IDTournament,IDSubject,MAX(QuestionsAnswered,0),Score FROM source.ScoresT_History`,
  ],
] as const;

try {
  database.exec(
    "PRAGMA foreign_keys=ON; PRAGMA busy_timeout=10000; ATTACH DATABASE " +
      quote(sourceDatabase) +
      " AS source; BEGIN IMMEDIATE",
  );
  const existing = database
    .prepare("SELECT count(*) count FROM authors")
    .get() as { count: number };
  if (existing.count !== 0)
    throw new Error("Target database has already been imported");
  const counts: Record<string, number> = {};
  for (const [table, sql] of imports) {
    database.exec(sql);
    counts[table] = Number(
      (
        database.prepare(`SELECT count(*) count FROM ${table}`).get() as {
          count: number;
        }
      ).count,
    );
  }
  database
    .prepare(
      "INSERT INTO import_audit(key,value) VALUES('mojibake_proposed',?),('mojibake_applied',?)",
    )
    .run(proposed, applied);
  database.exec("COMMIT; PRAGMA optimize");
  const report = {
    source: "trivial.sqlite",
    target: "wit.sqlite",
    counts,
    mojibake: { proposed, applied },
    generatedAt: new Date().toISOString(),
  };
  writeFileSync(auditReport, `${JSON.stringify(report, null, 2)}\n`, {
    mode: 0o600,
  });
  console.log(JSON.stringify(report, null, 2));
} catch (error) {
  try {
    database.exec("ROLLBACK");
  } catch {
    /* transaction may not have started */
  }
  throw error;
} finally {
  database.close();
}

function quote(path: string): string {
  return `'${path.replaceAll("'", "''")}'`;
}
