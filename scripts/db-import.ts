import { writeFileSync } from "node:fs";
import { basename } from "node:path";
import { DatabaseSync } from "node:sqlite";
import { lookupKey, repairMojibake } from "../src/core/text.js";
import { auditReport, sourceDatabase, targetDatabase } from "./paths.js";

const auditOnly = process.argv.includes("--audit-only");
const sourceAudit = new DatabaseSync(sourceDatabase, { readOnly: true });
const corrections = collectCorrections(sourceAudit);
sourceAudit.close();
const proposed = corrections.length;
const applied = auditOnly ? 0 : corrections.length;
if (auditOnly) {
  writeFileSync(
    auditReport,
    `${JSON.stringify({ source: basename(sourceDatabase), mode: "audit-only", mojibake: { proposed, applied }, corrections }, null, 2)}\n`,
    { mode: 0o600 }
  );
  console.log(JSON.stringify({ auditOnly: true, proposed }));
  process.exit(0);
}

const database = new DatabaseSync(targetDatabase);
database.function("wit_repaired_key", { deterministic: true }, (value) =>
  lookupKey(repairMojibake(String(value)).value)
);
database.function("wit_text", { deterministic: true }, (value) => {
  if (value === null) {
    return null;
  }
  return repairMojibake(String(value)).value;
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
    `INSERT INTO channels SELECT IdChannel,IDNetwork,wit_text(Name),wit_repaired_key(Name),LastUsed,NULL FROM source.Channels`,
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
    `INSERT INTO questions SELECT IDQuestion,wit_text(Question),wit_text(Answer),Source,Repeats,IDSubject,IDAuthor,IFS,rndnum,score FROM source.Questions_Table`,
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
      " AS source; BEGIN IMMEDIATE"
  );
  const existing = database.prepare("SELECT count(*) count FROM authors").get() as {
    count: number;
  };
  if (existing.count !== 0) {
    throw new Error("Target database has already been imported");
  }
  const counts: Record<string, number> = {};
  for (const [table, sql] of imports) {
    database.exec(sql);
    counts[table] = Number(
      (
        database.prepare(`SELECT count(*) count FROM ${table}`).get() as {
          count: number;
        }
      ).count
    );
  }
  database.exec(
    `UPDATE channels SET default_tournament_id=(SELECT IdDefaultTournament FROM source.Channels WHERE IdChannel=channels.id)`
  );
  database
    .prepare(
      "INSERT INTO import_audit(key,value) VALUES('mojibake_proposed',?),('mojibake_applied',?)"
    )
    .run(proposed, applied);
  database.exec("COMMIT; PRAGMA optimize");
  const report = {
    source: basename(sourceDatabase),
    target: basename(targetDatabase),
    counts,
    mojibake: { proposed, applied },
    corrections,
    generatedAt: new Date().toISOString(),
  };
  writeFileSync(auditReport, `${JSON.stringify(report, null, 2)}\n`, {
    mode: 0o600,
  });
  console.log(
    JSON.stringify(
      {
        source: report.source,
        target: report.target,
        counts: report.counts,
        mojibake: report.mojibake,
        correctionDetails: "written to configured ignored report",
        generatedAt: report.generatedAt,
      },
      null,
      2
    )
  );
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

interface Correction {
  table: string;
  id: number | string;
  column: string;
  original: string;
  corrected: string;
}
function collectCorrections(source: DatabaseSync): Correction[] {
  const fields = [
    ["IRCNetworks", "IDNetwork", ["NetworkName", "Description"]],
    ["Authors", "IdAuthor", ["Author"]],
    ["WitGames", "IDWitGame", ["GameName"]],
    ["Subjects", "IdSubject", ["Subject"]],
    ["Channels", "IdChannel", ["Name"]],
    ["QuestionSubsets", "IDQuestionSubset", ["DESC"]],
    ["Questions_Table", "IDQuestion", ["Question", "Answer"]],
    ["Dictionary", "IDWord", ["word", "meaning"]],
    ["Players", "IdPlayer", ["NickName"]],
    ["Leagues", "IDLeague", ["DESC"]],
    ["Tournaments", "IdTournament", ["Desc"]],
    ["Games", "IdGame", ["Desc"]],
  ] as const;
  const result: Correction[] = [];
  for (const [table, id, columns] of fields) {
    for (const column of columns) {
      const rows = source
        .prepare(
          `SELECT ${id} id,${quoteIdentifier(column)} value FROM ${table} WHERE ${quoteIdentifier(column)} IS NOT NULL`
        )
        .iterate() as Iterable<Record<string, unknown>>;
      for (const row of rows) {
        const original = String(row.value);
        const repaired = repairMojibake(original);
        if (repaired.applied) {
          result.push({
            table,
            id: row.id as number | string,
            column,
            original,
            corrected: repaired.value,
          });
        }
      }
    }
  }
  return result;
}
function quoteIdentifier(value: string): string {
  return `"${value.replaceAll('"', '""')}"`;
}
