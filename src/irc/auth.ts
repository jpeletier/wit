import type { ClientOptions } from "irc-client-ts";
import { sanitizeIrcText } from "../core/format.js";

export interface AccountAuth {
  method: "sasl";
  username: string;
  password: string;
}

export interface ServiceAuth {
  target: string;
  command?: string;
  account?: string;
  password: string;
}

export interface ClientOptionConfig {
  nick: string;
  serverPassword?: string;
  accountAuth?: AccountAuth;
}

export interface ServiceAuthCommand {
  target: string;
  text: string;
}

export function buildClientOptions(config: ClientOptionConfig): ClientOptions {
  const accountOptions =
    config.accountAuth?.method === "sasl"
      ? {
          authMethod: "sasl" as const,
          username: config.accountAuth.username,
          password: config.accountAuth.password,
        }
      : {};
  return {
    nick: config.nick,
    bot: true,
    reconnect: false,
    ctcpReplies: { version: "Wit TypeScript" },
    ...(config.serverPassword === undefined ? {} : { serverPassword: config.serverPassword }),
    ...accountOptions,
  };
}

export function buildServiceAuthCommand(
  config: ServiceAuth | undefined
): ServiceAuthCommand | undefined {
  if (config === undefined) {
    return undefined;
  }
  if (
    !authToken(config.target) ||
    !authToken(config.password) ||
    (config.command !== undefined && !authToken(config.command)) ||
    (config.account !== undefined && !authToken(config.account))
  ) {
    throw new Error("Service authentication configuration is invalid");
  }
  return {
    target: sanitizeIrcText(config.target),
    text: sanitizeIrcText(
      [config.command ?? "IDENTIFY", config.account, config.password]
        .filter((part) => part !== undefined)
        .join(" ")
    ),
  };
}

function authToken(value: string): boolean {
  return value !== "" && !/[\s\0]/u.test(value);
}
