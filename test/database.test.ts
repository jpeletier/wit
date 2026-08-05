import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { GameRepository, QuestionRepository } from "../src/db/repositories.js";

function database(): DatabaseSync {
  const db = new DatabaseSync(":memory:");
  db.exec(readFileSync(resolve("migrations/001_initial.sql"), "utf8"));
  db.exec(
    "INSERT INTO networks VALUES(1,'red','','1','1'); INSERT INTO game_types VALUES(1,'Trivial'); INSERT INTO authors VALUES(1,'a'); INSERT INTO subjects VALUES(1,'s',0,1); INSERT INTO channels VALUES(1,1,'#c','#c',NULL); INSERT INTO question_subsets VALUES(1,'q',1,1); INSERT INTO leagues VALUES(1,'l',NULL,NULL); INSERT INTO tournaments VALUES(1,'t',NULL,NULL,1,1,1,1)",
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
    "INSERT INTO question_subset_members VALUES(1,1,1,1); INSERT INTO questions VALUES(1,'q','a',NULL,0,1,1,0,0,0)",
  );
  const repository = new QuestionRepository(db, { next: () => 0 });
  assert.equal(repository.multiplier(1), 1);
  assert.equal(repository.select(1, 1)[0]?.id, 1);
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
