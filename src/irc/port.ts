import { ircCasefold } from "../core/text.js";
import { sanitizeIrcText } from "../core/format.js";

export type IrcCaseMapping = "ascii" | "rfc1459" | "strict-rfc1459";
export interface IrcUser {
  identity: string;
  nick: string;
}
export interface IrcMember {
  nick: string;
  prefix: string;
}

interface TrackedIdentity {
  identity: string;
  mask: string | undefined;
  nick: string;
}

interface ChannelMembers {
  channel: string;
  members: IrcMember[];
}

export class IrcIdentityTracker {
  readonly #byNick = new Map<string, TrackedIdentity>();
  #sequence = 0;
  constructor(private readonly fold: (nick: string) => string) {}
  resolve(nick: string, mask?: { user: string; host: string }): string {
    const key = this.fold(nick);
    const maskKey = identityMask(mask);
    const existing = this.#byNick.get(key);
    if (existing !== undefined && existing.mask === maskKey)
      return existing.identity;
    const base = maskKey === undefined ? `nick:${key}` : maskKey;
    const identity = `${base}#${++this.#sequence}`;
    this.#byNick.set(key, { identity, mask: maskKey, nick });
    return identity;
  }
  rename(
    previousNick: string,
    nick: string,
    mask?: { user: string; host: string },
  ): string {
    const previousKey = this.fold(previousNick);
    const existing = this.#byNick.get(previousKey);
    const identity = existing?.identity ?? this.resolve(previousNick, mask);
    const tracked = existing ?? this.#byNick.get(previousKey)!;
    if (tracked.mask === undefined) tracked.mask = identityMask(mask);
    tracked.nick = nick;
    this.#byNick.delete(previousKey);
    this.#byNick.set(this.fold(nick), tracked);
    return identity;
  }
  forget(nick: string): void {
    this.#byNick.delete(this.fold(nick));
  }
  get trackedCount(): number {
    return this.#byNick.size;
  }
  rekey(): void {
    const identities = [...this.#byNick.values()];
    this.#byNick.clear();
    for (const tracked of identities) {
      const key = this.fold(tracked.nick);
      if (!this.#byNick.has(key)) this.#byNick.set(key, tracked);
    }
  }
  clear(): void {
    this.#byNick.clear();
  }
}

function identityMask(
  mask: { user: string; host: string } | undefined,
): string | undefined {
  return mask === undefined
    ? undefined
    : `${mask.user}@${mask.host}`.normalize("NFC").toLocaleLowerCase("en-US");
}

export type IrcEvent =
  | { type: "registered" }
  | { type: "disconnected"; reason?: string }
  | { type: "caseMapping"; caseMapping: IrcCaseMapping }
  | { type: "message"; channel: string; user: IrcUser; text: string }
  | { type: "privateMessage"; user: IrcUser; text: string }
  | { type: "join"; channel: string; user: IrcUser; self: boolean }
  | { type: "part"; channel: string; user: IrcUser; self: boolean }
  | {
      type: "kick";
      channel: string;
      user: IrcUser;
      kickedNick: string;
      self: boolean;
    }
  | { type: "nick"; user: IrcUser; previousNick: string }
  | { type: "membership"; channel: string };

export class IrcMembershipState {
  readonly #joined = new Map<string, string>();
  readonly #members = new Map<string, ChannelMembers>();
  readonly #previousMembers = new Map<string, ChannelMembers>();
  #caseMapping: IrcCaseMapping;
  constructor(
    caseMapping: IrcCaseMapping = "rfc1459",
    public prefix = "(qaohv)~&@%+",
  ) {
    this.#caseMapping = caseMapping;
  }
  get caseMapping(): IrcCaseMapping {
    return this.#caseMapping;
  }
  key(value: string): string {
    return ircCasefold(value, this.caseMapping);
  }
  join(channel: string): void {
    this.#joined.set(this.key(channel), channel);
  }
  part(channel: string): void {
    this.#joined.delete(this.key(channel));
    this.#members.delete(this.key(channel));
    this.#previousMembers.delete(this.key(channel));
  }
  clear(): void {
    this.#joined.clear();
    this.#members.clear();
    this.#previousMembers.clear();
  }
  isJoined(channel: string): boolean {
    return this.#joined.has(this.key(channel));
  }
  joinedChannels(): readonly string[] {
    return [...this.#joined.values()];
  }
  setMembers(channel: string, members: readonly IrcMember[]): void {
    const channelKey = this.key(channel);
    const previous = this.#members.get(channelKey);
    if (previous !== undefined && previous.members.length > 0)
      this.#previousMembers.set(channelKey, previous);
    this.#members.set(channelKey, { channel, members: [...members] });
  }
  memberNicks(channel: string): readonly string[] {
    const channelKey = this.key(channel);
    const current = this.#members.get(channelKey)?.members ?? [];
    const members =
      current.length > 0
        ? current
        : (this.#previousMembers.get(channelKey)?.members ?? current);
    return members.map((member) => member.nick);
  }
  addMember(channel: string, nick: string): void {
    const channelKey = this.key(channel);
    const members = this.#members.get(channelKey)?.members ?? [];
    if (!members.some((member) => this.key(member.nick) === this.key(nick)))
      members.push({ nick, prefix: "" });
    this.#members.set(channelKey, { channel, members });
  }
  removeMember(channel: string, nick: string): void {
    const channelKey = this.key(channel);
    const state = this.#members.get(channelKey);
    if (state === undefined) return;
    this.#members.set(channelKey, {
      channel: state.channel,
      members: state.members.filter(
        (member) => this.key(member.nick) !== this.key(nick),
      ),
    });
  }
  removeMemberEverywhere(nick: string): void {
    for (const channel of this.#members.keys())
      this.removeMember(channel, nick);
  }
  hasMember(nick: string): boolean {
    return [...this.#members.entries()].some(
      ([channel, state]) =>
        this.#joined.has(channel) &&
        state.members.some(
          (member) => this.key(member.nick) === this.key(nick),
        ),
    );
  }
  rename(previousNick: string, nick: string): void {
    for (const state of this.#members.values()) {
      const member = state.members.find(
        (candidate) => this.key(candidate.nick) === this.key(previousNick),
      );
      if (member !== undefined) member.nick = nick;
    }
  }
  configure(caseMapping: IrcCaseMapping, prefix: string): boolean {
    const changed = this.#caseMapping !== caseMapping;
    if (changed) {
      const joined = [...this.#joined.values()];
      const members = [...this.#members.values()];
      const previousMembers = [...this.#previousMembers.values()];
      this.#caseMapping = caseMapping;
      this.#joined.clear();
      this.#members.clear();
      this.#previousMembers.clear();
      for (const channel of joined)
        this.#joined.set(this.key(channel), channel);
      this.#restoreMembers(this.#members, members);
      this.#restoreMembers(this.#previousMembers, previousMembers);
    }
    this.prefix = prefix;
    return changed;
  }
  isOperator(channel: string, nick: string): boolean {
    const match = /^\(([^)]+)\)(.+)$/u.exec(this.prefix);
    const modes = match?.[1] ?? "qaohv";
    const prefixes = match?.[2] ?? "~&@%+";
    const operators = new Set(
      [...prefixes].filter((_, index) =>
        ["q", "a", "o"].includes(modes[index] ?? ""),
      ),
    );
    return (this.#members.get(this.key(channel))?.members ?? []).some(
      (member) =>
        this.key(member.nick) === this.key(nick) &&
        operators.has(member.prefix),
    );
  }
  #restoreMembers(
    target: Map<string, ChannelMembers>,
    states: readonly ChannelMembers[],
  ): void {
    for (const state of states) {
      const key = this.key(state.channel);
      const existing = target.get(key);
      if (existing === undefined) {
        target.set(key, {
          channel: state.channel,
          members: [...state.members],
        });
        continue;
      }
      for (const member of state.members)
        if (
          !existing.members.some(
            (candidate) => this.key(candidate.nick) === this.key(member.nick),
          )
        )
          existing.members.push(member);
    }
  }
}

export class IrcPresenceCoordinator {
  constructor(
    private readonly membership: IrcMembershipState,
    private readonly identities: IrcIdentityTracker,
  ) {}

  join(channel: string, nick: string): void {
    this.membership.addMember(channel, nick);
  }
  part(channel: string, nick: string): void {
    this.membership.removeMember(channel, nick);
    this.#forgetIfAbsent(nick);
  }
  kick(channel: string, nick: string): void {
    this.part(channel, nick);
  }
  leaveChannel(channel: string): void {
    const nicks = this.membership.memberNicks(channel);
    this.membership.part(channel);
    for (const nick of nicks) this.#forgetIfAbsent(nick);
  }
  quit(nick: string): void {
    this.membership.removeMemberEverywhere(nick);
    this.identities.forget(nick);
  }
  rename(
    previousNick: string,
    nick: string,
    mask?: { user: string; host: string },
  ): string {
    const identity = this.identities.rename(previousNick, nick, mask);
    this.membership.rename(previousNick, nick);
    return identity;
  }
  clear(): void {
    this.membership.clear();
    this.identities.clear();
  }
  #forgetIfAbsent(nick: string): void {
    if (!this.membership.hasMember(nick)) this.identities.forget(nick);
  }
}

export interface IrcPort {
  readonly nick: string;
  readonly caseMapping: IrcCaseMapping;
  readonly joinedChannels: readonly string[];
  connect(): Promise<void>;
  disconnect(reason?: string): void;
  join(channel: string): void;
  say(target: string, text: string): void;
  notice(target: string, text: string): void;
  isJoined(channel: string): boolean;
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
  readonly state = new IrcMembershipState();
  disconnectCount = 0;
  constructor(public nick = "Wit") {}
  get caseMapping(): IrcCaseMapping {
    return this.state.caseMapping;
  }
  set caseMapping(value: IrcCaseMapping) {
    this.setCaseMapping(value);
  }
  setCaseMapping(value: IrcCaseMapping, prefix = this.state.prefix): void {
    if (this.state.configure(value, prefix))
      this.emit({ type: "caseMapping", caseMapping: value });
  }
  get joinedChannels(): readonly string[] {
    return this.state.joinedChannels();
  }
  async connect(): Promise<void> {
    this.emit({ type: "registered" });
  }
  disconnect(reason?: string): void {
    this.disconnectCount++;
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
    this.sent.push({ kind: "message", target, text: sanitizeIrcText(text) });
  }
  notice(target: string, text: string): void {
    this.sent.push({ kind: "notice", target, text: sanitizeIrcText(text) });
  }
  isJoined(channel: string): boolean {
    return this.state.isJoined(channel);
  }
  isOperator(channel: string, nick: string): boolean {
    return this.state.isOperator(channel, nick);
  }
  setOperator(channel: string, nick: string, value = true): void {
    const existing: IrcMember[] = value ? [{ nick, prefix: "@" }] : [];
    this.state.setMembers(channel, existing);
  }
  onEvent(listener: (event: IrcEvent) => void): () => void {
    this.#listeners.add(listener);
    return () => this.#listeners.delete(listener);
  }
  get eventListenerCount(): number {
    return this.#listeners.size;
  }
  emit(event: IrcEvent): void {
    if (event.type === "join" && event.self) this.state.join(event.channel);
    if ((event.type === "part" || event.type === "kick") && event.self)
      this.state.part(event.channel);
    if (event.type === "nick")
      this.state.rename(event.previousNick, event.user.nick);
    if (event.type === "disconnected") this.state.clear();
    for (const listener of this.#listeners) listener(event);
  }
}
