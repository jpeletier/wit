import { readFileSync } from "node:fs";
import type { AccountAuth, ServiceAuth } from "./irc/auth.js";

export interface BotConfig {
  nick: string;
  server: string;
  port: number;
  tls: boolean;
  serverPassword?: string;
  accountAuth?: AccountAuth;
  serviceAuth?: ServiceAuth;
  networkId: number;
  channels: string[];
  outboundDelayMs?: number;
}
export interface Config {
  database: string;
  welcomeOnJoin: boolean;
  bots: BotConfig[];
}

export function loadConfig(path: string): Config {
  return parseConfig(JSON.parse(readFileSync(path, "utf8")));
}

export function parseConfig(raw: unknown): Config {
  if (typeof raw !== "object" || raw === null)
    throw new Error("Config must be an object");
  const value = raw as Record<string, unknown>;
  if (
    typeof value.database !== "string" ||
    !Array.isArray(value.bots) ||
    value.bots.length === 0
  )
    throw new Error("Config requires database and bots");
  const bots = value.bots.map((entry, index) => validateBot(entry, index));
  return {
    database: value.database,
    welcomeOnJoin: value.welcomeOnJoin !== false,
    bots,
  };
}

function validateBot(raw: unknown, index: number): BotConfig {
  if (typeof raw !== "object" || raw === null)
    throw new Error(`bots[${index}] must be an object`);
  const value = raw as Record<string, unknown>;
  if ("password" in value)
    throw new Error(`bots[${index}].password is unsupported`);
  const tls = value.tls !== false;
  const accountAuth = validateAccountAuth(value.accountAuth, index);
  const serviceAuth = validateServiceAuth(value.serviceAuth, index);
  const serverPassword = optionalPassword(
    value.serverPassword,
    `bots[${index}].serverPassword`,
  );
  if (
    typeof value.nick !== "string" ||
    typeof value.server !== "string" ||
    typeof value.port !== "number" ||
    typeof value.networkId !== "number" ||
    !Array.isArray(value.channels) ||
    !value.channels.every((item) => typeof item === "string") ||
    (value.outboundDelayMs !== undefined &&
      (typeof value.outboundDelayMs !== "number" ||
        !Number.isSafeInteger(value.outboundDelayMs) ||
        value.outboundDelayMs <= 0))
  )
    throw new Error(`bots[${index}] is invalid`);
  return {
    nick: value.nick,
    server: value.server,
    port: value.port,
    tls,
    networkId: value.networkId,
    channels: value.channels,
    ...(typeof value.outboundDelayMs === "number"
      ? { outboundDelayMs: value.outboundDelayMs }
      : {}),
    ...(serverPassword === undefined ? {} : { serverPassword }),
    ...(accountAuth === undefined ? {} : { accountAuth }),
    ...(serviceAuth === undefined ? {} : { serviceAuth }),
  };
}

function validateAccountAuth(
  raw: unknown,
  index: number,
): AccountAuth | undefined {
  if (raw === undefined) return undefined;
  if (typeof raw !== "object" || raw === null)
    throw new Error(`bots[${index}].accountAuth is invalid`);
  const value = raw as Record<string, unknown>;
  if (value.method === "sasl") {
    if (!token(value.username) || !validPassword(value.password))
      throw new Error(`bots[${index}].accountAuth is invalid`);
    return {
      method: "sasl",
      username: value.username,
      password: value.password,
    };
  }
  throw new Error(`bots[${index}].accountAuth method is unsupported`);
}

function validateServiceAuth(
  raw: unknown,
  index: number,
): ServiceAuth | undefined {
  if (raw === undefined) return undefined;
  if (typeof raw !== "object" || raw === null)
    throw new Error(`bots[${index}].serviceAuth is invalid`);
  const value = raw as Record<string, unknown>;
  if (
    !token(value.target) ||
    !token(value.password) ||
    (value.command !== undefined && !token(value.command)) ||
    (value.account !== undefined && !token(value.account))
  )
    throw new Error(`bots[${index}].serviceAuth is invalid`);
  return {
    target: value.target,
    password: value.password,
    ...(typeof value.command === "string" ? { command: value.command } : {}),
    ...(typeof value.account === "string" ? { account: value.account } : {}),
  };
}

function optionalPassword(value: unknown, field: string): string | undefined {
  if (value === undefined) return undefined;
  if (!validPassword(value)) throw new Error(`${field} is invalid`);
  return value;
}

function token(value: unknown): value is string {
  return typeof value === "string" && value !== "" && !/[\s\0]/u.test(value);
}

function validPassword(value: unknown): value is string {
  return typeof value === "string" && value !== "" && !/[\r\n\0]/u.test(value);
}
