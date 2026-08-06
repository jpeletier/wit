export const INITIAL_RECONNECT_DELAY_MS = 5_000;
export const MAX_RECONNECT_DELAY_MS = 120_000;

export interface ReconnectTimer {
  cancel(): void;
}

export interface ReconnectScheduler {
  schedule(callback: () => void, delayMs: number): ReconnectTimer;
}

const systemScheduler: ReconnectScheduler = {
  schedule(callback, delayMs) {
    const timer = setTimeout(callback, delayMs);
    return { cancel: () => clearTimeout(timer) };
  },
};

export class ReconnectController {
  #started = false;
  #stopped = false;
  #attempting = false;
  #retryRequested = false;
  #timer: ReconnectTimer | undefined;
  #nextDelayMs = INITIAL_RECONNECT_DELAY_MS;

  constructor(
    private readonly connect: () => Promise<void>,
    private readonly scheduler: ReconnectScheduler = systemScheduler,
    private readonly onError: (error: unknown) => void = (error) =>
      console.error("IRC connection attempt failed", error)
  ) {}

  get stopped(): boolean {
    return this.#stopped;
  }

  async start(): Promise<void> {
    if (this.#started || this.#stopped) {
      return;
    }
    this.#started = true;
    await this.#attempt();
  }

  connectionLost(): void {
    if (!this.#started || this.#stopped) {
      return;
    }
    if (this.#attempting) {
      this.#retryRequested = true;
      return;
    }
    this.#schedule();
  }

  registered(): boolean {
    if (this.#stopped) {
      return false;
    }
    this.#retryRequested = false;
    this.#timer?.cancel();
    this.#timer = undefined;
    this.#nextDelayMs = INITIAL_RECONNECT_DELAY_MS;
    return true;
  }

  stop(): void {
    if (this.#stopped) {
      return;
    }
    this.#stopped = true;
    this.#retryRequested = false;
    this.#timer?.cancel();
    this.#timer = undefined;
  }

  async #attempt(): Promise<void> {
    if (this.#attempting || this.#stopped) {
      return;
    }
    this.#attempting = true;
    this.#retryRequested = false;
    try {
      await this.connect();
    } catch (error) {
      this.onError(error);
      this.#retryRequested = true;
    } finally {
      this.#attempting = false;
      if (this.#retryRequested) {
        this.#schedule();
      }
    }
  }

  #schedule(): void {
    if (this.#timer !== undefined || this.#stopped) {
      return;
    }
    const delayMs = this.#nextDelayMs;
    this.#nextDelayMs = Math.min(delayMs * 2, MAX_RECONNECT_DELAY_MS);
    this.#timer = this.scheduler.schedule(() => {
      this.#timer = undefined;
      void this.#attempt();
    }, delayMs);
  }
}

export class RegistrationPolicy {
  #registered = false;

  constructor(
    private readonly reconnect: ReconnectController,
    private readonly authenticate: () => void,
    private readonly channels: readonly string[],
    private readonly join: (channel: string) => void,
    private readonly closeLateConnection: () => void,
    private readonly emitRegistered: () => void
  ) {}

  registered(): boolean {
    if (this.reconnect.stopped) {
      this.closeLateConnection();
      return false;
    }
    if (this.#registered) {
      return false;
    }
    if (!this.reconnect.registered()) {
      this.closeLateConnection();
      return false;
    }
    this.#registered = true;
    this.authenticate();
    for (const channel of this.channels) {
      this.join(channel);
    }
    this.emitRegistered();
    return true;
  }

  disconnected(): void {
    this.#registered = false;
  }
}
