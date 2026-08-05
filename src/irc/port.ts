export type IrcCaseMapping = "ascii" | "rfc1459" | "strict-rfc1459";

export interface IrcUser {
  identity: string;
  nick: string;
}

export type IrcEvent =
  | { type: "registered" }
  | { type: "disconnected"; reason?: string }
  | { type: "message"; channel: string; user: IrcUser; text: string }
  | { type: "privateMessage"; user: IrcUser; text: string }
  | { type: "join"; channel: string; user: IrcUser; self: boolean }
  | { type: "part"; channel: string; user: IrcUser; self: boolean }
  | { type: "nick"; user: IrcUser; previousNick: string }
  | { type: "membership"; channel: string };

export interface IrcPort {
  readonly nick: string;
  readonly caseMapping: IrcCaseMapping;
  connect(): Promise<void>;
  disconnect(reason?: string): void;
  join(channel: string): void;
  say(target: string, text: string): void;
  notice(target: string, text: string): void;
  isOperator(channel: string, nick: string): boolean;
  onEvent(listener: (event: IrcEvent) => void): () => void;
}

export class FakeIrcPort implements IrcPort {
  readonly sent: Array<{
    kind: "message" | "notice" | "join";
    target: string;
    text: string;
  }> = [];
  readonly #listeners = new Set<(event: IrcEvent) => void>();
  readonly #operators = new Set<string>();
  caseMapping: IrcCaseMapping = "rfc1459";
  constructor(public nick = "Wit") {}
  async connect(): Promise<void> {
    this.emit({ type: "registered" });
  }
  disconnect(reason?: string): void {
    this.emit(
      reason === undefined
        ? { type: "disconnected" }
        : { type: "disconnected", reason },
    );
  }
  join(channel: string): void {
    this.sent.push({ kind: "join", target: channel, text: "" });
  }
  say(target: string, text: string): void {
    this.sent.push({ kind: "message", target, text });
  }
  notice(target: string, text: string): void {
    this.sent.push({ kind: "notice", target, text });
  }
  isOperator(channel: string, nick: string): boolean {
    return this.#operators.has(
      `${channel.toLowerCase()}\0${nick.toLowerCase()}`,
    );
  }
  setOperator(channel: string, nick: string, value = true): void {
    const key = `${channel.toLowerCase()}\0${nick.toLowerCase()}`;
    if (value) this.#operators.add(key);
    else this.#operators.delete(key);
  }
  onEvent(listener: (event: IrcEvent) => void): () => void {
    this.#listeners.add(listener);
    return () => this.#listeners.delete(listener);
  }
  emit(event: IrcEvent): void {
    for (const listener of this.#listeners) listener(event);
  }
}
