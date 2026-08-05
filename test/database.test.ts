import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import {
  GameRepository,
  QuestionRepository,
  legacyLeagueId,
} from "../src/db/repositories.js";

function database(): DatabaseSync {
  const db = new DatabaseSync(":memory:");
  db.exec(readFileSync(resolve("migrations/001_initial.sql"), "utf8"));
  db.exec(
    "INSERT INTO networks VALUES(1,'red','','1','1'); INSERT INTO game_types VALUES(1,'Trivial'); INSERT INTO authors VALUES(1,'a'); INSERT INTO subjects VALUES(1,'s',1,1); INSERT INTO channels VALUES(1,1,'#c','#c',NULL,NULL); INSERT INTO question_subsets VALUES(1,'q',1,1); INSERT INTO leagues VALUES(1,'l',NULL,NULL); INSERT INTO tournaments VALUES(1,'t',NULL,NULL,1,1,1,1)",
  );
  return db;
}

test("player and score upserts are transactional and IDs remain unique", () => {
  const db = database();
  const repository = new GameRepository(db, {
    now: () => new Date("2026-08-05T00:00:00Z"),
  });
  const player = repository.player(1, "Álex");
  assert.equal(repository.player(1, "áLEX"), player);
  assert.equal(
    (
      db.prepare("SELECT last_used FROM players WHERE id=?").get(player) as {
        last_used: string;
      }
    ).last_used,
    "2026-08-05T02:00:00.000",
  );
  repository.addScore(player, 1, 1, 100);
  repository.addScore(player, 1, 1, 75);
  assert.deepEqual(
    { ...db.prepare("SELECT questions_answered,score FROM scores").get() },
    { questions_answered: 2, score: 175 },
  );
  assert.throws(() => repository.addScore(999, 1, 1, 1));
  assert.equal(
    (db.prepare("SELECT count(*) count FROM scores").get() as { count: number })
      .count,
    1,
  );
  db.close();
});

test("batch score persistence rolls back every winner on one invalid row", () => {
  const db = database();
  const repository = new GameRepository(db, {
    now: () => new Date("2026-08-05T00:00:00Z"),
  });
  const player = repository.player(1, "Ana");
  assert.throws(() =>
    repository.addScores(1, [
      { playerId: player, subjectId: 1, points: 20 },
      { playerId: 999, subjectId: 1, points: 10 },
    ]),
  );
  assert.equal(
    (db.prepare("SELECT count(*) count FROM scores").get() as { count: number })
      .count,
    0,
  );
  db.close();
});

test("legacy league IDs use the March 2001 epoch at month boundaries", () => {
  assert.equal(legacyLeagueId(new Date("2001-02-28T23:00:00Z")), 0);
  assert.equal(legacyLeagueId(new Date("2001-02-28T22:59:59Z")), -1);
  assert.equal(legacyLeagueId(new Date("2026-07-31T21:59:59Z")), 304);
  assert.equal(legacyLeagueId(new Date("2026-07-31T22:00:00Z")), 305);
  assert.equal(legacyLeagueId(new Date("2026-08-31T22:00:00Z")), 306);
});

test("runtime persistence uses offset-less Madrid wall timestamps", () => {
  const db = database();
  const repository = new GameRepository(db, {
    now: () => new Date("2026-08-05T00:00:00.123Z"),
  });
  const playerId = repository.player(1, "Ana");
  const context = repository.prepareTournament(1, "#madrid", 1);
  const gameId = repository.createGame(context.tournamentId, 5);
  repository.finishGame(gameId);
  const expected = "2026-08-05T02:00:00.123";
  assert.equal(
    (
      db
        .prepare("SELECT last_used value FROM players WHERE id=?")
        .get(playerId) as {
        value: string;
      }
    ).value,
    expected,
  );
  assert.equal(
    (
      db
        .prepare("SELECT last_used value FROM channels WHERE id=?")
        .get(context.channelId) as { value: string }
    ).value,
    expected,
  );
  assert.equal(
    (
      db
        .prepare("SELECT date_init value FROM tournaments WHERE id=?")
        .get(context.tournamentId) as { value: string }
    ).value,
    expected,
  );
  assert.deepEqual(
    {
      ...db
        .prepare("SELECT date_init,date_end FROM games WHERE id=?")
        .get(gameId),
    },
    { date_init: expected, date_end: expected },
  );
  db.close();
});

