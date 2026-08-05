import { DatabaseSync } from "node:sqlite";
import { lookupKey, repairMojibake } from "../src/core/text.js";
import { sourceDatabase, targetDatabase } from "./paths.js";

const target = new DatabaseSync(targetDatabase, { readOnly: true });
const source = new DatabaseSync(sourceDatabase, { readOnly: true });
source.function("wit_text", { deterministic: true }, (value) =>
  value === null ? null : repairMojibake(String(value)).value,
);
source.function("wit_key", { deterministic: true }, (value) =>
  lookupKey(repairMojibake(String(value)).value),
);

const specs: Array<{ name: string; source: string; target: string }> = [
  {
    name: "networks",
    source: `SELECT IDNetwork id,wit_text(COALESCE(NetworkName,'')) name,wit_text(COALESCE(Description,'')) description,AllowJOIN_SC allow_join,COALESCE(JoinFree,1) join_free FROM IRCNetworks ORDER BY IDNetwork`,
    target:
      "SELECT id,name,description,allow_join,join_free FROM networks ORDER BY id",
  },
  {
    name: "authors",
    source: `SELECT IdAuthor id,wit_text(COALESCE(NULLIF(trim(Author),''),'(sin autor)')) author FROM Authors ORDER BY IdAuthor`,
    target: "SELECT id,author FROM authors ORDER BY id",
  },
  {
    name: "game_types",
    source: `SELECT IDWitGame id,wit_text(COALESCE(GameName,'')) name FROM WitGames ORDER BY IDWitGame`,
    target: "SELECT id,name FROM game_types ORDER BY id",
  },
  {
    name: "subjects",
    source: `SELECT IdSubject id,wit_text(Subject) subject,COALESCE(cnt,0) question_count,IDWitGame game_type_id FROM Subjects ORDER BY IdSubject`,
    target:
      "SELECT id,subject,question_count,game_type_id FROM subjects ORDER BY id",
  },
  {
    name: "channels",
    source: `SELECT IdChannel id,IDNetwork network_id,wit_text(Name) name,wit_key(Name) name_key,LastUsed last_used,IdDefaultTournament default_tournament_id FROM Channels ORDER BY IdChannel`,
    target:
      "SELECT id,network_id,name,name_key,last_used,default_tournament_id FROM channels ORDER BY id",
  },
  {
    name: "question_subsets",
    source: `SELECT IDQuestionSubset id,wit_text(COALESCE("DESC",'')) description,COALESCE(Multiplier,1) multiplier,IDChannel channel_id FROM QuestionSubsets ORDER BY IDQuestionSubset`,
    target:
      "SELECT id,description,multiplier,channel_id FROM question_subsets ORDER BY id",
  },
  {
    name: "question_subset_members",
    source: `SELECT IDQSubsetMembers id,IDQuestionSubset subset_id,IDSubject subject_id,MAX(COALESCE(weight,1),1) weight FROM QSubsetMembers ORDER BY IDQSubsetMembers`,
    target:
      "SELECT id,subset_id,subject_id,weight FROM question_subset_members ORDER BY id",
  },
  {
    name: "questions",
    source: `SELECT IDQuestion id,wit_text(Question) question,wit_text(Answer) answer,Source source,Repeats repeats,IDSubject subject_id,IDAuthor author_id,IFS selection_ifs,rndnum random_value,score selection_score FROM Questions_Table ORDER BY IDQuestion`,
    target:
      "SELECT id,question,answer,source,repeats,subject_id,author_id,selection_ifs,random_value,selection_score FROM questions ORDER BY id",
  },
  {
    name: "dictionary",
    source: `SELECT IDWord id,wit_text(word) word,wit_key(word) word_key,wit_text(meaning) meaning,status FROM Dictionary WHERE status IN ('OK','NF') ORDER BY word`,
    target:
      "SELECT id,word,word_key,meaning,status FROM dictionary ORDER BY word",
  },
  {
    name: "players",
    source: `SELECT IdPlayer id,IDNetwork network_id,wit_text(NickName) nick,wit_key(NickName) nick_key,LastUsed last_used FROM Players ORDER BY IdPlayer`,
    target:
      "SELECT id,network_id,nick,nick_key,last_used FROM players ORDER BY id",
  },
  {
    name: "leagues",
    source: `SELECT IDLeague id,wit_text(COALESCE("DESC",'')) description,DateInit date_init,DateEnd date_end FROM Leagues ORDER BY IDLeague`,
    target: "SELECT id,description,date_init,date_end FROM leagues ORDER BY id",
  },
  {
    name: "tournaments",
    source: `SELECT IdTournament id,wit_text(COALESCE("Desc",'')) description,DateInit date_init,DateEnd date_end,IdChannel channel_id,IDLeague league_id,IDQuestionSubset question_subset_id,IDWitGame game_type_id FROM Tournaments ORDER BY IdTournament`,
    target:
      "SELECT id,description,date_init,date_end,channel_id,league_id,question_subset_id,game_type_id FROM tournaments ORDER BY id",
  },
  {
    name: "games",
    source: `SELECT IdGame id,IdTournament tournament_id,MAX(COALESCE(NumQuestions,0),0) num_questions,DateInit date_init,DateEnd date_end,wit_text(COALESCE("Desc",'')) description FROM Games ORDER BY IdGame`,
    target:
      "SELECT id,tournament_id,num_questions,date_init,date_end,description FROM games ORDER BY id",
  },
  {
    name: "scores",
    source: `SELECT IDScore id,IDPlayer player_id,IDTournament tournament_id,IDSubject subject_id,MAX(QuestionsAnswered,0) questions_answered,Score score FROM ScoresT ORDER BY IDScore`,
    target:
      "SELECT id,player_id,tournament_id,subject_id,questions_answered,score FROM scores ORDER BY id",
  },
  {
    name: "score_history",
    source: `SELECT COALESCE(IDScore,rowid) id,IDPlayer player_id,IDTournament tournament_id,IDSubject subject_id,MAX(QuestionsAnswered,0) questions_answered,Score score FROM ScoresT_History ORDER BY COALESCE(IDScore,rowid)`,
    target:
      "SELECT id,player_id,tournament_id,subject_id,questions_answered,score FROM score_history ORDER BY id",
  },
];

