export const DEFAULT_OUTBOUND_DELAY_MS = 2_000;

export interface ScheduledTask {
  cancel(): void;
  unref?(): void;
}

export interface OutboundScheduler {
  schedule(callback: () => void, delayMs: number): ScheduledTask;
}

const systemScheduler: OutboundScheduler = {
  schedule(callback, delayMs) {
    const timer = setTimeout(callback, delayMs);
    return {
      cancel: () => clearTimeout(timer),
      unref: () => timer.unref(),
    };
  },
};

export function resolveOutboundDelayMs(value?: number): number {
  const delayMs = value ?? DEFAULT_OUTBOUND_DELAY_MS;
  if (!Number.isSafeInteger(delayMs) || delayMs <= 0) {
    throw new Error("outboundDelayMs must be a positive integer");
  }
  return delayMs;
}

export class OutboundQueue {
  readonly #pending: Array<() => unknown> = [];
  #cooldown: ScheduledTask | undefined;

  constructor(
    private readonly delayMs: number,
    private readonly scheduler: OutboundScheduler = systemScheduler,
    private readonly onError: (error: unknown) => void = () => {}
  ) {
    if (!Number.isSafeInteger(delayMs) || delayMs < 0) {
      throw new Error("Outbound queue delay must be a non-negative integer");
    }
  }

  enqueue(send: () => unknown): void {
    this.#pending.push(send);
    if (this.#cooldown === undefined) {
      this.#sendNext();
    }
  }

  clear(): void {
    this.#pending.length = 0;
    this.#cooldown?.cancel();
    this.#cooldown = undefined;
  }

  #sendNext(): void {
    const send = this.#pending.shift();
    if (send === undefined) {
      return;
    }
    this.#cooldown = this.scheduler.schedule(() => {
      this.#cooldown = undefined;
      this.#sendNext();
    }, this.delayMs);
    this.#cooldown.unref?.();
    try {
      const result = send();
      if (isPromiseLike(result)) {
        void Promise.resolve(result).catch((error: unknown) => this.onError(error));
      }
    } catch (error) {
      this.onError(error);
    }
  }
}

function isPromiseLike(value: unknown): value is PromiseLike<unknown> {
  return (
    (typeof value === "object" || typeof value === "function") &&
    value !== null &&
    "then" in value &&
    typeof value.then === "function"
  );
}
