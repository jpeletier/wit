import assert from "node:assert/strict";
import test from "node:test";
import {
  FakeIrcPort,
  IrcIdentityTracker,
  IrcMembershipState,
  IrcPresenceCoordinator,
} from "../src/irc/port.js";

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

test("identity tracker is stable for one mask and replaces a missed recycled nick", () => {
  const tracker = new IrcIdentityTracker((nick) => nick.toLowerCase());
  const firstMask = { user: "first", host: "bouncer.example" };
  const secondMask = { user: "second", host: "bouncer.example" };
  const first = tracker.resolve("Ana", firstMask);
  assert.equal(tracker.resolve("ANA", firstMask), first);
  assert.notEqual(tracker.resolve("Bea", firstMask), first);
  assert.notEqual(tracker.resolve("Ana", secondMask), first);
});

test("presence coordinator forgets QUIT and recycled nick identity", () => {
  const { tracker, membership, presence } = presenceFixture("#one");
  const mask = { user: "shared", host: "bouncer.example" };
  presence.join("#one", "Ana");
  const first = tracker.resolve("Ana", mask);
  presence.quit("Ana");
  assert.equal(membership.hasMember("Ana"), false);
  assert.notEqual(tracker.resolve("Ana", mask), first);
});

test("one-channel PART and KICK forget departed identities", () => {
  for (const departure of ["part", "kick"] as const) {
    const { tracker, presence } = presenceFixture("#one");
    const mask = { user: departure, host: "example.test" };
    presence.join("#one", "Ana");
    const first = tracker.resolve("Ana", mask);
    presence[departure]("#one", "Ana");
    assert.notEqual(tracker.resolve("Ana", mask), first);
  }
});

test("multi-channel PART retains identity until the final shared channel", () => {
  const { tracker, presence } = presenceFixture("#one", "#two");
  const mask = { user: "shared", host: "example.test" };
  presence.join("#one", "Ana");
  presence.join("#two", "Ana");
  const first = tracker.resolve("Ana", mask);
  presence.part("#one", "Ana");
  assert.equal(tracker.resolve("Ana", mask), first);
  presence.part("#two", "Ana");
  assert.notEqual(tracker.resolve("Ana", mask), first);
});

test("one-channel closure forgets identities from that channel", () => {
  const { tracker, membership, presence } = presenceFixture("#one");
  const mask = { user: "shared", host: "example.test" };
  presence.join("#one", "Ana");
  tracker.resolve("Ana", mask);
  assert.equal(tracker.trackedCount, 1);
  membership.setMembers("#one", []);
  presence.leaveChannel("#one");
  assert.equal(membership.isJoined("#one"), false);
  assert.equal(tracker.trackedCount, 0);
});

test("channel closure retains identities present in another shared channel", () => {
  const { tracker, membership, presence } = presenceFixture("#one", "#two");
  const mask = { user: "shared", host: "example.test" };
  presence.join("#one", "Ana");
  presence.join("#two", "Ana");
  const identity = tracker.resolve("Ana", mask);
  membership.setMembers("#one", []);
  presence.leaveChannel("#one");
  assert.equal(membership.isJoined("#one"), false);
  assert.equal(membership.isJoined("#two"), true);
  assert.equal(tracker.trackedCount, 1);
  assert.equal(tracker.resolve("Ana", mask), identity);
});

test("NICK transfers identity and presence", () => {
  const { tracker, membership, presence } = presenceFixture("#one");
  const mask = { user: "shared", host: "example.test" };
  presence.join("#one", "Ana");
  const first = tracker.resolve("Ana", mask);
  assert.equal(presence.rename("Ana", "Carla", mask), first);
  assert.equal(membership.hasMember("Ana"), false);
  assert.equal(membership.hasMember("Carla"), true);
  assert.equal(tracker.resolve("Carla", mask), first);
});

test("disconnect clear and JOIN/QUIT churn release tracked identities", () => {
  const { tracker, membership, presence } = presenceFixture("#one");
  const mask = { user: "shared", host: "example.test" };
  const first = tracker.resolve("Ana", mask);
  for (let index = 0; index < 100; index++) {
    const nick = `User${index}`;
    presence.join("#one", nick);
    tracker.resolve(nick, { user: nick, host: "example.test" });
    presence.quit(nick);
  }
  assert.equal(tracker.trackedCount, 1);
  presence.clear();
  assert.equal(tracker.trackedCount, 0);
  assert.deepEqual(membership.joinedChannels(), []);
  assert.notEqual(tracker.resolve("Ana", mask), first);
});

test("fake adapter sanitizes all outbound message and notice text", () => {
  const irc = new FakeIrcPort();
  irc.say("#c", "mensaje\r\n\0seguro");
  irc.notice("Ana", "aviso\nseguro");
  assert.deepEqual(
    irc.sent.map((entry) => entry.text),
    ["mensaje seguro", "aviso seguro"],
  );
});

function presenceFixture(...channels: string[]): {
  tracker: IrcIdentityTracker;
  membership: IrcMembershipState;
  presence: IrcPresenceCoordinator;
} {
  const membership = new IrcMembershipState();
  const tracker = new IrcIdentityTracker((nick) => membership.key(nick));
  const presence = new IrcPresenceCoordinator(membership, tracker);
  for (const channel of channels) membership.join(channel);
  return { tracker, membership, presence };
}
