import { createRequire, syncBuiltinESMExports } from "node:module";
import { isIP } from "node:net";
import type * as tls from "node:tls";
import type { ConnectionOptions } from "node:tls";

const require = createRequire(import.meta.url);
const tlsModule = require("node:tls") as typeof tls;
let enabled = false;

export function enableTlsServerName(): void {
  if (enabled) {
    return;
  }
  enabled = true;
  const original = tlsModule.connect.bind(tlsModule);
  tlsModule.connect = ((...args: unknown[]) => {
    if (typeof args[0] === "object" && args[0] !== null) {
      const merged = withDefaultServerName(args[0] as ConnectionOptions);
      if (merged !== undefined) {
        args[0] = merged;
      }
    }
    return original(...(args as Parameters<typeof tls.connect>));
  }) as typeof tls.connect;
  syncBuiltinESMExports();
}

export function withDefaultServerName(options: ConnectionOptions): ConnectionOptions | undefined {
  if (typeof options.host !== "string" || options.servername !== undefined) {
    return undefined;
  }
  const { host } = options;
  if (host === "" || isIP(host) !== 0) {
    return undefined;
  }
  return { ...options, servername: host };
}
