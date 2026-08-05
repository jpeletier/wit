import { calculate } from "../core/expression.js";
import { vbRound } from "../core/format.js";
import type { Clock } from "../core/ports.js";

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
      answer: string;
      subjectId: number;
      seconds: number;
      points: number;
    }
  | { type: "timeout"; answer: string }
  | { type: "complete" };

export function answerWords(answer: string): string[] {
  return answer.split(" ").filter(Boolean);
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
): boolean {
  if (submitted.length >= 30) return false;
  try {
    return calculate(submitted, { dice: false, maxLength: 29 }) === expected;
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
  const base = stage < 35 ? 100 : stage < 45 ? 75 : 50;
  return vbRound(base * multiplier);
}

export class TriviaGame {
  #stage = 0;
  #index = -1;
  #question: TriviaQuestion | undefined;
  #numeric: number | undefined;
  #ended = false;
  #completePending = false;

  constructor(
    private readonly questions: readonly TriviaQuestion[],
    private readonly multiplier: number,
    private readonly clock: Clock,
  ) {
    if (questions.length < 1)
      throw new Error("Trivia requires at least one question");
  }

  get currentQuestion(): TriviaQuestion | undefined {
    return this.#question;
  }

  tick(): TriviaEvent[] {
    if (this.#ended) return [];
    if (this.#completePending) {
      this.#ended = true;
      return [{ type: "complete" }];
    }
    this.#stage++;
    if (this.#stage === 5) return [this.#startQuestion()];
    if (this.#stage === 35 || this.#stage === 45) {
      const level = this.#stage === 35 ? 1 : 2;
      return [{ type: "hint", level, text: this.#hint(level) }];
    }
    if (this.#stage === 55 && this.#question !== undefined) {
      const event: TriviaEvent = {
        type: "timeout",
        answer: this.#question.answer.trim(),
      };
      this.#question = undefined;
      this.#stage = 0;
      if (this.#index + 1 >= this.questions.length) this.#ended = true;
      return this.#ended ? [event, { type: "complete" }] : [event];
    }
    return [];
  }

  submit(nick: string, text: string): TriviaEvent | undefined {
    const question = this.#question;
    if (question === undefined || this.#stage <= 5) return undefined;
    const correct =
      this.#numeric === undefined
        ? matchesTriviaAnswer(question.answer.trim(), text)
        : matchesNumericAnswer(this.#numeric, text);
    if (!correct) return undefined;
    const points = triviaPoints(this.#stage, this.multiplier);
    const event: TriviaEvent = {
      type: "correct",
      nick,
      answer:
        this.#numeric === undefined
          ? question.answer.trim()
          : String(this.#numeric),
      subjectId: question.subjectId,
      seconds: this.#stage - 5,
      points,
    };
    this.#question = undefined;
    this.#stage = 0;
    if (this.#index + 1 >= this.questions.length) this.#completePending = true;
    return event;
  }

  #startQuestion(): TriviaEvent {
    this.#index++;
    const question = this.questions[this.#index];
    if (question === undefined) {
      this.#ended = true;
      return { type: "complete" };
    }
    const words = answerWords(question.answer.trim());
    if (words.length === 0 || words.length > 10)
      throw new Error(`Invalid answer word count for question ${question.id}`);
    this.#question = question;
    this.#numeric = words.length === 1 ? parseNumeric(words[0]!) : undefined;
    return {
      type: "question",
      question,
      number: this.#index + 1,
      total: this.questions.length,
      hint: this.#hint(0),
      words: words.length,
    };
  }

  #hint(level: 0 | 1 | 2): string {
    if (this.#question === undefined) return "";
    if (this.#numeric !== undefined)
      return numericHint(this.#numeric, level, this.clock.now().getTime());
    return answerWords(this.#question.answer.trim())
      .map((word) => hintWord(word, level))
      .join(" ");
  }
}

function parseNumeric(value: string): number | undefined {
  const normalized = value.replaceAll(",", ".").replaceAll("'", ".");
  if (
    normalized.length >= 30 ||
    !/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/u.test(normalized)
  )
    return undefined;
  const result = Number(normalized);
  return Number.isFinite(result) ? result : undefined;
}

function numericHint(answer: number, level: 0 | 1 | 2, seed: number): string {
  const spread = level === 0 ? 30 : level === 1 ? 20 : 10;
  const fraction = ((seed % 997) + 1) / 998;
  const left = answer - fraction * spread;
  const right = answer + (1 - fraction / 2) * spread;
  const format = (value: number): string =>
    Number.isInteger(answer)
      ? String(Math.floor(value))
      : value.toFixed(2).replace(/0+$/u, "").replace(/\.$/u, "");
  return `El número está entre ${format(left)} y ${format(right)}`;
}
