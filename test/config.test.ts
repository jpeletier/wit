import assert from "node:assert/strict";
import test from "node:test";
import { parseConfig } from "../src/config.js";

function config(bot: Record<string, unknown>): Record<string, unknown> {
  return {
    database: "./db/wit.sqlite",
    bots: [
      {
        nick: "Wit",
        server: "irc.example.net",
        port: 6697,
        tls: true,
        networkId: 1,
        channels: ["#trivia"],
        ...bot,
      },
    ],
  };
}

test("config parses explicit server, SASL PLAIN and service authentication", () => {
  const parsed = parseConfig(
    config({
      serverPassword: "server secret",
      accountAuth: {
        method: "sasl",
        username: "wit-account",
        password: "account secret",
      },
      serviceAuth: {
        target: "AuthServ@services.example",
        command: "LOGIN",
        account: "wit-account",
        password: "service-secret",
      },
    }),
  );
  assert.equal(parsed.bots[0]?.serverPassword, "server secret");
  assert.deepEqual(parsed.bots[0]?.accountAuth, {
    method: "sasl",
    username: "wit-account",
    password: "account secret",
  });
  assert.deepEqual(parsed.bots[0]?.serviceAuth, {
    target: "AuthServ@services.example",
    command: "LOGIN",
    account: "wit-account",
    password: "service-secret",
  });
});

test("config clearly rejects unsupported account authentication methods", () => {
  assert.throws(
    () => parseConfig(config({ accountAuth: { method: "unsupported" } })),
    /accountAuth method is unsupported/u,
  );
});

test("config never infers service auth and rejects legacy generic password", () => {
  const parsed = parseConfig(config({}));
  assert.equal(parsed.bots[0]?.serviceAuth, undefined);
  assert.throws(
    () => parseConfig(config({ password: "legacy-secret" })),
    /password is unsupported/u,
  );
});

test("config rejects incomplete or unsafe explicit service authentication", () => {
  for (const serviceAuth of [
    { password: "secret" },
    { target: "Auth Serv", password: "secret" },
    { target: "AuthServ", command: "ID ENTIFY", password: "secret" },
    {
      target: "AuthServ",
      account: "bad account",
      password: "secret",
    },
    { target: "AuthServ", password: "line\nbreak" },
    { target: "AuthServ", password: "spaced secret" },
    { target: "AuthServ", password: "" },
  ])
    assert.throws(
      () => parseConfig(config({ serviceAuth })),
      /serviceAuth is invalid/u,
    );
});
