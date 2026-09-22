import { Client } from "irc-client-ts";
import { ircCasefold } from "../core/text.js";
import { sanitizeIrcText } from "../core/format.js";
import {
  buildClientOptions,
  buildServiceAuthCommand,
  type AccountAuth,
  type ServiceAuth,
} from "./auth.js";
import { OutboundQueue, resolveOutboundDelayMs } from "./outbound-queue.js";
import { RegistrationPolicy, ReconnectController } from "./reconnect-controller.js";
import {
  IrcMembershipState,
  IrcIdentityTracker,
  IrcPresenceCoordinator,
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
  ident?: string;
  realname?: string;
  serverPassword?: string;
  accountAuth?: AccountAuth;
  serviceAuth?: ServiceAuth;
  channels: string[];
  outboundDelayMs?: number;
}

export class IrcClientAdapter implements IrcPort {
  readonly #client: Client;
  readonly #listeners = new Set<(event: IrcEvent) => void>();
  readonly #membership = new IrcMembershipState();
  readonly #outbound: OutboundQueue;
  readonly #reconnect: ReconnectController;
  readonly #registration: RegistrationPolicy;
  readonly #identities = new IrcIdentityTracker((nick) => ircCasefold(nick, this.#caseMapping));
  readonly #presence = new IrcPresenceCoordinator(this.#membership, this.#identities);
  #caseMapping: IrcCaseMapping = "rfc1459";
  #connectionEnded = true;

