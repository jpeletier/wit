import assert from "node:assert/strict";
import test from "node:test";
import {
  DEFAULT_OUTBOUND_DELAY_MS,
  OutboundQueue,
  resolveOutboundDelayMs,
  type OutboundScheduler,
  type ScheduledTask,
} from "../src/irc/outbound-queue.js";

interface PendingTask {
  due: number;
  order: number;
  callback: () => void;
  cancelled: boolean;
  unrefed: boolean;
}

class FakeScheduler implements OutboundScheduler {
  now = 0;
  #order = 0;
  readonly tasks: PendingTask[] = [];

  schedule(callback: () => void, delayMs: number): ScheduledTask {
    const task: PendingTask = {
      due: this.now + delayMs,
      order: this.#order++,
      callback,
      cancelled: false,
      unrefed: false,
    };
    this.tasks.push(task);
    return {
      cancel: () => {
        task.cancelled = true;
      },
      unref: () => {
        task.unrefed = true;
      },
    };
  }

  advance(milliseconds: number): void {
    const target = this.now + milliseconds;
    for (;;) {
      const next = this.tasks
        .filter((task) => !task.cancelled && task.due <= target)
        .sort((left, right) => left.due - right.due || left.order - right.order)[0];
      if (next === undefined) {
        break;
      }
      next.cancelled = true;
      this.now = next.due;
      next.callback();
    }
    this.now = target;
  }
}

test("outbound queue preserves mixed FIFO order at exact two-second intervals", () => {
  const scheduler = new FakeScheduler();
  const sent: Array<{ kind: string; at: number }> = [];
  const queue = new OutboundQueue(2_000, scheduler);
  queue.enqueue(() => sent.push({ kind: "say:first", at: scheduler.now }));
  queue.enqueue(() => sent.push({ kind: "notice:second", at: scheduler.now }));
  queue.enqueue(() => sent.push({ kind: "say:third", at: scheduler.now }));
  assert.deepEqual(sent, [{ kind: "say:first", at: 0 }]);
  scheduler.advance(1_999);
  assert.equal(sent.length, 1);
  scheduler.advance(1);
  scheduler.advance(2_000);
  assert.deepEqual(sent, [
    { kind: "say:first", at: 0 },
    { kind: "notice:second", at: 2_000 },
    { kind: "say:third", at: 4_000 },
  ]);
  assert.ok(scheduler.tasks.every((task) => task.unrefed));
});

test("outbound queue cancellation drops pending sends", () => {
  const scheduler = new FakeScheduler();
  const sent: string[] = [];
  const queue = new OutboundQueue(2_000, scheduler);
  queue.enqueue(() => sent.push("first"));
  queue.enqueue(() => sent.push("stale"));
  queue.clear();
  scheduler.advance(10_000);
  assert.deepEqual(sent, ["first"]);
});

test("outbound queue logs send errors and continues", async () => {
  const scheduler = new FakeScheduler();
  const errors: unknown[] = [];
  const sent: string[] = [];
  const queue = new OutboundQueue(2_000, scheduler, (error) => errors.push(error));
  const failure = new Error("send failed");
  queue.enqueue(() => {
    throw failure;
  });
  const rejected = new Error("async send failed");
  queue.enqueue(() => Promise.reject(rejected));
  queue.enqueue(() => sent.push("third"));
  scheduler.advance(2_000);
  await Promise.resolve();
  scheduler.advance(2_000);
  assert.deepEqual(errors, [failure, rejected]);
  assert.deepEqual(sent, ["third"]);
});

test("outbound queues are isolated per adapter", () => {
  const scheduler = new FakeScheduler();
  const sent: string[] = [];
  const first = new OutboundQueue(2_000, scheduler);
  const second = new OutboundQueue(2_000, scheduler);
  first.enqueue(() => sent.push("first:one"));
  first.enqueue(() => sent.push("first:two"));
  second.enqueue(() => sent.push("second:one"));
  second.enqueue(() => sent.push("second:two"));
  first.clear();
  scheduler.advance(2_000);
  assert.deepEqual(sent, ["first:one", "second:one", "second:two"]);
});

test("adapter delay defaults to 2000 ms and production options reject zero", () => {
  assert.equal(DEFAULT_OUTBOUND_DELAY_MS, 2_000);
  assert.equal(resolveOutboundDelayMs(), 2_000);
  assert.equal(resolveOutboundDelayMs(750), 750);
  assert.throws(() => resolveOutboundDelayMs(0), /positive integer/u);

  const scheduler = new FakeScheduler();
  const sent: string[] = [];
  const testQueue = new OutboundQueue(0, scheduler);
  testQueue.enqueue(() => sent.push("first"));
  testQueue.enqueue(() => sent.push("second"));
  scheduler.advance(0);
  assert.deepEqual(sent, ["first", "second"]);
});
