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
import { cylTranscript, triviaTranscript } from "./fixtures/transcripts.js";

const fakePorts: FakeIrcPort[] = [];

test.after(() => {
  for (const irc of fakePorts)
    for (const entry of irc.sent)
      if (entry.kind === "message" || entry.kind === "notice")
        assert.doesNotMatch(entry.text, /[\r\n\0]/u);
});

function fixture(): {
  bot: WitBot;
  irc: FakeIrcPort;
  db: DatabaseSync;
  games: GameRepository;
} {
  const db = new DatabaseSync(":memory:");
  db.exec(readFileSync(resolve("migrations/001_initial.sql"), "utf8"));
  db.exec(`INSERT INTO networks VALUES(1,'red','','1','1'); INSERT INTO game_types VALUES(1,'Trivial'); INSERT INTO game_types VALUES(2,'CYL');
    INSERT INTO authors VALUES(1,'Autor'); INSERT INTO subjects VALUES(1,'Tema',1,1); INSERT INTO subjects VALUES(97,'Cifras',0,2); INSERT INTO subjects VALUES(98,'Letras',0,2);
    INSERT INTO question_subsets VALUES(1,'General',1,NULL); INSERT INTO question_subsets VALUES(34,'CYL',1,NULL); INSERT INTO question_subset_members VALUES(1,1,1,1);
    INSERT INTO questions VALUES(1,'Pregunta 1','Respuesta',NULL,0,1,1,1,1,NULL);
    INSERT INTO questions VALUES(2,'Pregunta 2','Respuesta',NULL,0,1,1,1,2,NULL);
    INSERT INTO questions VALUES(3,'Pregunta 3','Respuesta',NULL,0,1,1,1,3,NULL);
    INSERT INTO questions VALUES(4,'Pregunta 4','Respuesta',NULL,0,1,1,1,4,NULL);
    INSERT INTO questions VALUES(5,'Pregunta 5','Respuesta',NULL,0,1,1,1,5,NULL);
    INSERT INTO dictionary VALUES(1,'aa','aa','doble a','OK');
    INSERT INTO dictionary VALUES(2,'AAA','aaa','triple a','OK');
    INSERT INTO dictionary VALUES(3,'AAAA','aaaa','cuádruple a','OK');`);
  const irc = new FakeIrcPort();
  fakePorts.push(irc);
  const clock = { now: () => new Date("2026-08-05T00:00:00Z") };
  const games = new GameRepository(db, clock);
  const bot = new WitBot(
    irc,
    games,
    new QuestionRepository(db, { next: () => 0 }),
    new DictionaryRepository(db),
    clock,
    { next: () => 0 },
    { networkId: 1, welcomeOnJoin: true },
  );
  return { bot, irc, db, games };
}

