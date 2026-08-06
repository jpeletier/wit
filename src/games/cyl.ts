import { calculate } from "../core/expression.js";
import { definitionExcerpt, vbRound } from "../core/format.js";
import { lookupKey } from "../core/text.js";
import type { RandomSource } from "../core/ports.js";
import { randomInt } from "../core/ports.js";

export const CYL_K = 8;
export interface DictionaryWord {
  word: string;
  meaning: string | null;
  status: "OK" | "NF";
}
export interface LetterWinner {
  identity: string;
  nick: string;
  word: string;
  entry: DictionaryWord;
  score: number;
}
export interface NumberWinner {
  identity: string;
  nick: string;
  expression: string;
  value: number;
  distance: number;
  score: number;
}
export type LetterSubmissionOutcome = "rejected" | "retained" | "discarded";

const vowels = "AAAAAAAAAAAAEEEEEEEEEEEEIIIIIIOOOOOOOOOUUUUU";
const mixedVowels = "AAAEEEEIIOOOUU";
const consonantOrder = "RNCLTSDMPBGHFVZJÑQYXKW";
const consonantCumulative = [
  43437, 67852, 91954, 114851, 135974, 153959, 171451, 183862, 194558, 203833, 212505, 217725,
  222918, 227602, 231801, 235788, 237499, 239195, 240273, 241027, 241093, 241110,
];

export function generateRandomVowel(random: RandomSource): string {
  return vowels[Math.floor(random.next() * 44)]!;
}

export function generateRandomConsonant2(random: RandomSource): string {
  const draw = Math.floor(random.next() * 221110) + 20001;
  const index = consonantCumulative.findIndex((limit) => draw <= limit);
  return consonantOrder[index < 0 ? consonantOrder.length - 1 : index]!;
}

export function generateRandomLetter2(random: RandomSource): string {
  const position = Math.floor(random.next() * 71) + 1;
  return position < 15 ? mixedVowels[position - 1]! : generateRandomConsonant2(random);
}

export function generateLetters(random: RandomSource): string[] {
  return [
    ...Array.from({ length: 3 }, () => generateRandomVowel(random)),
    ...Array.from({ length: 6 }, () => generateRandomLetter2(random)),
  ];
}

export function generateNumbers(random: RandomSource): {
  numbers: number[];
  target: number;
} {
  const pool = [
    ...Array.from({ length: 2 }, () => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).flat(),
    25,
    50,
    75,
    100,
  ];
  const numbers: number[] = [];
  while (numbers.length < 6) {
    numbers.push(pool.splice(randomInt(random, 0, pool.length - 1), 1)[0]!);
  }
  return { numbers, target: randomInt(random, 101, 999) };
}

export function usesSuppliedLetters(word: string, letters: readonly string[]): boolean {
  const available = letters.map(foldCylTile);
  return [...word.trim().normalize("NFC")].every((character) => {
    const index = available.indexOf(foldCylTile(character));
    if (index < 0) {
      return false;
    }
    available.splice(index, 1);
    return true;
  });
}

function foldCylTile(character: string): string {
  const normalized = character.normalize("NFC").toUpperCase();
  const vowelFolds: Record<string, string> = {
    Á: "A",
    É: "E",
    Í: "I",
    Ó: "O",
    Ú: "U",
    Ü: "U",
  };
  return vowelFolds[normalized] ?? normalized;
}

export function usedNumbers(expression: string): number[] {
  return [...expression.matchAll(/\d+(?:[.,]\d+)?/gu)].map((match) =>
    Number(match[0]!.replace(",", "."))
  );
}

export function usesNumberInventory(expression: string, numbers: readonly number[]): boolean {
  const available = [...numbers];
  return usedNumbers(expression).every((number) => {
    if (number > 20_000) {
      return false;
    }
    const index = available.indexOf(number);
    if (index < 0) {
      return false;
    }
    available.splice(index, 1);
    return true;
  });
}

