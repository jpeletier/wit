const CONTROL = "\u0003";

export const mirc = {
  bold: (text: string): string => `\u0002${text}\u0002`,
  underline: (text: string): string => `\u001f${text}\u001f`,
  color: (text: string, foreground: number, background?: number): string =>
    `${CONTROL}${String(foreground).padStart(2, "0")}${background === undefined ? "" : `,${String(background).padStart(2, "0")}`}${text}${CONTROL}`,
};

export function vbRound(value: number): number {
  if (!Number.isFinite(value))
    throw new RangeError("Cannot round a non-finite value");
  const floor = Math.floor(value);
  const fraction = value - floor;
  if (Math.abs(fraction - 0.5) < Number.EPSILON * Math.max(1, Math.abs(value)))
    return floor % 2 === 0 ? floor : floor + 1;
  return Math.round(value);
}

export function definitionExcerpt(value: string, limit = 100): string {
  const normalized = value.replaceAll("\u0002", " || ");
  return normalized.length > limit
    ? `${normalized.slice(0, limit)} ...`
    : normalized;
}