test("commands report busy channels, authorize stop, welcome every join and force calculator display", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u@h", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
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

test("commands require membership, STOP matches type, defaults/clamps and self-kick finalizes", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c nope" });
  assert.ok(
    irc.sent.some(
      (entry) => entry.text === "Primero debo estar en el canal #c.",
    ),
  );
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 1" });
  irc.setOperator("#c", "Ana");
  bot.handle({ type: "privateMessage", user, text: "CYL #c STOP" });
  assert.ok(
    irc.sent.some((entry) =>
      entry.text.includes("No hay ninguna partida activa de Cifras"),
    ),
  );
  irc.emit({
    type: "kick",
    channel: "#c",
    user: { identity: "op", nick: "Op" },
    kickedNick: "Wit",
    self: true,
  });
  assert.equal(
    (
      db.prepare("SELECT num_questions FROM games").get() as {
        num_questions: number;
      }
    ).num_questions,
    5,
  );
  assert.equal(
    (
      db
        .prepare("SELECT count(*) count FROM games WHERE date_end IS NOT NULL")
        .get() as { count: number }
    ).count,
    1,
  );
  irc.emit({
    type: "join",
    channel: "#d",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #d nonsense" });
  assert.equal(
    (
      db
        .prepare("SELECT num_questions FROM games ORDER BY id DESC LIMIT 1")
        .get() as { num_questions: number }
    ).num_questions,
    20,
  );
  db.close();
});

test("active Trivia survives late CASEMAPPING for messages and completion", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.caseMapping = "ascii";
  irc.emit({
    type: "join",
    channel: "#Trivia[",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({
    type: "privateMessage",
    user,
    text: "TRIVIAL #Trivia[ 5",
  });
  irc.caseMapping = "rfc1459";
  assert.equal(irc.isJoined("#trivia{"), true);
  for (let round = 0; round < 5; round++) {
    for (let tick = 0; tick < 6; tick++) bot.tick();
    bot.handle({
      type: "message",
      channel: "#trivia{",
      user,
      text: "Respuesta",
    });
  }
  bot.tick();
  bot.tick();
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

test("operator STOP finds a session after CASEMAPPING changes", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana^" };
  irc.caseMapping = "ascii";
  irc.emit({
    type: "join",
    channel: "#Stop[",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  irc.setOperator("#Stop[", "Ana^");
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #Stop[ 5" });
  irc.caseMapping = "rfc1459";
  bot.handle({
    type: "privateMessage",
    user: { identity: "u", nick: "Ana~" },
    text: "TRIVIAL #stop{ STOP",
  });
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

test("CASEMAPPING session collisions finalize every game without overwrite", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.caseMapping = "ascii";
  for (const channel of ["#Game[", "#Game{"])
    irc.emit({
      type: "join",
      channel,
      user: { identity: "bot", nick: "Wit" },
      self: true,
    });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #Game[ 5" });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #Game{ 5" });
  irc.caseMapping = "rfc1459";
  assert.equal(
    (
      db
        .prepare("SELECT count(*) count FROM games WHERE date_end IS NOT NULL")
        .get() as { count: number }
    ).count,
    2,
  );
  assert.equal(
    irc.sent.filter((entry) => entry.text.includes("conflicto de CASEMAPPING"))
      .length,
    2,
  );
  db.close();
});

test("deterministic full Trivia transcript", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  for (let round = 0; round < 5; round++) {
    for (let tick = 0; tick < 6; tick++) bot.tick();
    bot.handle({ type: "message", channel: "#c", user, text: "Respuesta" });
  }
  bot.tick();
  bot.tick();
  const transcript = irc.sent
    .filter((entry) => entry.kind === "message")
    .map((entry) => entry.text);
  assert.deepEqual(transcript, triviaTranscript);
  db.close();
});

test("deterministic full CYL transcript", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "CYL #c 1" });
  for (let tick = 0; tick < 5; tick++) bot.tick();
  bot.handle({ type: "message", channel: "#c", user, text: "AA" });
  bot.handle({
    type: "message",
    channel: "#c",
    user: { identity: "u2", nick: "Bea" },
    text: "AAA",
  });
  bot.handle({
    type: "message",
    channel: "#c",
    user: { identity: "u3", nick: "Carla" },
    text: "AAAA",
  });
  for (let tick = 5; tick < 60; tick++) bot.tick();
  const transcript = irc.sent
    .filter((entry) => entry.kind === "message")
    .map((entry) => entry.text);
  assert.deepEqual(transcript, cylTranscript);
  db.close();
});

test("discarded fourth Letras candidate creates no player or completion entry", () => {
  const { bot, irc, db } = fixture();
  db.exec(
    "INSERT INTO dictionary VALUES(4,'ÁA','áa','doble a acentuada','OK')",
  );
  const users = [
    { identity: "u1", nick: "Ana", word: "AA" },
    { identity: "u2", nick: "Bea", word: "AAA" },
    { identity: "u3", nick: "Carla", word: "AAAA" },
    { identity: "u4", nick: "Dora", word: "ÁA" },
  ];
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({
    type: "privateMessage",
    user: users[0]!,
    text: "CYL #c 1",
  });
  for (let tick = 0; tick < 5; tick++) bot.tick();
  for (const user of users)
    bot.handle({
      type: "message",
      channel: "#c",
      user,
      text: user.word,
    });
  assert.equal(
    (
      db.prepare("SELECT count(*) count FROM players").get() as {
        count: number;
      }
    ).count,
    3,
  );
  for (let tick = 5; tick < 60; tick++) bot.tick();
  const standings = irc.sent.find((entry) =>
    entry.text.startsWith("Puntuaciones:"),
  );
  assert.ok(standings?.text.includes("Carla"));
  assert.ok(standings?.text.includes("Bea"));
  assert.ok(standings?.text.includes("Ana"));
  assert.equal(standings?.text.includes("Dora"), false);
  const completion = irc.sent.filter((entry) =>
    entry.text.includes("Clasificación General"),
  );
  assert.equal(completion.length, 3);
  assert.equal(
    completion.some((entry) => entry.text.includes("Dora")),
    false,
  );
  assert.equal(
    irc.sent.some((entry) => entry.text.includes("Dora")),
    false,
  );
  db.close();
});

test("numeric Trivia displays submitted expression, canonical result, author and question ID", () => {
  const { bot, irc, db } = fixture();
  db.exec("UPDATE questions SET answer='42' WHERE id=1");
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  for (let tick = 0; tick < 6; tick++) bot.tick();
  bot.handle({ type: "message", channel: "#c", user, text: "6*7" });
  const line = irc.sent.find(
    (entry) => entry.kind === "message" && entry.text.includes("6*7=42"),
  );
  assert.ok(line?.text.includes("Autor"));
  assert.ok(line?.text.includes("#1"));
  db.close();
});

test("text Trivia always reveals the canonical answer for flexible matches", () => {
  for (const submitted of [
    "nueva york",
    "NUEVA YORK",
    "York Nueva",
    "en York Nueva ciudad",
  ]) {
    const { bot, irc, db } = fixture();
    db.exec("UPDATE questions SET answer='Nueva York' WHERE id=1");
    const user = { identity: "u", nick: "Ana" };
    irc.emit({
      type: "join",
      channel: "#c",
      user: { identity: "bot", nick: "Wit" },
      self: true,
    });
    bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
    for (let tick = 0; tick < 6; tick++) bot.tick();
    bot.handle({ type: "message", channel: "#c", user, text: submitted });
    const reveal = irc.sent.find((entry) =>
      entry.text.includes("La respuesta era"),
    );
    assert.ok(reveal?.text.includes("\u0002Nueva York\u0002"));
    assert.equal(reveal?.text.includes("="), false);
    db.close();
  }
});

test("numeric Trivia displays literals once and expressions with canonical results", () => {
  for (const [submitted, expected] of [
    ["42", "\u000242\u0002"],
    ["6*7", "\u00026*7=42\u0002"],
  ] as const) {
    const { bot, irc, db } = fixture();
    db.exec("UPDATE questions SET answer='42' WHERE id=1");
    const user = { identity: "u", nick: "Ana" };
    irc.emit({
      type: "join",
      channel: "#c",
      user: { identity: "bot", nick: "Wit" },
      self: true,
    });
    bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
    for (let tick = 0; tick < 6; tick++) bot.tick();
    bot.handle({ type: "message", channel: "#c", user, text: submitted });
    const reveal = irc.sent.find((entry) =>
      entry.text.includes("La respuesta era"),
    );
    assert.ok(reveal?.text.includes(expected));
    db.close();
  }
});

test("Trivia sanitizes database question text and line-broken repeated answers", () => {
  const { bot, irc, db } = fixture();
  db.exec(`UPDATE questions
    SET question='Pregunta' || char(10) || 'inyectada' || char(0) || 'fin',
        answer='Respuesta' || char(13) || char(10) || 'RESPUESTA'
    WHERE id=1`);
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  for (let tick = 0; tick < 6; tick++) bot.tick();
  assert.ok(
    irc.sent.some((entry) => entry.text.includes("Pregunta inyectada fin")),
  );
  bot.handle({ type: "message", channel: "#c", user, text: "Respuesta" });
  const reveal = irc.sent.find((entry) =>
    entry.text.includes("La respuesta era"),
  );
  assert.ok(reveal?.text.includes("\u0002Respuesta\u0002"));
  assert.equal(reveal?.text.includes("Respuesta RESPUESTA"), false);
  db.close();
});

test("CYL sanitizes database definitions before displaying excerpts", () => {
  const { bot, irc, db } = fixture();
  db.exec(`UPDATE dictionary
    SET meaning='primera línea' || char(10) || char(0) || 'segunda parte'
    WHERE id=1`);
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "CYL #c 1" });
  for (let tick = 0; tick < 5; tick++) bot.tick();
  bot.handle({ type: "message", channel: "#c", user, text: "AA" });
  for (let tick = 5; tick < 60; tick++) bot.tick();
  assert.ok(
    irc.sent.some((entry) =>
      entry.text.includes(': "primera línea segunda parte"'),
    ),
  );
  db.close();
});

test("Cifras exact answer closes next tick with legacy wording and 200-point delta", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "CYL #c 4" });
  for (let challenge = 0; challenge < 3; challenge++)
    for (let tick = 0; tick < 60; tick++) bot.tick();
  for (let tick = 0; tick < 5; tick++) bot.tick();
  bot.handle({ type: "message", channel: "#c", user, text: "5^3-6*4" });
  assert.equal(
    irc.sent.some((entry) => entry.text.includes("consiguió el número exacto")),
    false,
  );
  bot.tick();
  assert.ok(
    irc.sent.some(
      (entry) =>
        entry.text ===
        "\u00037¡ Ana consiguió el número exacto !\u0003\u00032 5^3-6*4 = 101\u0003",
    ),
  );
  assert.ok(
    irc.sent.some((entry) => entry.text.includes("(\u00034+200\u0003)")),
  );
  db.close();
});