export function scoreNumber(distance: number): number {
  if (distance === 0) {
    return 200;
  }
  return distance < 100 ? vbRound(101 - distance) : 0;
}

export function scoreWord(word: string): number {
  const values: Record<string, number> = {
    A: 1,
    B: 3,
    C: 3,
    D: 2,
    E: 1,
    F: 4,
    G: 2,
    H: 4,
    I: 1,
    J: 8,
    K: CYL_K,
    L: 1,
    M: 3,
    N: 1,
    Ñ: 8,
    O: 1,
    P: 3,
    Q: 5,
    R: 1,
    S: 1,
    T: 1,
    U: 1,
    V: 4,
    W: 18,
    X: 8,
    Y: 10,
    Z: 10,
  };
  const characters = [
    ...word
      .normalize("NFD")
      .toUpperCase()
      .replaceAll(/(?<!N)\p{M}/gu, "")
      .normalize("NFC"),
  ];
  const sum = characters.reduce((total, character) => total + (values[character] ?? 0), 0);
  return sum * 10 * (characters.length >= 9 ? 2 : 1);
}

export function validateNumberEntry(
  expression: string,
  numbers: readonly number[],
  target: number
): Omit<NumberWinner, "identity" | "nick"> | undefined {
  if (!usesNumberInventory(expression, numbers)) {
    return undefined;
  }
  try {
    const value = calculate(expression, { dice: false });
    if (value < 0) {
      return undefined;
    }
    const distance = Math.abs(value - target);
    return { expression, value, distance, score: scoreNumber(distance) };
  } catch {
    return undefined;
  }
}

export class LetterRound {
  #winners: LetterWinner[] = [];
  constructor(
    readonly letters: readonly string[],
    private readonly lookup: (key: string) => DictionaryWord | undefined
  ) {}

  submit(identity: string, nick: string, raw: string): LetterSubmissionOutcome {
    const word = raw.trim();
    if (word.length <= 1 || !usesSuppliedLetters(word, this.letters)) {
      return "rejected";
    }
    const entry = this.lookup(lookupKey(word));
    if (entry === undefined || (entry.status !== "OK" && entry.status !== "NF")) {
      return "rejected";
    }
    if (this.#winners.some((winner) => lookupKey(winner.word) === lookupKey(word))) {
      return "rejected";
    }
    const previous = this.#winners.find((winner) => winner.identity === identity);
    if (previous !== undefined && [...previous.word].length >= [...word].length) {
      return "rejected";
    }
    this.#winners = this.#winners.filter((winner) => winner.identity !== identity);
    const candidate = { identity, nick, word, entry, score: 0 };
    this.#winners.push(candidate);
    this.#winners.sort((left, right) => [...right.word].length - [...left.word].length);
    this.#winners = this.#winners.slice(0, 3);
    this.#winners.forEach((winner, index) => {
      winner.score = vbRound(scoreWord(winner.word) / 2 ** index);
    });
    return this.#winners.includes(candidate) ? "retained" : "discarded";
  }

  winners(): readonly LetterWinner[] {
    return this.#winners;
  }
  definition(): string | undefined {
    const meaning = this.#winners[0]?.entry.meaning;
    return meaning === null || meaning === undefined || meaning === ""
      ? undefined
      : definitionExcerpt(meaning);
  }
}

export class NumberRound {
  #winner?: NumberWinner;
  constructor(
    readonly numbers: readonly number[],
    readonly target: number
  ) {}
  submit(identity: string, nick: string, expression: string): boolean {
    const result = validateNumberEntry(expression, this.numbers, this.target);
    if (
      result === undefined ||
      (this.#winner !== undefined && result.distance >= this.#winner.distance)
    ) {
      return false;
    }
    this.#winner = { identity, nick, ...result };
    return true;
  }
  winner(): NumberWinner | undefined {
    return this.#winner;
  }
}
