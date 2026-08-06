import assert from "node:assert/strict";
import test from "node:test";
import {
  CYL_K,
  generateNumbers,
  generateRandomConsonant2,
  generateRandomLetter2,
  generateRandomVowel,
  LetterRound,
  NumberRound,
  scoreNumber,
  scoreWord,
  usesNumberInventory,
  usesSuppliedLetters,
  validateNumberEntry,
} from "../src/games/cyl.js";

test("letter validation folds vowel accents while dictionary lookup keeps accents", () => {
  assert.equal(
    usesSuppliedLetters(" camión ", ["C", "A", "M", "I", "O", "N", "X", "Y", "Z"]),
    true
  );
  const dictionary = new Map([
    ["camión", { word: "camión", meaning: "vehículo", status: "OK" as const }],
  ]);
  const round = new LetterRound(["C", "A", "M", "I", "O", "N", "X", "Y", "Z"], (key) =>
    dictionary.get(key)
  );
  assert.equal(round.submit("u1", "Ana", "  CAMIÓN "), "retained");
  assert.equal(round.winners()[0]?.word, "CAMIÓN");
  assert.equal(round.winners()[0]?.score, scoreWord("CAMIÓN"));
  assert.equal(round.submit("u2", "Bea", "CAMION"), "rejected");
});

test("CYL inventory preserves Ñ as a distinct premium tile", () => {
  assert.equal(usesSuppliedLetters("AÑO", ["A", "N", "O"]), false);
  assert.equal(usesSuppliedLetters("AÑO", ["A", "Ñ", "O"]), true);
  assert.equal(usesSuppliedLetters("ANO", ["A", "Ñ", "O"]), false);
  assert.equal(usesSuppliedLetters("ÁÉÍÓÚÜ", ["A", "E", "I", "O", "U", "U"]), true);
  assert.equal(usesSuppliedLetters("Ć", ["C"]), false);

  const dictionary = new Map([["año", { word: "año", meaning: "periodo", status: "OK" as const }]]);
  const withoutEnye = new LetterRound(["A", "N", "O"], (key) => dictionary.get(key));
  assert.equal(withoutEnye.submit("u1", "Ana", "AÑO"), "rejected");
  assert.deepEqual(withoutEnye.winners(), []);

  const withEnye = new LetterRound(["A", "Ñ", "O"], (key) => dictionary.get(key));
  assert.equal(withEnye.submit("u1", "Ana", "AÑO"), "retained");
  assert.equal(withEnye.winners()[0]?.score, 100);
});

test("LetterRound distinguishes rejected, retained and stable top-three discard", () => {
  const dictionary = new Map(
    ["AAAA", "AAA", "AA", "ÁA"].map((word) => [
      word.toLocaleLowerCase("es-ES"),
      { word, meaning: null, status: "OK" as const },
    ])
  );
  const round = new LetterRound(["A", "A", "A", "A"], (key) => dictionary.get(key));
  assert.equal(round.submit("u1", "Ana", "AAAA"), "retained");
  assert.equal(round.submit("u2", "Bea", "AAA"), "retained");
  assert.equal(round.submit("u3", "Carla", "AA"), "retained");
  assert.equal(round.submit("u4", "Dora", "ÁA"), "discarded");
  assert.equal(round.submit("u5", "Eva", "ZZ"), "rejected");
  assert.deepEqual(
    round.winners().map((winner) => winner.identity),
    ["u1", "u2", "u3"]
  );
});

test("K has value 8 and word scores preserve legacy values", () => {
  assert.equal(CYL_K, 8);
  assert.equal(scoreWord("K"), 80);
  assert.equal(scoreWord("Ñ"), 80);
  assert.equal(scoreWord("CASA"), 60);
});

test("Cifras enforces exact inventory, allows subsets/fractions/powers, rejects dice and keeps distant zero winners", () => {
  const numbers = [1, 2, 3, 4, 5, 6];
  assert.equal(usesNumberInventory("(6/4)^2+1", numbers), true);
  assert.equal(usesNumberInventory("6+6", numbers), false);
  assert.equal(usesNumberInventory("20001-20000", [1, 2, 3, 4, 5, 6]), false);
  assert.equal(validateNumberEntry("6/4", numbers, 2)?.value, 1.5);
  assert.equal(validateNumberEntry("1d6", numbers, 6), undefined);
  assert.equal(scoreNumber(101), 0);
  const round = new NumberRound(numbers, 999);
  assert.equal(round.submit("u1", "Ana", "6"), true);
  assert.equal(round.winner()?.score, 0);
  assert.equal(round.submit("u2", "Bea", "6"), false);
});

test("legacy letter generator preserves vowel branch and cumulative consonant boundaries", () => {
  assert.equal(generateRandomVowel({ next: () => 0 }), "A");
  assert.equal(generateRandomVowel({ next: () => 43 / 44 }), "U");
  assert.equal(generateRandomLetter2({ next: () => 0 }), "A");
  const draws = [14.5 / 71, 0];
  assert.equal(generateRandomLetter2({ next: () => draws.shift() ?? 0 }), "R");
  assert.equal(generateRandomConsonant2({ next: () => 0 }), "R");
  assert.equal(generateRandomConsonant2({ next: () => 1 - Number.EPSILON }), "W");
});

test("number generation keeps inventory and target distributions", () => {
  let value = 0;
  const generated = generateNumbers({
    next: () => (value = (value + 0.137) % 1),
  });
  assert.equal(generated.numbers.length, 6);
  assert.ok(generated.target >= 101 && generated.target <= 999);
});
