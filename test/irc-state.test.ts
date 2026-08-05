import assert from "node:assert/strict";
import test from "node:test";
import { FakeIrcPort, IrcMembershipState } from "../src/irc/port.js";

test("IRC state casefolds channels for joins and operator lookup", () => {
  const state = new IrcMembershipState("rfc1459");
  state.join("#Foo[Bar]");
  state.setMembers("#foo{bar}", [{ nick: "Op^", prefix: "@" }]);
  assert.equal(state.isJoined("#FOO{BAR}"), true);
  assert.equal(state.isOperator("#Foo[Bar]", "op~"), true);
  state.rename("op~", "NewOp");
  assert.equal(state.isOperator("#foo{bar}", "newop"), true);
});

test("fake adapter tracks self join, part, kick and disconnect", () => {
  const irc = new FakeIrcPort();
  const self = { identity: "bot", nick: "Wit" };
  irc.emit({ type: "join", channel: "#One", user: self, self: true });
  assert.equal(irc.isJoined("#one"), true);
  irc.emit({
    type: "kick",
    channel: "#ONE",
    user: { identity: "op", nick: "Op" },
    kickedNick: "Wit",
    self: true,
  });
  assert.equal(irc.isJoined("#one"), false);
  irc.emit({ type: "join", channel: "#Two", user: self, self: true });
  irc.emit({ type: "disconnected" });
  assert.deepEqual(irc.joinedChannels, []);
});
