import { calculate } from "../core/expression.js";
import { mirc, sanitizeIrcText, vbRound } from "../core/format.js";
import type { RandomSource } from "../core/ports.js";

export interface TriviaQuestion {
  id: number;
  text: string;
  answer: string;
  subjectId: number;
  subject: string;
  author: string;
}

export type TriviaEvent =
  | {
      type: "question";
      question: TriviaQuestion;
      number: number;
      total: number;
      hint: string;
      words: number;
    }
  | { type: "hint"; level: 1 | 2; text: string }
  | {
      type: "correct";
      nick: string;
      submitted: string;
      answer: string;
      answerType: "text" | "numeric";
      question: TriviaQuestion;
      seconds: number;
      points: number;
    }
  | { type: "timeout"; question: TriviaQuestion }
  | { type: "complete" };

export function answerWords(answer: string): string[] {
  return answer.split(" ").filter(Boolean);
}

export function normalizeTriviaAnswer(value: string): string {
  const tokens: string[] = [];
  for (const rawLine of value.split(/\r\n?|\n/gu)) {
    const line = sanitizeIrcText(rawLine)
      .trim()
      .replaceAll(/[ \t]+/gu, " ");
    if (line === "") continue;
    const lineTokens = line.split(" ");
    if (
      tokens.length > 0 &&
      tokens.at(-1)?.toLocaleLowerCase("es-ES") ===
        lineTokens[0]?.toLocaleLowerCase("es-ES")
    )
      lineTokens.shift();
    tokens.push(...lineTokens);
  }
  return tokens.join(" ");
}

export function matchesTriviaAnswer(
  expected: string,
  submitted: string,
): boolean {
  const words = answerWords(expected);
  if (words.length === 0 || words.length > 10) return false;
  const available = answerWords(submitted.toLocaleLowerCase("es-ES"));
  return words
    .map((word) => word.toLocaleLowerCase("es-ES"))
    .every((word) => {
      const index = available.indexOf(word);
      if (index < 0) return false;
      available.splice(index, 1);
      return true;
    });
}

export function matchesNumericAnswer(
  expected: number,
  submitted: string,
  random: RandomSource,
): boolean {
  if (submitted.length >= 30) return false;
  try {
    return (
      calculate(submitted, {
        dice: true,
        maxLength: 29,
        random: () => random.next(),
      }) === expected
    );
  } catch {
    return false;
  }
}

export function hintWord(word: string, level: 0 | 1 | 2): string {
  const characters = [...word];
  return characters
    .map((character, index) => {
      if (
        (level >= 1 && index === 0) ||
        (level === 2 && index === characters.length - 1)
      )
        return character;
      return /^[A-Za-z0-9ñÑ]$/u.test(character) ? "-" : character;
    })
    .join("");
}

export function triviaPoints(stage: number, multiplier: number): number {
  return vbRound((stage < 35 ? 100 : stage < 45 ? 75 : 50) * multiplier);
}

export function numericHint(
  answer: number,
  level: 0 | 1 | 2,
  random: RandomSource,
): string {
  const spread = level === 0 ? 30 : level === 1 ? 20 : 10;
  let left = answer - random.next() * spread;
  let right = answer + random.next() * spread;
  if (Number.isInteger(answer)) {
    left = Math.floor(left);
    right = Math.floor(right);
  }
  const format = (value: number): string =>
    Number.isInteger(answer)
      ? String(value)
      : value.toFixed(2).replace(/0+$/u, "").replace(/\.$/u, "");
  return `El número está entre${mirc.color(` ${format(left)}`, 6)} y${mirc.color(` ${format(right)}`, 6)}`;
}

export class TriviaGame {
  #stage = 0;
  #questionCount = 0;
  #question: TriviaQuestion | undefined;
  #numeric: number | undefined;
  #ended = false;

  constructor(
    private readonly total: number,
    private readonly multiplier: number,
    private readonly nextQuestion: () => TriviaQuestion,
    private readonly random: RandomSource,
  ) {
    if (total < 1) throw new Error("Trivia requires at least one question");
  }

  get stage(): number {
    return this.#stage;
  }
  get currentQuestion(): TriviaQuestion | undefined {
    return this.#question;
  }

  tick(): TriviaEvent[] {
    if (this.#ended) return [];
    const events: TriviaEvent[] = [];
    if (this.#stage === 1 && this.#questionCount >= this.total) {
      this.#ended = true;
      return [{ type: "complete" }];
    }
    if (this.#stage === 5) events.push(this.#startQuestion());
    else if (this.#stage === 35 || this.#stage === 45) {
      const level = this.#stage === 35 ? 1 : 2;
      events.push({ type: "hint", level, text: this.#hint(level) });
    } else if (this.#stage === 55 && this.#question !== undefined) {
      events.push({ type: "timeout", question: this.#question });
      this.#question = undefined;
      this.#numeric = undefined;
      this.#stage = 0;
    }
    this.#stage++;
    return events;
  }

  submit(nick: string, text: string): TriviaEvent | undefined {
    const question = this.#question;
    if (question === undefined || this.#stage <= 5) return undefined;
    const correct =
      this.#numeric === undefined
        ? matchesTriviaAnswer(question.answer.trim(), text)
        : matchesNumericAnswer(this.#numeric, text, this.random);
    if (!correct) return undefined;
    const event: TriviaEvent = {
      type: "correct",
      nick,
      submitted: text,
      answerType: this.#numeric === undefined ? "text" : "numeric",
      answer:
        this.#numeric === undefined
          ? question.answer.trim()
          : String(this.#numeric),
      question,
      seconds: this.#stage - 5,
      points: triviaPoints(this.#stage, this.multiplier),
    };
    this.#question = undefined;
    this.#numeric = undefined;
    this.#stage = 0;
    return event;
  }

  #startQuestion(): TriviaEvent {
    this.#questionCount++;
    let question: TriviaQuestion | undefined;
    for (let attempts = 0; attempts < 1_000; attempts++) {
      const candidate = this.nextQuestion();
      const answer = normalizeTriviaAnswer(candidate.answer);
      const words = answerWords(answer);
      if (words.length > 0 && words.length <= 10) {
        question = {
          ...candidate,
          text: sanitizeIrcText(candidate.text),
          answer,
        };
        break;
      }
    }
    if (question === undefined)
      throw new Error("No hay preguntas utilizables después de 1000 intentos");
    const words = answerWords(question.answer.trim());
    this.#question = question;
    this.#numeric = words.length === 1 ? parseNumeric(words[0]!) : undefined;
    return {
      type: "question",
      question,
      number: this.#questionCount,
      total: this.total,
      hint: this.#hint(0),
      words: words.length,
    };
  }

  #hint(level: 0 | 1 | 2): string {
    if (this.#question === undefined) return "";
    if (this.#numeric !== undefined)
      return numericHint(this.#numeric, level, this.random);
    return `${answerWords(this.#question.answer.trim())
      .map((word) => hintWord(word, level))
      .join(" ")} `;
  }
}

function parseNumeric(value: string): number | undefined {
  const normalized = value.replaceAll(",", ".").replaceAll("'", ".");
  if (
    normalized.length >= 30 ||
    !/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/u.test(normalized)
  )
    return undefined;
  const result = Number(normalized);
  return Number.isFinite(result) ? result : undefined;
}
