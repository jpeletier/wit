import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  loadConfig,
  MAX_CHANNEL_LENGTH,
  MAX_OUTBOUND_DELAY_MS,
  parseConfig,
  selectDatabasePath,
} from "../src/config.js";

function bot(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    nick: "Wit",
    server: "irc.example.net",
    port: 6697,
    networkId: 1,
    channels: ["#trivia"],
    ...overrides,
  };
}

function config(
  botOverrides: Record<string, unknown> = {},
  rootOverrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    database: "./db/wit.sqlite",
    bots: [bot(botOverrides)],
    ...rootOverrides,
  };
}

test("config parses and freezes minimal normalized output", () => {
  const raw = config();
  const parsed = parseConfig(raw);
  assert.equal(parsed.welcomeOnJoin, true);
  assert.equal(parsed.bots[0]?.tls, true);
  assert.deepEqual(parsed.bots[0]?.channels, ["#trivia"]);
  assert.equal(Object.isFrozen(parsed), true);
  assert.equal(Object.isFrozen(parsed.bots), true);
  assert.equal(Object.isFrozen(parsed.bots[0]), true);
  assert.equal(Object.isFrozen(parsed.bots[0]?.channels), true);
  (raw.bots as Array<Record<string, unknown>>)[0]!.channels = ["#changed"];
  assert.deepEqual(parsed.bots[0]?.channels, ["#trivia"]);
  assert.throws(() => {
    parsed.database = "changed";
  }, TypeError);
});

test("config accepts all documented fields and protocol boundaries", () => {
  const longestChannel = `#${"a".repeat(MAX_CHANNEL_LENGTH - 1)}`;
  const parsed = parseConfig(
    config(
      {
        nick: "Wit-2",
        server: "2001:db8::1",
        port: 65_535,
        tls: false,
        networkId: Number.MAX_SAFE_INTEGER,
        channels: [longestChannel, "&local", "+modeless", "!safe"],
        outboundDelayMs: MAX_OUTBOUND_DELAY_MS,
        serverPassword: "server password",
        accountAuth: {
          method: "sasl",
          username: "wit-account",
          password: "account password",
        },
        serviceAuth: {
          target: "AuthServ@services.example",
          command: "LOGIN",
          account: "wit-account",
          password: "service-secret",
        },
      },
      { welcomeOnJoin: false },
    ),
  );
  assert.equal(parsed.welcomeOnJoin, false);
  assert.equal(parsed.bots[0]?.tls, false);
  assert.equal(parsed.bots[0]?.port, 65_535);
  assert.equal(parsed.bots[0]?.outboundDelayMs, MAX_OUTBOUND_DELAY_MS);
  assert.equal(Object.isFrozen(parsed.bots[0]?.accountAuth), true);
  assert.equal(Object.isFrozen(parsed.bots[0]?.serviceAuth), true);
});

test("config rejects unknown keys with paths", () => {
  const cases: Array<[unknown, RegExp]> = [
    [config({}, { mystery: true }), /config\.mystery is not supported/u],
    [config({ mystery: true }), /config\.bots\[0\]\.mystery/u],
    [config({ password: "legacy" }), /config\.bots\[0\]\.password/u],
    [
      config({
        accountAuth: {
          method: "sasl",
          username: "user",
          password: "secret",
          extra: true,
        },
      }),
      /accountAuth\.extra/u,
    ],
    [
      config({
        serviceAuth: { target: "AuthServ", password: "secret", extra: true },
      }),
      /serviceAuth\.extra/u,
    ],
  ];
  for (const [raw, pattern] of cases)
    assert.throws(() => parseConfig(raw), pattern);
});

test("config rejects invalid root and bot field boundaries", () => {
  const longChannel = `#${"a".repeat(MAX_CHANNEL_LENGTH)}`;
  const multibyteChannel = `#${"ñ".repeat(MAX_CHANNEL_LENGTH / 2)}`;
  const cases: Array<[string, unknown, RegExp]> = [
    ["database", config({}, { database: " " }), /config\.database/u],
    ["database type", config({}, { database: 1 }), /config\.database/u],
    ["welcome", config({}, { welcomeOnJoin: "yes" }), /welcomeOnJoin/u],
    ["bots empty", config({}, { bots: [] }), /config\.bots/u],
    ["bot object", config({}, { bots: [null] }), /config\.bots\[0\]/u],
    ["nick empty", config({ nick: "" }), /\.nick/u],
    ["nick whitespace", config({ nick: "Bad Nick" }), /\.nick/u],
    ["nick comma", config({ nick: "Bad,Nick" }), /\.nick/u],
    ["nick leading colon", config({ nick: ":Wit" }), /\.nick/u],
    ["nick embedded colon", config({ nick: "Wit:Bot" }), /\.nick/u],
    ["server whitespace", config({ server: "irc example" }), /\.server/u],
    ["server comma", config({ server: "irc,example" }), /\.server/u],
    ["server control", config({ server: "irc\nexample" }), /\.server/u],
    ["port zero", config({ port: 0 }), /\.port/u],
    ["port high", config({ port: 65_536 }), /\.port/u],
    ["port fraction", config({ port: 1.5 }), /\.port/u],
    ["tls", config({ tls: "true" }), /\.tls/u],
    ["network zero", config({ networkId: 0 }), /\.networkId/u],
    ["network fraction", config({ networkId: 1.5 }), /\.networkId/u],
    [
      "network unsafe",
      config({ networkId: Number.MAX_SAFE_INTEGER + 1 }),
      /\.networkId/u,
    ],
    ["channels empty", config({ channels: [] }), /\.channels/u],
    ["channel prefix", config({ channels: ["trivia"] }), /channels\[0\]/u],
    [
      "channel whitespace",
      config({ channels: ["#bad name"] }),
      /channels\[0\]/u,
    ],
    ["channel comma", config({ channels: ["#bad,name"] }), /channels\[0\]/u],
    ["channel colon", config({ channels: ["#bad:name"] }), /channels\[0\]/u],
    ["channel control", config({ channels: ["#bad\0name"] }), /channels\[0\]/u],
    ["channel long", config({ channels: [longChannel] }), /channels\[0\]/u],
    [
      "channel multibyte",
      config({ channels: [multibyteChannel] }),
      /channels\[0\]/u,
    ],
    [
      "channel duplicate",
      config({ channels: ["#Trivia", "#trivia"] }),
      /channels\[1\].*duplicated/u,
    ],
    ["delay zero", config({ outboundDelayMs: 0 }), /outboundDelayMs/u],
    [
      "delay high",
      config({ outboundDelayMs: MAX_OUTBOUND_DELAY_MS + 1 }),
      /outboundDelayMs/u,
    ],
    ["delay fraction", config({ outboundDelayMs: 1.5 }), /outboundDelayMs/u],
  ];
  for (const [name, raw, pattern] of cases)
    assert.throws(() => parseConfig(raw), pattern, name);
});

