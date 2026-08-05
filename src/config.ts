import { readFileSync } from "node:fs";

export interface BotConfig {
  nick: string;
  server: string;
  port: number;
  tls: boolean;
  password?: string;
  networkId: number;
  channels: string[];
}
export interface Config {
  database: string;
  welcomeOnJoin: boolean;
  bots: BotConfig[];
}

export function loadConfig(path: string): Config {
  const raw: unknown = JSON.parse(readFileSync(path, "utf8"));
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
  if (
    typeof value.nick !== "string" ||
    typeof value.server !== "string" ||
    typeof value.port !== "number" ||
    typeof value.networkId !== "number" ||
    !Array.isArray(value.channels) ||
    !value.channels.every((item) => typeof item === "string")
  )
    throw new Error(`bots[${index}] is invalid`);
  return {
    nick: value.nick,
    server: value.server,
    port: value.port,
    tls: value.tls !== false,
    networkId: value.networkId,
    channels: value.channels,
    ...(typeof value.password === "string" ? { password: value.password } : {}),
  };
}
