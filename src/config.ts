import { readFileSync } from "node:fs";
import type { AccountAuth, ServiceAuth } from "./irc/auth.js";

const ROOT_KEYS = ["database", "welcomeOnJoin", "bots"] as const;
const BOT_KEYS = [
  "nick",
  "server",
  "port",
  "tls",
  "ident",
  "realname",
  "serverPassword",
  "accountAuth",
  "serviceAuth",
  "networkId",
  "channels",
  "outboundDelayMs",
  "channelLifecycle",
] as const;
const ACCOUNT_AUTH_KEYS = ["method", "username", "password"] as const;
const SERVICE_AUTH_KEYS = ["target", "command", "account", "password"] as const;
const CHANNEL_LIFECYCLE_KEYS = [
  "messageIdleMinutes",
  "gameIdleMinutes",
  "maxChannels",
  "inviteEvictionIdleMinutes",
] as const;
export const MAX_CHANNEL_LENGTH = 50;
export const MAX_OUTBOUND_DELAY_MS = 300_000;
export const MAX_CHANNEL_LIFECYCLE_MINUTES = 5_256_000;
export const MAX_JOINED_CHANNELS = 100;

export interface ChannelLifecycleConfig {
  messageIdleMinutes: number;
  gameIdleMinutes: number;
  maxChannels: number;
  inviteEvictionIdleMinutes: number;
}

export const DEFAULT_CHANNEL_LIFECYCLE: Readonly<ChannelLifecycleConfig> = Object.freeze({
  messageIdleMinutes: 6 * 60,
  gameIdleMinutes: 48 * 60,
  maxChannels: 15,
  inviteEvictionIdleMinutes: 60,
});

export const DEFAULT_IDENT = "jirc";
export const DEFAULT_REALNAME = "jIRC ActiveX DLL by J. Peletier, www.peletier.com";
export const MAX_REALNAME_BYTES = 128;

export interface BotConfig {
  nick: string;
  server: string;
  port: number;
  tls: boolean;
  ident: string;
  realname: string;
  serverPassword?: string;
  accountAuth?: AccountAuth;
  serviceAuth?: ServiceAuth;
  networkId: number;
  channels: string[];
  outboundDelayMs?: number;
  channelLifecycle: ChannelLifecycleConfig;
}
export interface Config {
  database: string;
  welcomeOnJoin: boolean;
  bots: BotConfig[];
}

export function loadConfig(path: string): Config {
  let source: string;
  try {
    source = readFileSync(path, "utf8");
  } catch (cause) {
    throw new Error(`Unable to read config file ${path}`, { cause });
  }
  let raw: unknown;
  try {
    raw = JSON.parse(source);
  } catch (cause) {
    throw new Error(`Invalid JSON in config file ${path}`, { cause });
  }
  try {
    return parseConfig(raw);
  } catch (cause) {
    const detail = cause instanceof Error ? cause.message : "validation failed";
    throw new Error(`Invalid configuration in ${path}: ${detail}`, { cause });
  }
}

export function selectDatabasePath(
  configuredPath: string,
  environmentOverride: string | undefined
): string {
  if (environmentOverride === undefined) {
    if (!validPath(configuredPath)) {
      throw new Error("config.database must be a nonempty path");
    }
    return configuredPath;
  }
  if (!validPath(environmentOverride)) {
    throw new Error("WIT_DATABASE must be a nonempty path");
  }
  return environmentOverride;
}

export function parseConfig(raw: unknown): Config {
  const value = objectValue(raw, "config");
  rejectUnknownKeys(value, ROOT_KEYS, "config");
  if (!validPath(value.database)) {
    throw new Error("config.database must be a nonempty path");
  }
  if (value.welcomeOnJoin !== undefined && typeof value.welcomeOnJoin !== "boolean") {
    throw new Error("config.welcomeOnJoin must be a boolean");
  }
  if (!Array.isArray(value.bots) || value.bots.length === 0) {
    throw new Error("config.bots must be a nonempty array");
  }
  const bots = value.bots.map((entry, index) => validateBot(entry, index));
  const identities = new Set<string>();
  const assignments = new Set<string>();
  for (let index = 0; index < bots.length; index++) {
    const bot = bots[index]!;
    const identity = [bot.server, String(bot.port), bot.nick]
      .map((part) => part.normalize("NFC").toLocaleLowerCase("en-US"))
      .join("\0");
    if (identities.has(identity)) {
      throw new Error(`config.bots[${index}] duplicates a connection identity`);
    }
    identities.add(identity);
    for (let channelIndex = 0; channelIndex < bot.channels.length; channelIndex++) {
      const channel = bot.channels[channelIndex]!;
      const assignment = `${bot.networkId}\0${normalizedKey(channel)}`;
      if (assignments.has(assignment)) {
        throw new Error(
          `config.bots[${index}].channels[${channelIndex}] duplicates a network/channel assignment`
        );
      }
      assignments.add(assignment);
    }
  }
  return freezeConfig({
    database: value.database,
    welcomeOnJoin: value.welcomeOnJoin ?? true,
    bots,
  });
}