test("config validates credentials without exposing secret values", () => {
  const secret = "do-not-print\nsecret";
  const cases: unknown[] = [
    config({ serverPassword: "" }),
    config({ serverPassword: "****" }),
    config({ serverPassword: secret }),
    config({
      accountAuth: { method: "sasl", username: "bad user", password: "secret" },
    }),
    config({
      accountAuth: { method: "sasl", username: "user", password: "****" },
    }),
    config({
      accountAuth: {
        method: "sasl",
        username: "user",
        password: "line\nbreak",
      },
    }),
    config({
      accountAuth: { method: "other", username: "user", password: "secret" },
    }),
    config({ serviceAuth: { target: "Auth Serv", password: "secret" } }),
    config({
      serviceAuth: {
        target: "AuthServ",
        command: "ID ENTIFY",
        password: "secret",
      },
    }),
    config({
      serviceAuth: {
        target: "AuthServ",
        account: "bad account",
        password: "secret",
      },
    }),
    config({ serviceAuth: { target: "AuthServ", password: "spaced secret" } }),
    config({ serviceAuth: { target: "AuthServ", password: "****" } }),
  ];
  for (const raw of cases) {
    const error = capture(() => parseConfig(raw));
    assert.ok(error instanceof Error);
    assert.equal(error.message.includes("do-not-print"), false);
    assert.match(error.message, /config\.bots\[0\]/u);
  }
});

test("config rejects conflicting bot identities and network channels", () => {
  const duplicate = config(
    {},
    { bots: [bot(), bot({ nick: "wIT", server: "IRC.EXAMPLE.NET" })] },
  );
  assert.throws(
    () => parseConfig(duplicate),
    /duplicates a connection identity/u,
  );
  const duplicateAssignment = config(
    {},
    { bots: [bot(), bot({ nick: "Other", channels: ["#TRIVIA"] })] },
  );
  assert.throws(
    () => parseConfig(duplicateAssignment),
    /duplicates a network\/channel assignment/u,
  );
  const sharedNetwork = config(
    {},
    { bots: [bot(), bot({ nick: "Other", channels: ["#other"] })] },
  );
  assert.equal(parseConfig(sharedNetwork).bots.length, 2);
  const separateNetworks = config(
    {},
    { bots: [bot(), bot({ nick: "Other", networkId: 2 })] },
  );
  assert.equal(parseConfig(separateNetworks).bots.length, 2);
});

test("loadConfig wraps read, JSON and validation errors with path and cause", () => {
  const directory = mkdtempSync(join(tmpdir(), "wit-config-"));
  const missing = join(directory, "missing.json");
  const malformed = join(directory, "malformed.json");
  const invalid = join(directory, "invalid.json");
  writeFileSync(malformed, "{ secret contents", "utf8");
  writeFileSync(
    invalid,
    JSON.stringify(config({ serverPassword: "****" })),
    "utf8",
  );
  try {
    for (const [path, pattern] of [
      [missing, /Unable to read config file/u],
      [malformed, /Invalid JSON in config file/u],
      [invalid, /Invalid configuration in/u],
    ] as const) {
      const error = capture(() => loadConfig(path));
      assert.ok(error instanceof Error);
      assert.match(error.message, pattern);
      assert.ok(error.message.includes(path));
      assert.ok(error.cause !== undefined);
      assert.equal(error.message.includes("secret contents"), false);
      assert.equal(error.message.includes("****"), false);
    }
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
});

test("database environment override must be a nonempty safe path", () => {
  assert.equal(
    selectDatabasePath("configured.sqlite", undefined),
    "configured.sqlite",
  );
  assert.equal(
    selectDatabasePath("configured.sqlite", "override.sqlite"),
    "override.sqlite",
  );
  assert.throws(
    () => selectDatabasePath("configured.sqlite", ""),
    /WIT_DATABASE/u,
  );
  assert.throws(
    () => selectDatabasePath("configured.sqlite", "  "),
    /WIT_DATABASE/u,
  );
  assert.throws(
    () => selectDatabasePath("configured.sqlite", "bad\0path"),
    /WIT_DATABASE/u,
  );
});

function capture(action: () => unknown): unknown {
  try {
    action();
  } catch (error) {
    return error;
  }
  throw new Error("Expected action to throw");
}