test("question initialization does not create orphan games", () => {
  const { bot, irc, db } = fixture();
  db.exec("UPDATE questions SET selection_ifs=NULL");
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  assert.equal(
    (db.prepare("SELECT count(*) count FROM games").get() as { count: number })
      .count,
    0,
  );
  assert.ok(
    irc.sent.some(
      (entry) =>
        entry.kind === "notice" &&
        entry.text.includes("no tiene preguntas utilizables"),
    ),
  );
  db.close();
});

test("IRC announcement failure finalizes the newly created game", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  irc.say = () => {
    throw new Error("send failed");
  };
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  assert.equal(
    (
      db
        .prepare("SELECT count(*) count FROM games WHERE date_end IS NOT NULL")
        .get() as { count: number }
    ).count,
    1,
  );
  assert.ok(
    irc.sent.some(
      (entry) => entry.kind === "notice" && entry.text.includes("send failed"),
    ),
  );
  db.close();
});

test("score persistence failure visibly finalizes and removes the accepted game", () => {
  const { bot, irc, db, games } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  for (let tick = 0; tick < 6; tick++) bot.tick();
  games.addScore = () => {
    throw new Error("write failed");
  };
  bot.handle({ type: "message", channel: "#c", user, text: "Respuesta" });
  assert.ok(
    irc.sent.some(
      (entry) =>
        entry.text.includes("write failed") && entry.text.includes("terminado"),
    ),
  );
  assert.equal(
    (
      db
        .prepare("SELECT count(*) count FROM games WHERE date_end IS NOT NULL")
        .get() as { count: number }
    ).count,
    1,
  );
  bot.handle({ type: "message", channel: "#c", user, text: "?2" });
  assert.ok(irc.sent.some((entry) => entry.text === "Ana: 2=2"));
  db.close();
});

