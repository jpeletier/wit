import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { WitBot } from "../src/app/bot.js";
import {
  DictionaryRepository,
  GameRepository,
  QuestionRepository,
} from "../src/db/repositories.js";
import { FakeIrcPort } from "../src/irc/port.js";

function fixture(): { bot: WitBot; irc: FakeIrcPort; db: DatabaseSync } {
  const db = new DatabaseSync(":memory:");
  db.exec(readFileSync(resolve("migrations/001_initial.sql"), "utf8"));
  db.exec(`INSERT INTO networks VALUES(1,'red','','1','1'); INSERT INTO game_types VALUES(1,'Trivial'); INSERT INTO game_types VALUES(2,'CYL');
    INSERT INTO authors VALUES(1,'Autor'); INSERT INTO subjects VALUES(1,'Tema',1,1); INSERT INTO subjects VALUES(97,'Cifras',0,2); INSERT INTO subjects VALUES(98,'Letras',0,2);
    INSERT INTO question_subsets VALUES(1,'General',1,NULL); INSERT INTO question_subsets VALUES(34,'CYL',1,NULL); INSERT INTO question_subset_members VALUES(1,1,1,1);
    INSERT INTO questions VALUES(1,'Pregunta 1','Respuesta',NULL,0,1,1,0,1,0);
    INSERT INTO questions VALUES(2,'Pregunta 2','Respuesta',NULL,0,1,1,0,2,0);
    INSERT INTO questions VALUES(3,'Pregunta 3','Respuesta',NULL,0,1,1,0,3,0);
    INSERT INTO questions VALUES(4,'Pregunta 4','Respuesta',NULL,0,1,1,0,4,0);
    INSERT INTO questions VALUES(5,'Pregunta 5','Respuesta',NULL,0,1,1,0,5,0);`);
  const irc = new FakeIrcPort();
  const clock = { now: () => new Date("2026-08-05T00:00:00Z") };
  const bot = new WitBot(
    irc,
    new GameRepository(db, clock),
    new QuestionRepository(db, { next: () => 0 }),
    new DictionaryRepository(db),
    clock,
    { next: () => 0 },
    { networkId: 1, welcomeOnJoin: true },
  );
  return { bot, irc, db };
}

test("commands report busy channels, authorize stop, welcome every join and force calculator display", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u@h", nick: "Ana" };
  bot.handle({ type: "join", channel: "#c", user, self: false });
  bot.handle({ type: "join", channel: "#c", user, self: false });
  assert.equal(
    irc.sent.filter(
      (entry) => entry.kind === "notice" && entry.text.startsWith("Bienvenido"),
    ).length,
    2,
  );
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  bot.handle({ type: "privateMessage", user, text: "CYL #c 5" });
  assert.ok(
    irc.sent.some((entry) => entry.text.includes("Ya hay una partida activa")),
  );
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c STOP" });
  assert.ok(irc.sent.some((entry) => entry.text.includes("Sólo un operador")));
  irc.setOperator("#c", "Ana");
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c STOP" });
  bot.handle({ type: "message", channel: "#c", user, text: "?2" });
  assert.ok(irc.sent.some((entry) => entry.text === "Ana: 2=2"));
  db.close();
});

test("nick changes keep identity and disconnect ends active game without failover", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "same@host", nick: "Antes" };
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  bot.handle({
    type: "nick",
    previousNick: "Antes",
    user: { identity: "same@host", nick: "Después" },
  });
  bot.handle({ type: "disconnected", reason: "lost" });
  assert.ok(irc.sent.some((entry) => entry.text.includes("se desconectó")));
  assert.equal(
    (
      db
        .prepare("SELECT count(*) count FROM games WHERE date_end IS NOT NULL")
        .get() as { count: number }
    ).count,
    1,
  );
  db.close();
});