test("tournaments reuse current custom subsets and inherit stale defaults", () => {
  const db = database();
  db.exec(`INSERT INTO question_subsets VALUES(5,'Custom',2,NULL);
    INSERT INTO tournaments VALUES(50,'old',NULL,NULL,1,1,5,1);
    UPDATE channels SET default_tournament_id=50 WHERE id=1;
    INSERT INTO leagues VALUES(305,'305ª Liga de trivial',NULL,NULL);
    INSERT INTO tournaments VALUES(51,'current',NULL,NULL,1,305,5,1);`);
  const repository = new GameRepository(db, {
    now: () => new Date("2026-08-05T00:00:00Z"),
  });
  const reused = repository.prepareTournament(1, "#c", 1);
  assert.equal(reused.tournamentId, 51);
  assert.equal(reused.subsetId, 5);
  assert.equal(reused.multiplier, 2);
  db.exec(
    "UPDATE channels SET default_tournament_id=50 WHERE id=1; DELETE FROM tournaments WHERE id=51; DELETE FROM leagues WHERE id=305",
  );
  const inherited = repository.prepareTournament(1, "#c", 1);
  assert.equal(inherited.leagueId, 305);
  assert.equal(inherited.subsetId, 5);
  assert.equal(
    (
      db
        .prepare("SELECT default_tournament_id value FROM channels WHERE id=1")
        .get() as { value: number }
    ).value,
    inherited.tournamentId,
  );
  db.close();
});

test("game creation and finalization fail visibly on invalid state", () => {
  const db = database();
  const repository = new GameRepository(db, {
    now: () => new Date("2026-08-05T00:00:00Z"),
  });
  const game = repository.createGame(1, 5);
  repository.finishGame(game);
  assert.throws(() => repository.finishGame(game));
  db.close();
});

test("question selection increments repeat weighting transactionally", () => {
  const db = database();
  db.exec(
    "INSERT INTO question_subset_members VALUES(1,1,1,1); INSERT INTO questions VALUES(1,'q','a',NULL,0,1,1,1,0,NULL)",
  );
  const repository = new QuestionRepository(db, { next: () => 0 });
  assert.equal(repository.multiplier(1), 1);
  assert.equal(repository.next(1).id, 1);
  assert.equal(
    (
      db.prepare("SELECT repeats FROM questions WHERE id=1").get() as {
        repeats: number;
      }
    ).repeats,
    1,
  );
  db.close();
});

test("selector uses weighted subjects, IFS positions, FIFO and refresh mutations", () => {
  const db = database();
  db.exec(`INSERT INTO subjects VALUES(2,'s2',2,1); INSERT INTO question_subset_members VALUES(1,1,1,1);
    INSERT INTO question_subset_members VALUES(2,1,2,3);
    INSERT INTO questions VALUES(1,'q1','a1',NULL,0,1,1,1,1,NULL);
    INSERT INTO questions VALUES(2,'q2','a2',NULL,0,1,1,1,2,NULL);
    INSERT INTO questions VALUES(3,'q3','a3',NULL,0,2,1,1,1,NULL);
    INSERT INTO questions VALUES(4,'q4','a4',NULL,0,2,1,2,2,NULL);`);
  let draw = 0;
  const repository = new QuestionRepository(db, { next: () => draw });
  assert.equal(repository.next(1).id, 1);
  assert.equal(repository.next(1).id, 2);
  draw = 0.99;
  const weighted = repository.next(1);
  assert.equal(weighted.subjectId, 2);
  const rows = db
    .prepare(
      "SELECT repeats,random_value FROM questions WHERE id IN (1,2,4) ORDER BY id",
    )
    .all() as Array<{ repeats: number; random_value: number }>;
  assert.deepEqual(
    rows.map((row) => row.repeats),
    [2, 2, 1],
  );
  assert.ok(
    rows.every((row) => row.random_value >= 1 && row.random_value <= 10_000),
  );
  db.close();
});

const importedSchemaReady =
  existsSync("db/wit.sqlite") &&
  (() => {
    const db = new DatabaseSync("db/wit.sqlite", { readOnly: true });
    try {
      return (
        db.prepare("PRAGMA table_info(channels)").all() as Array<{
          name: string;
        }>
      ).some((column) => column.name === "default_tournament_id");
    } finally {
      db.close();
    }
  })();

test(
  "regenerated historical database retains league 305 and custom default subsets",
  { skip: !importedSchemaReady },
  () => {
    const db = new DatabaseSync("db/wit.sqlite", { readOnly: true });
    assert.equal(
      (
        db.prepare("SELECT count(*) count FROM leagues WHERE id=305").get() as {
          count: number;
        }
      ).count,
      1,
    );
    const row = db
      .prepare(
        `SELECT c.id,c.default_tournament_id,t.question_subset_id,t.league_id FROM channels c
    JOIN tournaments t ON t.id=c.default_tournament_id WHERE t.game_type_id=1 AND t.question_subset_id<>1 LIMIT 1`,
      )
      .get() as
      | {
          id: number;
          default_tournament_id: number;
          question_subset_id: number;
        }
      | undefined;
    assert.ok(row !== undefined);
    const typed = row as {
      id: number;
      default_tournament_id: number;
      question_subset_id: number;
      league_id: number;
    };
    const date = new Date(2001, 2 + typed.league_id, 1);
    const repository = new GameRepository(db, { now: () => date });
    const channel = db
      .prepare("SELECT network_id,name FROM channels WHERE id=?")
      .get(typed.id) as { network_id: number; name: string };
    const context = repository.prepareTournament(
      channel.network_id,
      channel.name,
      1,
    );
    assert.equal(context.tournamentId, typed.default_tournament_id);
    assert.equal(context.subsetId, typed.question_subset_id);
    db.close();
  },
);
