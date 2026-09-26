import pino from "pino";
import type { Logger } from "./logging-port.js";

export type { Logger } from "./logging-port.js";

export function createLogger(): Logger {
  return pino(
    {
      level: process.env.WIT_LOG_LEVEL ?? "info",
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    pino.destination(2)
  ) as unknown as Logger;
}
