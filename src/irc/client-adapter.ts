import { Client } from "irc-client-ts";
import { ircCasefold } from "../core/text.js";
import {
  IrcMembershipState,
  IrcIdentityTracker,
  type IrcCaseMapping,
  type IrcEvent,
  type IrcPort,
  type IrcUser,
} from "./port.js";

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
  readonly #membership = new IrcMembershipState();
  readonly #identities = new IrcIdentityTracker((nick) =>
    ircCasefold(nick, this.#caseMapping),
  );
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
  get joinedChannels(): readonly string[] {
    return this.#membership.joinedChannels();
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
    return this.#membership.isOperator(channel, nick);
  }
  isJoined(channel: string): boolean {
    return this.#membership.isJoined(channel);
  }

  #wireEvents(): void {
    this.#client.on("error", (error) =>
      console.error(`IRC ${this.config.nick}: ${error.message}`),
    );
    this.#client.on("register", () => {
      for (const channel of this.config.channels) this.#client.join(channel);
      this.#emit({ type: "registered" });
    });
    this.#client.on("disconnected", () => {
      this.#membership.clear();
      this.#identities.clear();
      this.#emit({ type: "disconnected", reason: "connection lost" });
    });
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
      if (this.#sameNick(user.nick, this.nick))
        this.#membership.join(message.params.channel);
    });
    this.#client.on("part", (message) => {
      const user = this.#user(message.source);
      this.#emit({
        type: "part",
        channel: message.params.channel,
        user,
        self: this.#sameNick(user.nick, this.nick),
      });
      if (this.#sameNick(user.nick, this.nick))
        this.#membership.part(message.params.channel);
    });
    this.#client.on("kick", (message) => {
      const user = this.#user(message.source);
      const self = this.#sameNick(message.params.nick, this.nick);
      if (self) this.#membership.part(message.params.channel);
      this.#emit({
        type: "kick",
        channel: message.params.channel,
        user,
        kickedNick: message.params.nick,
        self,
      });
    });
    this.#client.on("nick", (message) => {
      const previousNick = message.source?.name ?? "";
      const identity = this.#identities.rename(
        previousNick,
        message.params.nick,
        message.source?.mask,
      );
      this.#membership.rename(previousNick, message.params.nick);
      this.#emit({
        type: "nick",
        previousNick,
        user: { identity, nick: message.params.nick },
      });
    });
    this.#client.on("nicklist", (message) => {
      this.#membership.setMembers(
        message.params.channel,
        message.params.nicklist,
      );
      this.#emit({ type: "membership", channel: message.params.channel });
    });
    this.#client.on("raw", (message) => {
      if (message.command !== "rpl_isupport") return;
      for (const parameter of message.params) {
        const match = /^CASEMAPPING=(ascii|rfc1459|strict-rfc1459)$/iu.exec(
          parameter,
        );
        if (match !== null)
          this.#caseMapping = match[1]!.toLowerCase() as IrcCaseMapping;
        this.#membership.caseMapping = this.#caseMapping;
        this.#membership.prefix =
          this.#client.state.isupport.PREFIX ?? "(qaohv)~&@%+";
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
    return this.#identities.resolve(source.name, source.mask);
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