function validateBot(raw: unknown, index: number): BotConfig {
  const path = `config.bots[${index}]`;
  const value = objectValue(raw, path);
  rejectUnknownKeys(value, BOT_KEYS, path);
  if (!nickToken(value.nick)) {
    throw new Error(`${path}.nick is invalid`);
  }
  if (!serverToken(value.server)) {
    throw new Error(`${path}.server is invalid`);
  }
  if (!integerInRange(value.port, 1, 65_535)) {
    throw new Error(`${path}.port must be an integer from 1 to 65535`);
  }
  if (value.tls !== undefined && typeof value.tls !== "boolean") {
    throw new Error(`${path}.tls must be a boolean`);
  }
  const ident = validateIdent(value.ident, path);
  const realname = validateRealname(value.realname, path);
  if (!integerInRange(value.networkId, 1, Number.MAX_SAFE_INTEGER)) {
    throw new Error(`${path}.networkId must be a positive safe integer`);
  }
  const channels = validateChannels(value.channels, path);
  const channelLifecycle = validateChannelLifecycle(value.channelLifecycle, path);
  if (channels.length > channelLifecycle.maxChannels) {
    throw new Error(`${path}.channels cannot exceed channelLifecycle.maxChannels`);
  }
  if (
    value.outboundDelayMs !== undefined &&
    !integerInRange(value.outboundDelayMs, 1, MAX_OUTBOUND_DELAY_MS)
  ) {
    throw new Error(
      `${path}.outboundDelayMs must be an integer from 1 to ${MAX_OUTBOUND_DELAY_MS}`
    );
  }
  const accountAuth = validateAccountAuth(value.accountAuth, path);
  const serviceAuth = validateServiceAuth(value.serviceAuth, path);
  const serverPassword = optionalPassword(value.serverPassword, `${path}.serverPassword`);
  return Object.freeze({
    nick: value.nick,
    server: value.server,
    port: value.port,
    tls: value.tls ?? true,
    ident,
    realname,
    networkId: value.networkId,
    channels,
    channelLifecycle,
    ...(typeof value.outboundDelayMs === "number"
      ? { outboundDelayMs: value.outboundDelayMs }
      : {}),
    ...(serverPassword === undefined ? {} : { serverPassword }),
    ...(accountAuth === undefined ? {} : { accountAuth }),
    ...(serviceAuth === undefined ? {} : { serviceAuth }),
  });
}

function validateChannelLifecycle(raw: unknown, botPath: string): ChannelLifecycleConfig {
  if (raw === undefined) {
    return DEFAULT_CHANNEL_LIFECYCLE;
  }
  const path = `${botPath}.channelLifecycle`;
  const value = objectValue(raw, path);
  rejectUnknownKeys(value, CHANNEL_LIFECYCLE_KEYS, path);
  const messageIdleMinutes =
    value.messageIdleMinutes ?? DEFAULT_CHANNEL_LIFECYCLE.messageIdleMinutes;
  const gameIdleMinutes = value.gameIdleMinutes ?? DEFAULT_CHANNEL_LIFECYCLE.gameIdleMinutes;
  const inviteEvictionIdleMinutes =
    value.inviteEvictionIdleMinutes ?? DEFAULT_CHANNEL_LIFECYCLE.inviteEvictionIdleMinutes;
  const maxChannels = value.maxChannels ?? DEFAULT_CHANNEL_LIFECYCLE.maxChannels;
  for (const [field, setting] of [
    ["messageIdleMinutes", messageIdleMinutes],
    ["gameIdleMinutes", gameIdleMinutes],
    ["inviteEvictionIdleMinutes", inviteEvictionIdleMinutes],
  ] as const) {
    if (!integerInRange(setting, 1, MAX_CHANNEL_LIFECYCLE_MINUTES)) {
      throw new Error(
        `${path}.${field} must be a positive integer no greater than ${MAX_CHANNEL_LIFECYCLE_MINUTES}`
      );
    }
  }
  if (!integerInRange(maxChannels, 1, MAX_JOINED_CHANNELS)) {
    throw new Error(`${path}.maxChannels must be an integer from 1 to ${MAX_JOINED_CHANNELS}`);
  }
  return Object.freeze({
    messageIdleMinutes: messageIdleMinutes as number,
    gameIdleMinutes: gameIdleMinutes as number,
    maxChannels,
    inviteEvictionIdleMinutes: inviteEvictionIdleMinutes as number,
  });
}

function validateChannels(raw: unknown, botPath: string): string[] {
  const path = `${botPath}.channels`;
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new Error(`${path} must be a nonempty array`);
  }
  const values = raw as unknown[];
  const channels: string[] = [];
  const keys = new Set<string>();
  for (let index = 0; index < values.length; index++) {
    const channel = values[index];
    if (
      typeof channel !== "string" ||
      channel.length < 2 ||
      new TextEncoder().encode(channel).length > MAX_CHANNEL_LENGTH ||
      !/^[#&+!]/u.test(channel) ||
      /[\s,:\0-\x1f\x7f]/u.test(channel)
    ) {
      throw new Error(`${path}[${index}] is not a valid IRC channel`);
    }
    const key = normalizedKey(channel);
    if (keys.has(key)) {
      throw new Error(`${path}[${index}] is duplicated`);
    }
    keys.add(key);
    channels.push(channel);
  }
  return Object.freeze(channels) as string[];
}

