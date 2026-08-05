export const LEGACY_TIME_ZONE = "Europe/Madrid";

export interface MadridDateTimeParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
  millisecond: number;
}

const madridFormatter = new Intl.DateTimeFormat("en-CA", {
  timeZone: LEGACY_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});

export function madridDateTimeParts(date: Date): MadridDateTimeParts {
  if (!Number.isFinite(date.getTime())) throw new RangeError("Invalid date");
  const parts = Object.fromEntries(
    madridFormatter
      .formatToParts(date)
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, Number(part.value)]),
  ) as Record<string, number>;
  return {
    year: parts.year!,
    month: parts.month!,
    day: parts.day!,
    hour: parts.hour!,
    minute: parts.minute!,
    second: parts.second!,
    millisecond: date.getUTCMilliseconds(),
  };
}

export function formatMadridSqlDateTime(date: Date): string {
  const parts = madridDateTimeParts(date);
  const two = (value: number): string => String(value).padStart(2, "0");
  return `${String(parts.year).padStart(4, "0")}-${two(parts.month)}-${two(parts.day)}T${two(parts.hour)}:${two(parts.minute)}:${two(parts.second)}.${String(parts.millisecond).padStart(3, "0")}`;
}

export function formatMadridDisplayDateTime(date: Date): string {
  return `${formatMadridSqlDateTime(date).replace("T", " ")} (${LEGACY_TIME_ZONE})`;
}
