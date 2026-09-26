export interface Logger {
  child(bindings: Record<string, unknown>): Logger;
  debug(bindings: Record<string, unknown>, message: string): void;
  error(bindings: Record<string, unknown>, message: string): void;
  info(bindings: Record<string, unknown>, message: string): void;
  warn(bindings: Record<string, unknown>, message: string): void;
}

export const silentLogger: Logger = {
  child: () => silentLogger,
  debug: () => {},
  error: () => {},
  info: () => {},
  warn: () => {},
};
