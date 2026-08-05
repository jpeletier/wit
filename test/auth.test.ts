import assert from "node:assert/strict";
import test from "node:test";
import {
  buildClientOptions,
  buildServiceAuthCommand,
} from "../src/irc/auth.js";

test("client options map server PASS and SASL PLAIN without inferred NickServ", () => {
  assert.deepEqual(
    buildClientOptions({
      nick: "Wit",
      serverPassword: "server secret",
      accountAuth: {
        method: "sasl",
        username: "wit-account",
        password: "account secret",
      },
    }),
    {
      nick: "Wit",
      bot: true,
      reconnect: false,
      ctcpReplies: { version: "Wit TypeScript" },
      serverPassword: "server secret",
      authMethod: "sasl",
      username: "wit-account",
      password: "account secret",
    },
  );
  const unauthenticated = buildClientOptions({ nick: "Wit" });
  assert.equal("password" in unauthenticated, false);
  assert.equal("authMethod" in unauthenticated, false);
});

test("service auth builder requires an explicit safe target and defaults IDENTIFY", () => {
  assert.deepEqual(
    buildServiceAuthCommand({
      target: "AuthServ@services.example",
      account: "wit-account",
      password: "service-secret",
    }),
    {
      target: "AuthServ@services.example",
      text: "IDENTIFY wit-account service-secret",
    },
  );
  assert.equal(buildServiceAuthCommand(undefined), undefined);
  assert.throws(
    () => buildServiceAuthCommand({ target: "", password: "secret" }),
    /configuration is invalid/u,
  );
  assert.throws(
    () =>
      buildServiceAuthCommand({
        target: "Auth Serv",
        command: "IDENTIFY\nOPER",
        password: "secret",
      }),
    /configuration is invalid/u,
  );
  assert.throws(
    () =>
      buildServiceAuthCommand({
        target: "AuthServ",
        password: "service secret",
      }),
    /configuration is invalid/u,
  );
});
