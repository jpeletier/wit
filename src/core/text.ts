export function lookupKey(value: string): string {
  return value.normalize("NFC").toLocaleLowerCase("es-ES");
}

export function ircCasefold(
  value: string,
  mapping: "ascii" | "rfc1459" | "strict-rfc1459" = "rfc1459",
): string {
  let folded = value.toLowerCase();
  if (mapping !== "ascii")
    folded = folded
      .replaceAll("[", "{")
      .replaceAll("]", "}")
      .replaceAll("\\", "|");
  if (mapping === "rfc1459") folded = folded.replaceAll("^", "~");
  return folded;
}

export function repairMojibake(value: string): {
  value: string;
  proposed: boolean;
  applied: boolean;
} {
  if (!/[ÃÂâ€]/u.test(value) || /[\0-\x08\x0b\x0c\x0e-\x1f]/u.test(value)) {
    return { value, proposed: false, applied: false };
  }
  const cp1252: Record<string, number> = {
    "€": 0x80,
    "‚": 0x82,
    ƒ: 0x83,
    "„": 0x84,
    "…": 0x85,
    "†": 0x86,
    "‡": 0x87,
    ˆ: 0x88,
    "‰": 0x89,
    Š: 0x8a,
    "‹": 0x8b,
    Œ: 0x8c,
    Ž: 0x8e,
    "‘": 0x91,
    "’": 0x92,
    "“": 0x93,
    "”": 0x94,
    "•": 0x95,
    "–": 0x96,
    "—": 0x97,
    "˜": 0x98,
    "™": 0x99,
    š: 0x9a,
    "›": 0x9b,
    œ: 0x9c,
    ž: 0x9e,
    Ÿ: 0x9f,
  };
  const encoded = [...value].map((character) => {
    const point = character.codePointAt(0) ?? 0;
    return point <= 255 ? point : cp1252[character];
  });
  if (encoded.some((byte) => byte === undefined)) {
    return { value, proposed: false, applied: false };
  }
  const bytes = Uint8Array.from(encoded as number[]);
  let candidate: string;
  try {
    candidate = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    return { value, proposed: false, applied: false };
  }
  const reversible = [...new TextEncoder().encode(candidate)].every(
    (byte, index) => byte === bytes[index],
  );
  const before = (value.match(/[ÃÂâ€]/gu) ?? []).length;
  const after = (candidate.match(/[ÃÂâ€]/gu) ?? []).length;
  const applied = reversible && after < before;
  return {
    value: applied ? candidate.normalize("NFC") : value,
    proposed: reversible,
    applied,
  };
}
