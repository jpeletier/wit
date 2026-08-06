import assert from "node:assert/strict";
import test from "node:test";
import { calculate } from "../src/core/expression.js";
import { definitionExcerpt, mirc, sanitizeIrcText, vbRound } from "../src/core/format.js";
import { lookupKey, repairMojibake } from "../src/core/text.js";

test("safe calculator supports precedence, powers, parentheses, decimals and dice", () => {
  assert.equal(calculate("2+3*4"), 14);
  assert.equal(calculate("(2+3)^2/2"), 12.5);
  assert.equal(calculate("1,5 + .5"), 2);
  assert.equal(calculate("2d6", { random: () => 0 }), 2);
  assert.throws(() => calculate("2d6", { dice: false }));
  assert.throws(() => calculate("globalThis.process.exit()"));
  assert.equal(calculate("2^3^2"), 64);
  assert.throws(() => calculate("1+2+3+4+5+6+7+8+9+10+11+12+13+14+15+16+17+18+19+20+21"));
  assert.throws(() => calculate("(((((((((((1)))))))))))"));
});

test("VB banker rounding and mIRC controls are preserved", () => {
  assert.equal(vbRound(2.5), 2);
  assert.equal(vbRound(3.5), 4);
  assert.equal(vbRound(-1.5), -2);
  assert.equal(mirc.bold("x"), "\u0002x\u0002");
  assert.equal(mirc.color("x", 5), "\u00035x\u0003");
});

test("mIRC reset spacer survives irc-client-ts trailing whitespace serialization", () => {
  const serialized = `PRIVMSG #canal ${mirc.reset}`.trimEnd() + "\r\n";
  assert.equal(serialized, "PRIVMSG #canal \u000f\r\n");
  assert.notEqual(serialized, "PRIVMSG #canal\r\n");
  assert.equal(mirc.reset.replaceAll(/\p{C}/gu, ""), "");
  assert.equal(sanitizeIrcText(mirc.reset), mirc.reset);
});

test("IRC text sanitizer collapses unsafe separators and preserves Unicode and mIRC controls", () => {
  const controls = "\u0002\u0003\u000f\u0016\u001d\u001f";
  assert.equal(sanitizeIrcText(`á${controls}\r\n\0\n世界`), `á${controls} 世界`);
});

test("definition excerpts sanitize and budget source before separator expansion", () => {
  assert.equal(definitionExcerpt("short", 10), "short");
  assert.equal(definitionExcerpt("12345678901", 10), "1234567890 ...");
  assert.equal(definitionExcerpt("12345\r\n\0\n67890", 10), "12345 6789 ...");
  assert.equal(definitionExcerpt("A\u0002B\u0002C", 4), "A || B ||  ...");
  assert.equal(definitionExcerpt("12\r\n\0\n34\u000256", 6), "12 34 ||  ...");
  assert.equal(definitionExcerpt("áé😊x", 3), "áé😊 ...");
});

test("lookup keys preserve accents and mojibake repair is strict and reversible", () => {
  assert.equal(lookupKey("ÁRBOL"), "árbol");
  assert.notEqual(lookupKey("papa"), lookupKey("papá"));
  assert.deepEqual(repairMojibake("EspaÃ±a"), {
    value: "España",
    proposed: true,
    applied: true,
  });
  assert.deepEqual(repairMojibake("control\0Ã±"), {
    value: "control\0Ã±",
    proposed: false,
    applied: false,
  });
  assert.deepEqual(repairMojibake("Ãÿ"), {
    value: "Ãÿ",
    proposed: false,
    applied: false,
  });
  assert.deepEqual(repairMojibake("Itâ€™s"), {
    value: "It’s",
    proposed: true,
    applied: true,
  });
  assert.equal(repairMojibake("texto normal").value, "texto normal");
});
