import assert from "node:assert/strict";
import test from "node:test";
import {
  formatMadridDisplayDateTime,
  formatMadridSqlDateTime,
  madridDateTimeParts,
} from "../src/core/time.js";

test("Madrid wall time applies winter and summer offsets with milliseconds", () => {
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-01-15T12:04:05.006Z")),
    "2026-01-15T13:04:05.006"
  );
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-07-15T12:04:05.006Z")),
    "2026-07-15T14:04:05.006"
  );
});

test("Madrid wall time handles both DST transition boundaries", () => {
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-03-29T00:59:59.999Z")),
    "2026-03-29T01:59:59.999"
  );
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-03-29T01:00:00.000Z")),
    "2026-03-29T03:00:00.000"
  );
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-10-25T00:59:59.999Z")),
    "2026-10-25T02:59:59.999"
  );
  assert.equal(
    formatMadridSqlDateTime(new Date("2026-10-25T01:00:00.000Z")),
    "2026-10-25T02:00:00.000"
  );
});

test("Madrid calendar handles leap, month and year boundaries", () => {
  assert.equal(
    formatMadridSqlDateTime(new Date("2024-02-29T22:59:59.999Z")),
    "2024-02-29T23:59:59.999"
  );
  assert.deepEqual(madridDateTimeParts(new Date("2024-02-29T23:00:00Z")), {
    year: 2024,
    month: 3,
    day: 1,
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
  });
  assert.equal(
    formatMadridSqlDateTime(new Date("2025-12-31T23:00:00Z")),
    "2026-01-01T00:00:00.000"
  );
});

test("Madrid format rejects invalid dates and labels display output", () => {
  assert.throws(() => formatMadridSqlDateTime(new Date(Number.NaN)), /Invalid/u);
  assert.equal(
    formatMadridDisplayDateTime(new Date("2026-08-05T00:00:00.123Z")),
    "2026-08-05 02:00:00.123 (Europe/Madrid)"
  );
});