try {
  assert(
    (target.prepare("PRAGMA foreign_keys").get() as { foreign_keys: number })
      .foreign_keys === 1,
    "foreign_keys is disabled",
  );
  assert(
    target.prepare("PRAGMA foreign_key_check").all().length === 0,
    "foreign key violations found",
  );
  const counts: Record<string, number> = {};
  for (const spec of specs) counts[spec.name] = compareEveryField(spec);
  compareRankings();
  verifySchema();
  const audit = Object.fromEntries(
    (
      target.prepare("SELECT key,value FROM import_audit").all() as Array<{
        key: string;
        value: number;
      }>
    ).map((row) => [row.key, row.value]),
  );
  assert(
    audit.mojibake_proposed === audit.mojibake_applied,
    "not every proposed correction was applied",
  );
  console.log(
    JSON.stringify(
      {
        verified: true,
        comparison: "every projected field",
        counts,
        audit,
        rankingEquivalence: true,
        forbiddenData: "absent",
      },
      null,
      2,
    ),
  );
} finally {
  target.close();
  source.close();
}

function compareEveryField(spec: {
  name: string;
  source: string;
  target: string;
}): number {
  const expected = source.prepare(spec.source).iterate()[Symbol.iterator]();
  const actual = target.prepare(spec.target).iterate()[Symbol.iterator]();
  let count = 0;
  while (true) {
    const left = expected.next();
    const right = actual.next();
    if (left.done || right.done) {
      assert(
        left.done === right.done,
        `${spec.name}: row count differs at ${count}`,
      );
      break;
    }
    const leftValues = Object.values(left.value as Record<string, unknown>);
    const rightValues = Object.values(right.value as Record<string, unknown>);
    assert(
      leftValues.length === rightValues.length &&
        leftValues.every((value, index) =>
          Object.is(value, rightValues[index]),
        ),
      `${spec.name}: projected fields differ at row ${count + 1}`,
    );
    count++;
  }
  return count;
}

function compareRankings(): void {
  const sourceRows = source
    .prepare(
      `SELECT IDTournament tournament_id,IDPlayer player_id,SUM(Score) total FROM ScoresT GROUP BY IDTournament,IDPlayer ORDER BY IDTournament,total DESC,IDPlayer`,
    )
    .iterate();
  const sourceIterator = sourceRows[Symbol.iterator]();
  const targetRows = target
    .prepare(
      `SELECT tournament_id,player_id,SUM(score) total FROM scores GROUP BY tournament_id,player_id ORDER BY tournament_id,total DESC,player_id`,
    )
    .iterate();
  const targetIterator = targetRows[Symbol.iterator]();
  let row = 0;
  while (true) {
    const left = sourceIterator.next();
    const right = targetIterator.next();
    if (left.done || right.done) {
      assert(left.done === right.done, "ranking row count differs");
      break;
    }
    assert(
      Object.values(left.value as Record<string, unknown>).every(
        (value, index) =>
          Object.is(
            value,
            Object.values(right.value as Record<string, unknown>)[index],
          ),
      ),
      `ranking differs at row ${row}`,
    );
    row++;
  }
}

function verifySchema(): void {
  const tables = new Set(
    (
      target
        .prepare(
          "SELECT lower(name) name FROM sqlite_master WHERE type='table'",
        )
        .all() as Array<{ name: string }>
    ).map((row) => row.name),
  );
  for (const table of [
    "admins",
    "bans",
    "ipbans",
    "mywits",
    "wsnicks",
    "witops",
    "bank_users",
    "bank_history",
    "teams",
    "teammembers",
    "sms_contributors",
    "question_votes",
    "cylscores",
    "forum_members",
  ])
    assert(!tables.has(table), `forbidden table present: ${table}`);
  const allColumns = [...tables].flatMap((table) =>
    (
      target.prepare(`PRAGMA table_info("${table}")`).all() as Array<{
        name: string;
      }>
    ).map((row) => row.name.toLowerCase()),
  );
  for (const column of [
    "externalid",
    "password",
    "adminlevel",
    "ip",
    "secretcode",
    "nickpassword",
  ])
    assert(!allColumns.includes(column), `forbidden column present: ${column}`);
  const indexes = new Set(
    (
      target
        .prepare("SELECT name FROM sqlite_master WHERE type='index'")
        .all() as Array<{ name: string }>
    ).map((row) => row.name),
  );
  for (const index of [
    "idx_questions_selection",
    "idx_players_nick",
    "idx_tournaments_active",
    "idx_games_tournament",
    "idx_scores_ranking",
    "idx_score_history_ranking",
  ])
    assert(indexes.has(index), `missing index: ${index}`);
}

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