function validateIdent(raw: unknown, botPath: string): string {
  if (raw === undefined) {
    return DEFAULT_IDENT;
  }
  const path = `${botPath}.ident`;
  if (typeof raw !== "string" || !/^[a-z0-9_-]+$/iu.test(raw) || raw.length > 20) {
    throw new Error(`${path} must be 1-20 characters of letters, digits, "-" or "_"`);
  }
  return raw;
}

function validateRealname(raw: unknown, botPath: string): string {
  if (raw === undefined) {
    return DEFAULT_REALNAME;
  }
  const path = `${botPath}.realname`;
  if (
    typeof raw !== "string" ||
    raw === "" ||
    new TextEncoder().encode(raw).length > MAX_REALNAME_BYTES ||
    /[\0\r\n]/u.test(raw)
  ) {
    throw new Error(
      `${path} must be 1-${MAX_REALNAME_BYTES} UTF-8 bytes without NUL or line breaks`
    );
  }
  return raw;
}

function validateAccountAuth(raw: unknown, botPath: string): AccountAuth | undefined {
  if (raw === undefined) {
    return undefined;
  }
  const path = `${botPath}.accountAuth`;
  const value = objectValue(raw, path);
  rejectUnknownKeys(value, ACCOUNT_AUTH_KEYS, path);
  if (value.method !== "sasl") {
    throw new Error(`${path}.method is unsupported`);
  }
  if (!token(value.username)) {
    throw new Error(`${path}.username is invalid`);
  }
  if (!validPassword(value.password)) {
    throw new Error(`${path}.password is invalid`);
  }
  return Object.freeze({
    method: "sasl",
    username: value.username,
    password: value.password,
  });
}

function validateServiceAuth(raw: unknown, botPath: string): ServiceAuth | undefined {
  if (raw === undefined) {
    return undefined;
  }
  const path = `${botPath}.serviceAuth`;
  const value = objectValue(raw, path);
  rejectUnknownKeys(value, SERVICE_AUTH_KEYS, path);
  if (!token(value.target)) {
    throw new Error(`${path}.target is invalid`);
  }
  if (!tokenPassword(value.password)) {
    throw new Error(`${path}.password is invalid`);
  }
  if (value.command !== undefined && !token(value.command)) {
    throw new Error(`${path}.command is invalid`);
  }
  if (value.account !== undefined && !token(value.account)) {
    throw new Error(`${path}.account is invalid`);
  }
  return Object.freeze({
    target: value.target,
    password: value.password,
    ...(typeof value.command === "string" ? { command: value.command } : {}),
    ...(typeof value.account === "string" ? { account: value.account } : {}),
  });
}

function optionalPassword(value: unknown, path: string): string | undefined {
  if (value === undefined) {
    return undefined;
  }
  if (!validPassword(value)) {
    throw new Error(`${path} is invalid`);
  }
  return value;
}

function objectValue(raw: unknown, path: string): Record<string, unknown> {
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
    throw new Error(`${path} must be an object`);
  }
  return raw as Record<string, unknown>;
}

function rejectUnknownKeys(
  value: Record<string, unknown>,
  allowed: readonly string[],
  path: string
): void {
  const known = new Set(allowed);
  const unknown = Object.keys(value).find((key) => !known.has(key));
  if (unknown !== undefined) {
    throw new Error(`${path}.${unknown} is not supported`);
  }
}

function nickToken(value: unknown): value is string {
  return typeof value === "string" && value !== "" && !/[\s,:\0-\x1f\x7f]/u.test(value);
}

function serverToken(value: unknown): value is string {
  return typeof value === "string" && value !== "" && !/[\s,\0-\x1f\x7f]/u.test(value);
}

function token(value: unknown): value is string {
  return typeof value === "string" && value !== "" && !/[\s,\0-\x1f\x7f]/u.test(value);
}

function validPassword(value: unknown): value is string {
  return typeof value === "string" && value !== "" && value !== "****" && !/[\r\n\0]/u.test(value);
}

function tokenPassword(value: unknown): value is string {
  return validPassword(value) && !/[\s\0-\x1f\x7f]/u.test(value);
}

function integerInRange(value: unknown, minimum: number, maximum: number): value is number {
  return (
    typeof value === "number" && Number.isSafeInteger(value) && value >= minimum && value <= maximum
  );
}

function validPath(value: unknown): value is string {
  return typeof value === "string" && value.trim() !== "" && !/[\r\n\0]/u.test(value);
}

function normalizedKey(value: string): string {
  return value.normalize("NFC").toLocaleLowerCase("en-US");
}

function freezeConfig(config: Config): Config {
  Object.freeze(config.bots);
  return Object.freeze(config);
}
