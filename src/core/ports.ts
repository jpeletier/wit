export interface Clock {
  now(): Date;
}

export interface RandomSource {
  next(): number;
}

export const systemClock: Clock = { now: () => new Date() };
export const systemRandom: RandomSource = { next: () => Math.random() };

export function randomInt(random: RandomSource, min: number, max: number): number {
  return Math.floor(random.next() * (max - min + 1)) + min;
}
