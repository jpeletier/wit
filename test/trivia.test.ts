import assert from "node:assert/strict";
import test from "node:test";
import {
  hintWord,
  matchesNumericAnswer,
  matchesTriviaAnswer,
  TriviaGame,
  numericHint,
  triviaPoints,
} from "../src/games/trivia.js";

test("text matching is unordered, case-insensitive, accent-sensitive and ignores empty tokens", () => {
  assert.equal(
    matchesTriviaAnswer("Nueva  York", "en YORK nueva ciudad"),
    true,
  );
  assert.equal(matchesTriviaAnswer("camión", "CAMION"), false);
  assert.equal(matchesTriviaAnswer("a a", "a"), false);
  assert.equal(
    matchesTriviaAnswer("1 2 3 4 5 6 7 8 9 10 11", "1 2 3 4 5 6 7 8 9 10 11"),
    false,
  );
});

test("numeric matching uses exact safe expression equality", () => {
  assert.equal(matchesNumericAnswer(42, "6*7"), true);
  assert.equal(matchesNumericAnswer(0.3, "0.1+0.2"), false);
  assert.equal(matchesNumericAnswer(6, "1d6"), false);
});

test("hints mask ASCII, digits and ñ while showing accented characters", () => {
  assert.equal(hintWord("Árbol.ñ2", 0), "Á----.--");
  assert.equal(hintWord("casa", 1), "c---");
  assert.equal(hintWord("casa", 2), "c--a");
});

test("round stages, score tiers and displayed maximum use banker rounding", () => {
  assert.equal(triviaPoints(5, 0.625), 62);
  assert.equal(triviaPoints(35, 1), 75);
  assert.equal(triviaPoints(45, 1), 50);
  const question = {
    id: 1,
    text: "Capital",
    answer: "Madrid",
    subjectId: 1,
    subject: "Geografía",
    author: "Autor",
  };
  const game = new TriviaGame(1, 0.625, () => question, { next: () => 0 });
  for (let index = 0; index < 5; index++) game.tick();
  assert.equal(game.submit("Ana", "madrid"), undefined);
  game.tick();
  const result = game.submit("Ana", "MADRID");
  assert.equal(result?.type, "correct");
  if (result?.type === "correct") assert.equal(result.points, 62);
  assert.deepEqual(game.tick(), []);
  assert.deepEqual(game.tick(), [{ type: "complete" }]);
});

test("legacy stages display on stage 5, accept immediately, and complete on the following stage-1 tick", () => {
  const question = {
    id: 1,
    text: "q",
    answer: "a",
    subjectId: 1,
    subject: "s",
    author: "x",
  };
  const game = new TriviaGame(1, 1, () => question, { next: () => 0 });
  for (let tick = 0; tick < 5; tick++) assert.deepEqual(game.tick(), []);
  assert.equal(game.tick()[0]?.type, "question");
  assert.equal(game.stage, 6);
  assert.equal(game.submit("n", "a")?.type, "correct");
  assert.deepEqual(game.tick(), []);
  assert.deepEqual(game.tick(), [{ type: "complete" }]);
});

test("numeric hints consume two independent random draws", () => {
  const draws = [0.25, 0.75];
  assert.equal(
    numericHint(100, 0, { next: () => draws.shift() ?? 0 }),
    "El número está entre\u00036 92\u0003 y\u00036 122\u0003",
  );
  assert.equal(draws.length, 0);
});

test("unusable long answers are skipped without consuming another round", () => {
  const questions = [
    {
      id: 1,
      text: "bad",
      answer: "1 2 3 4 5 6 7 8 9 10 11",
      subjectId: 1,
      subject: "s",
      author: "x",
    },
    {
      id: 2,
      text: "good",
      answer: "ok",
      subjectId: 1,
      subject: "s",
      author: "x",
    },
  ];
  const game = new TriviaGame(1, 1, () => questions.shift()!, {
    next: () => 0,
  });
  for (let tick = 0; tick < 6; tick++) {
    const event = game.tick()[0];
    if (event?.type === "question") assert.equal(event.question.id, 2);
  }
});
