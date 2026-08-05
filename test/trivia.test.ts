import assert from "node:assert/strict";
import test from "node:test";
import {
  hintWord,
  matchesNumericAnswer,
  matchesTriviaAnswer,
  TriviaGame,
  triviaPoints,
} from "../src/games/trivia.js";

const clock = { now: () => new Date("2026-08-05T10:00:00Z") };

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
  const game = new TriviaGame(
    [
      {
        id: 1,
        text: "Capital",
        answer: "Madrid",
        subjectId: 1,
        subject: "Geografía",
        author: "Autor",
      },
    ],
    0.625,
    clock,
  );
  for (let index = 0; index < 5; index++) game.tick();
  assert.equal(game.submit("Ana", "madrid"), undefined);
  game.tick();
  const result = game.submit("Ana", "MADRID");
  assert.equal(result?.type, "correct");
  if (result?.type === "correct") assert.equal(result.points, 62);
  assert.deepEqual(game.tick(), [{ type: "complete" }]);
});
