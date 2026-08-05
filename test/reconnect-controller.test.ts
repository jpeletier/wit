import assert from "node:assert/strict";
import test from "node:test";
import {
  INITIAL_RECONNECT_DELAY_MS,
  MAX_RECONNECT_DELAY_MS,
  RegistrationPolicy,
  ReconnectController,
  type ReconnectScheduler,
  type ReconnectTimer,
} from "../src/irc/reconnect-controller.js";

interface PendingReconnect {
  callback: () => void;
  delayMs: number;
  cancelled: boolean;
}

class FakeReconnectScheduler implements ReconnectScheduler {
  readonly tasks: PendingReconnect[] = [];
  readonly delays: number[] = [];

  schedule(callback: () => void, delayMs: number): ReconnectTimer {
    const task = { callback, delayMs, cancelled: false };
    this.tasks.push(task);
    this.delays.push(delayMs);
    return {
      cancel: () => {
        task.cancelled = true;
      },
    };
  }

  runNext(): void {
    const task = this.tasks.find((candidate) => !candidate.cancelled);
    assert.ok(task, "expected a pending reconnect");
    task.cancelled = true;
    task.callback();
  }

  pending(): number {
    return this.tasks.filter((task) => !task.cancelled).length;
  }
}

async function flushAttempt(): Promise<void> {
  await Promise.resolve();
  await Promise.resolve();
}

test("initial failures retry indefinitely with exponential capped backoff", async () => {
  const scheduler = new FakeReconnectScheduler();
  const errors: unknown[] = [];
  let attempts = 0;
  const controller = new ReconnectController(
    async () => {
      attempts++;
      throw new Error(`failure ${attempts}`);
    },
    scheduler,
    (error) => errors.push(error),
  );
  await controller.start();
  for (let attempt = 0; attempt < 6; attempt++) {
    scheduler.runNext();
    await flushAttempt();
  }
  assert.deepEqual(scheduler.delays, [
    INITIAL_RECONNECT_DELAY_MS,
    10_000,
    20_000,
    40_000,
    80_000,
    MAX_RECONNECT_DELAY_MS,
    MAX_RECONNECT_DELAY_MS,
  ]);
  assert.equal(attempts, 7);
  assert.equal(errors.length, 7);
  assert.equal(scheduler.pending(), 1);
});

test("silent disconnect and ping/read-close signals schedule one reconnect", async () => {
  const scheduler = new FakeReconnectScheduler();
  let attempts = 0;
  const controller = new ReconnectController(async () => {
    attempts++;
  }, scheduler);
  await controller.start();
  controller.registered();
  controller.connectionLost();
  controller.connectionLost();
  controller.connectionLost();
  assert.equal(scheduler.pending(), 1);
  assert.deepEqual(scheduler.delays, [5_000]);
  scheduler.runNext();
  await flushAttempt();
  assert.equal(attempts, 2);
  assert.equal(scheduler.pending(), 0);
});

test("successful registration resets backoff and rejoins configured channels once", async () => {
  const scheduler = new FakeReconnectScheduler();
  let attempts = 0;
  const controller = new ReconnectController(
    async () => {
      attempts++;
      if (attempts < 3) throw new Error("temporary");
    },
    scheduler,
    () => {},
  );
  await controller.start();
  scheduler.runNext();
  await flushAttempt();
  scheduler.runNext();
  await flushAttempt();
  const joins: string[] = [];
  const events: string[] = [];
  const registration = new RegistrationPolicy(
    controller,
    ["#one", "#two"],
    (channel) => joins.push(channel),
    () => assert.fail("active registration must not close"),
    () => events.push("registered"),
  );
  assert.equal(registration.registered(), true);
  assert.equal(registration.registered(), false);
  controller.connectionLost();
  assert.deepEqual(scheduler.delays, [5_000, 10_000, 5_000]);
  registration.disconnected();
  assert.equal(registration.registered(), true);
  assert.deepEqual(joins, ["#one", "#two", "#one", "#two"]);
  assert.deepEqual(events, ["registered", "registered"]);
});

test("intentional shutdown cancels retry and ignores later disconnects", async () => {
  const scheduler = new FakeReconnectScheduler();
  let attempts = 0;
  const controller = new ReconnectController(async () => {
    attempts++;
  }, scheduler);
  await controller.start();
  controller.registered();
  controller.connectionLost();
  controller.stop();
  controller.stop();
  controller.connectionLost();
  assert.equal(scheduler.pending(), 0);
  assert.equal(attempts, 1);
});

test("intentional shutdown during an attempt cannot schedule another", async () => {
  const scheduler = new FakeReconnectScheduler();
  let finishAttempt: (() => void) | undefined;
  const controller = new ReconnectController(
    () =>
      new Promise<void>((resolve) => {
        finishAttempt = resolve;
      }),
    scheduler,
  );
  const started = controller.start();
  controller.stop();
  finishAttempt?.();
  await started;
  controller.connectionLost();
  assert.equal(controller.stopped, true);
  assert.equal(scheduler.pending(), 0);
});

test("late registration after stop closes without joins, events, or retries", async () => {
  const scheduler = new FakeReconnectScheduler();
  const controller = new ReconnectController(async () => {}, scheduler);
  await controller.start();
  controller.stop();
  const joins: string[] = [];
  const events: string[] = [];
  let closes = 0;
  const registration = new RegistrationPolicy(
    controller,
    ["#one", "#two"],
    (channel) => joins.push(channel),
    () => closes++,
    () => events.push("registered"),
  );
  assert.equal(registration.registered(), false);
  assert.deepEqual(joins, []);
  assert.deepEqual(events, []);
  assert.equal(closes, 1);
  assert.equal(scheduler.pending(), 0);
});