test("finalization failure is visible and still removes the session", () => {
  const { bot, irc, db, games } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  games.finishGame = () => {
    throw new Error("finalize failed");
  };
  irc.setOperator("#c", "Ana");
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c STOP" });
  assert.ok(
    irc.sent.some(
      (entry) =>
        entry.text.includes("Error al finalizar") &&
        entry.text.includes("finalize failed"),
    ),
  );
  bot.handle({ type: "message", channel: "#c", user, text: "?2" });
  assert.ok(irc.sent.some((entry) => entry.text === "Ana: 2=2"));
  db.close();
});

test("disconnect removes session when both finalization and IRC error reporting fail", () => {
  const { bot, irc, db, games } = fixture();
  const user = { identity: "u", nick: "Ana" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  games.finishGame = () => {
    throw new Error("finalize failed");
  };
  const originalSay = irc.say.bind(irc);
  const originalError = console.error;
  const logs: string[] = [];
  irc.say = () => {
    throw new Error("connection closed");
  };
  console.error = (...args: unknown[]) => logs.push(args.map(String).join(" "));
  try {
    assert.doesNotThrow(() => irc.emit({ type: "disconnected" }));
  } finally {
    irc.say = originalSay;
    console.error = originalError;
  }
  assert.ok(
    logs.some(
      (line) =>
        line.includes("finalize failed") && line.includes("connection closed"),
    ),
  );
  bot.handle({ type: "message", channel: "#c", user, text: "?2" });
  assert.ok(irc.sent.some((entry) => entry.text === "Ana: 2=2"));
  db.close();
});

test("a bot allows two concurrent Trivia games and blocks a third and CYL", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "u", nick: "Ana" };
  for (const channel of ["#a", "#b", "#c", "#d"])
    irc.emit({
      type: "join",
      channel,
      user: { identity: "bot", nick: "Wit" },
      self: true,
    });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #a 5" });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #b 5" });
  bot.handle({ type: "privateMessage", user, text: "TRIVIAL #c 5" });
  bot.handle({ type: "privateMessage", user, text: "CYL #d 5" });
  assert.equal(
    irc.sent.filter(
      (entry) => entry.kind === "notice" && entry.text.includes("demasiados"),
    ).length,
    2,
  );
  assert.equal(
    (db.prepare("SELECT count(*) count FROM games").get() as { count: number })
      .count,
    2,
  );
  db.close();
});

test("nick changes keep identity and disconnect ends active game without failover", () => {
  const { bot, irc, db } = fixture();
  const user = { identity: "same@host", nick: "Antes" };
  irc.emit({
    type: "join",
    channel: "#c",
    user: { identity: "bot", nick: "Wit" },
    self: true,
  });
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

test("stop unsubscribes before disconnect and is idempotent", () => {
  const { bot, irc, db } = fixture();
  assert.equal(irc.eventListenerCount, 1);
  bot.stop();
  bot.stop();
  assert.equal(irc.eventListenerCount, 0);
  assert.equal(irc.disconnectCount, 1);
  db.close();
});