  constructor(private readonly config: IrcClientConfig) {
    this.#client = new Client(
      buildClientOptions({
        nick: config.nick,
        ...(config.accountAuth === undefined && config.ident !== undefined
          ? { username: config.ident }
          : {}),
        ...(config.realname === undefined ? {} : { realname: config.realname }),
        ...(config.serverPassword === undefined ? {} : { serverPassword: config.serverPassword }),
        ...(config.accountAuth === undefined ? {} : { accountAuth: config.accountAuth }),
      })
    );
    this.#outbound = new OutboundQueue(
      resolveOutboundDelayMs(config.outboundDelayMs),
      undefined,
      (error) => console.error(`IRC ${this.config.nick} outbound send failed`, error)
    );
    this.#reconnect = new ReconnectController(
      async () => {
        const connection = await this.#client.connect(this.config.server, {
          port: this.config.port,
          tls: this.config.tls,
        });
        if (connection === null) {
          throw new Error("IRC connection failed");
        }
      },
      undefined,
      (error) => console.error(`IRC ${this.config.nick} connection attempt failed`, error)
    );
    const serviceAuth = buildServiceAuthCommand(config.serviceAuth);
    this.#registration = new RegistrationPolicy(
      this.#reconnect,
      () => {
        if (serviceAuth !== undefined) {
          this.say(serviceAuth.target, serviceAuth.text);
        }
      },
      config.channels,
      (channel) => this.#client.join(channel),
      () => this.#client.disconnect(),
      () => this.#emit({ type: "registered" })
    );
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
    await this.#reconnect.start();
  }
  disconnect(reason = "Wit detenido"): void {
    this.#reconnect.stop();
    this.#outbound.clear();
    this.#client.quit(reason);
  }
  join(channel: string): void {
    this.#client.join(channel);
  }
  part(channel: string, reason?: string): void {
    this.#client.part(channel, reason === undefined ? undefined : sanitizeIrcText(reason));
  }
  say(target: string, text: string): void {
    const safeText = sanitizeIrcText(text);
    this.#outbound.enqueue(() => this.#client.privmsg(target, safeText));
  }
  notice(target: string, text: string): void {
    const safeText = sanitizeIrcText(text);
    this.#outbound.enqueue(() => this.#client.notice(target, safeText));
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
    this.#client.on("error", (error) => {
      console.error(`IRC ${this.config.nick}: ${error.message}`);
      if (error.type === "close") {
        this.#handleDisconnected();
      } else if (["connect", "read"].includes(error.type)) {
        this.#reconnect.connectionLost();
      }
    });
    this.#client.on("connecting", () => {
      this.#connectionEnded = false;
    });
    this.#client.on("connected", () => {
      if (this.#reconnect.stopped) {
        this.#client.disconnect();
      }
    });
    this.#client.on("register", () => {
      this.#registration.registered();
    });
    this.#client.on("disconnected", () => this.#handleDisconnected());
    this.#client.on("raw:error", () => this.#client.disconnect());
    this.#client.on("privmsg:channel", (message) =>
      this.#emit({
        type: "message",
        channel: message.params.target,
        user: this.#user(message.source),
        text: message.params.text,
      })
    );
    this.#client.on("privmsg:private", (message) =>
      this.#emit({
        type: "privateMessage",
        user: this.#user(message.source),
        text: message.params.text,
      })
    );
    this.#client.on("invite", (message) => {
      if (!this.#sameNick(message.params.nick, this.nick)) {
        return;
      }
      this.#emit({
        type: "invite",
        channel: message.params.channel,
        user: this.#user(message.source),
      });
    });
    this.#client.on("join", (message) => {
      const user = this.#user(message.source);
      const self = this.#sameNick(user.nick, this.nick);
      if (self) {
        this.#membership.join(message.params.channel);
      } else {
        this.#presence.join(message.params.channel, user.nick);
      }
      this.#emit({
        type: "join",
        channel: message.params.channel,
        user,
        self,
      });
    });
    this.#client.on("part", (message) => {
      const user = this.#user(message.source);
      const self = this.#sameNick(user.nick, this.nick);
      if (self) {
        this.#presence.leaveChannel(message.params.channel);
      } else {
        this.#presence.part(message.params.channel, user.nick);
      }
      this.#emit({
        type: "part",
        channel: message.params.channel,
        user,
        self,
      });
    });
    this.#client.on("kick", (message) => {
      const user = this.#user(message.source);
      const self = this.#sameNick(message.params.nick, this.nick);
      if (self) {
        this.#presence.leaveChannel(message.params.channel);
      } else {
        this.#presence.kick(message.params.channel, message.params.nick);
      }
      this.#emit({
        type: "kick",
        channel: message.params.channel,
        user,
        kickedNick: message.params.nick,
        self,
      });
    });
    this.#client.on("quit", (message) => {
      const nick = message.source?.name;
      if (nick !== undefined) {
        this.#presence.quit(nick);
      }
    });
    this.#client.on("nick", (message) => {
      const previousNick = message.source?.name ?? "";
      const identity = this.#presence.rename(
        previousNick,
        message.params.nick,
        message.source?.mask
      );
      this.#emit({
        type: "nick",
        previousNick,
        user: { identity, nick: message.params.nick },
      });
    });
    this.#client.on("nicklist", (message) => {
      this.#membership.setMembers(message.params.channel, message.params.nicklist);
      this.#emit({ type: "membership", channel: message.params.channel });
    });
    this.#client.on("raw", (message) => {
      if (message.command !== "rpl_isupport") {
        return;
      }
      let caseMapping = this.#caseMapping;
      for (const parameter of message.params) {
        const match = /^CASEMAPPING=(ascii|rfc1459|strict-rfc1459)$/iu.exec(parameter);
        if (match !== null) {
          caseMapping = match[1]!.toLowerCase() as IrcCaseMapping;
        }
      }
      const changed = caseMapping !== this.#caseMapping;
      this.#caseMapping = caseMapping;
      this.#membership.configure(caseMapping, this.#client.state.isupport.PREFIX ?? "(qaohv)~&@%+");
      if (changed) {
        this.#identities.rekey();
        this.#emit({ type: "caseMapping", caseMapping });
      }
    });
  }

  #sameNick(left: string, right: string): boolean {
    return ircCasefold(left, this.#caseMapping) === ircCasefold(right, this.#caseMapping);
  }
  #handleDisconnected(): void {
    if (this.#connectionEnded) {
      return;
    }
    this.#connectionEnded = true;
    this.#outbound.clear();
    this.#presence.clear();
    this.#registration.disconnected();
    try {
      this.#emit({ type: "disconnected", reason: "connection lost" });
    } finally {
      this.#outbound.clear();
      this.#reconnect.connectionLost();
    }
  }
  #identity(source: { name: string; mask?: { user: string; host: string } } | undefined): string {
    if (source === undefined) {
      return "server";
    }
    return this.#identities.resolve(source.name, source.mask);
  }
  #user(source: { name: string; mask?: { user: string; host: string } } | undefined): IrcUser {
    return { identity: this.#identity(source), nick: source?.name ?? "server" };
  }
  #emit(event: IrcEvent): void {
    for (const listener of this.#listeners) {
      listener(event);
    }
  }
}
