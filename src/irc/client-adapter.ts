import { Client } from "irc-client-ts";
import { ircCasefold } from "../core/text.js";
import type { IrcCaseMapping, IrcEvent, IrcPort, IrcUser } from "./port.js";

export interface IrcClientConfig {
  nick: string;
  server: string;
  port: number;
  tls: boolean;
  password?: string;
  channels: string[];
}

export class IrcClientAdapter implements IrcPort {
  readonly #client: Client;
  readonly #listeners = new Set<(event: IrcEvent) => void>();
  readonly #identities = new Map<string, string>();
  #caseMapping: IrcCaseMapping = "rfc1459";

  constructor(private readonly config: IrcClientConfig) {
    this.#client = new Client({
      nick: config.nick,
      bot: true,
      ...(config.password === undefined ||
      config.password === "" ||
      config.password === "****"
        ? {}
        : { password: config.password }),
      reconnect: {
        attempts: Number.POSITIVE_INFINITY,
        delay: 5,
        exponentialBackoff: true,
      },
      ctcpReplies: { version: "Wit TypeScript" },
    });
    this.#wireEvents();
  }

  get nick(): string {
    return this.#client.state.user.nick ?? this.config.nick;
  }
  get caseMapping(): IrcCaseMapping {
    return this.#caseMapping;
  }
  async connect(): Promise<void> {
    await this.#client.connect(this.config.server, {
      port: this.config.port,
      tls: this.config.tls,
    });
  }
  disconnect(reason = "Wit detenido"): void {
    this.#client.quit(reason);
  }
  join(channel: string): void {
    this.#client.join(channel);
  }
  say(target: string, text: string): void {
    this.#client.privmsg(target, text);
  }
  notice(target: string, text: string): void {
    this.#client.notice(target, text);
  }
  onEvent(listener: (event: IrcEvent) => void): () => void {
    this.#listeners.add(listener);
    return () => this.#listeners.delete(listener);
  }

  isOperator(channel: string, nick: string): boolean {
    const list = this.#client.state.nicklists[channel] ?? [];
    const prefixSpec = this.#client.state.isupport.PREFIX ?? "(qaohv)~&@%+";
    const match = /^\(([^)]+)\)(.+)$/u.exec(prefixSpec);
    const modes = match?.[1] ?? "qaohv";
    const prefixes = match?.[2] ?? "~&@%+";
    const operatorPrefixes = new Set(
      [...prefixes].filter((_, index) =>
        ["q", "a", "o"].includes(modes[index] ?? ""),
      ),
    );
    return list.some(
      (user) =>
        ircCasefold(user.nick, this.#caseMapping) ===
          ircCasefold(nick, this.#caseMapping) &&
        operatorPrefixes.has(user.prefix),
    );
  }

  #wireEvents(): void {
    this.#client.on("error", (error) =>
      console.error(`IRC ${this.config.nick}: ${error.message}`),
    );
    this.#client.on("register", () => {
      for (const channel of this.config.channels) this.#client.join(channel);
      this.#emit({ type: "registered" });
    });
    this.#client.on("disconnected", () =>
      this.#emit({ type: "disconnected", reason: "connection lost" }),
    );
    this.#client.on("privmsg:channel", (message) =>
      this.#emit({
        type: "message",
        channel: message.params.target,
        user: this.#user(message.source),
        text: message.params.text,
      }),
    );
    this.#client.on("privmsg:private", (message) =>
      this.#emit({
        type: "privateMessage",
        user: this.#user(message.source),
        text: message.params.text,
      }),
    );
    this.#client.on("join", (message) => {
      const user = this.#user(message.source);
      this.#emit({
        type: "join",
        channel: message.params.channel,
        user,
        self: this.#sameNick(user.nick, this.nick),
      });
    });
    this.#client.on("part", (message) => {
      const user = this.#user(message.source);
      this.#emit({
        type: "part",
        channel: message.params.channel,
        user,
        self: this.#sameNick(user.nick, this.nick),
      });
    });
    this.#client.on("nick", (message) => {
      const previousNick = message.source?.name ?? "";
      const identity = this.#identity(message.source);
      this.#identities.delete(ircCasefold(previousNick, this.#caseMapping));
      this.#identities.set(
        ircCasefold(message.params.nick, this.#caseMapping),
        identity,
      );
      this.#emit({
        type: "nick",
        previousNick,
        user: { identity, nick: message.params.nick },
      });
    });
    this.#client.on("nicklist", (message) =>
      this.#emit({ type: "membership", channel: message.params.channel }),
    );
    this.#client.on("raw", (message) => {
      if (message.command !== "rpl_isupport") return;
      for (const parameter of message.params) {
        const match = /^CASEMAPPING=(ascii|rfc1459|strict-rfc1459)$/iu.exec(
          parameter,
        );
        if (match !== null)
          this.#caseMapping = match[1]!.toLowerCase() as IrcCaseMapping;
      }
    });
  }

  #sameNick(left: string, right: string): boolean {
    return (
      ircCasefold(left, this.#caseMapping) ===
      ircCasefold(right, this.#caseMapping)
    );
  }
  #identity(
    source: { name: string; mask?: { user: string; host: string } } | undefined,
  ): string {
    if (source === undefined) return "server";
    const key = ircCasefold(source.name, this.#caseMapping);
    const existing = this.#identities.get(key);
    if (existing !== undefined) return existing;
    const identity =
      source.mask === undefined
        ? `nick:${key}`
        : `${source.mask.user}@${source.mask.host}`
            .normalize("NFC")
            .toLocaleLowerCase("en-US");
    this.#identities.set(key, identity);
    return identity;
  }
  #user(
    source: { name: string; mask?: { user: string; host: string } } | undefined,
  ): IrcUser {
    return { identity: this.#identity(source), nick: source?.name ?? "server" };
  }
  #emit(event: IrcEvent): void {
    for (const listener of this.#listeners) listener(event);
  }
}
