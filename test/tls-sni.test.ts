import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { connect as tlsConnect, createServer, type Server, type TLSSocket } from "node:tls";
import { enableTlsServerName, withDefaultServerName } from "../src/irc/tls-sni.js";

function selfSigned(): { key: string; cert: string } {
  const dir = mkdtempSync(join(tmpdir(), "wit-tls-"));
  const keyPath = join(dir, "key.pem");
  const certPath = join(dir, "cert.pem");
  execFileSync("openssl", [
    "req",
    "-x509",
    "-newkey",
    "rsa:2048",
    "-keyout",
    keyPath,
    "-out",
    certPath,
    "-days",
    "1",
    "-nodes",
    "-subj",
    "/CN=localhost",
  ]);
  return { key: readFileSync(keyPath, "utf8"), cert: readFileSync(certPath, "utf8") };
}

function startSniServer(
  names: string[],
  credentials: { key: string; cert: string }
): Promise<Server> {
  const server = createServer(
    {
      key: credentials.key,
      cert: credentials.cert,
      SNICallback: (name, callback) => {
        names.push(name);
        callback(null, undefined);
      },
    },
    (socket) => socket.destroy()
  );
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

function connectOnce(port: number): Promise<void> {
  return new Promise((resolve, reject) => {
    const socket: TLSSocket = tlsConnect(
      { host: "localhost", port, rejectUnauthorized: false, timeout: 5000 },
      () => {
        socket.destroy();
        resolve();
      }
    );
    socket.once("error", reject);
    socket.once("timeout", () => {
      socket.destroy();
      reject(new Error("TLS connection timed out"));
    });
  });
}

test("withDefaultServerName adds servername from host for DNS names", () => {
  assert.deepEqual(withDefaultServerName({ host: "irc.chathispano.com", port: 6697 }), {
    host: "irc.chathispano.com",
    port: 6697,
    servername: "irc.chathispano.com",
  });
});

test("withDefaultServerName leaves explicit servername, IP hosts, and missing hosts untouched", () => {
  assert.equal(
    withDefaultServerName({ host: "irc.chathispano.com", servername: "a.example" }),
    undefined
  );
  assert.equal(withDefaultServerName({ host: "195.234.61.184", port: 6697 }), undefined);
  assert.equal(withDefaultServerName({ port: 6697 }), undefined);
});

test("enableTlsServerName makes tls.connect send SNI for hostname connections", async () => {
  const names: string[] = [];
  const credentials = selfSigned();
  const server = await startSniServer(names, credentials);
  const port = (server.address() as { port: number }).port;
  enableTlsServerName();
  await connectOnce(port);
  server.close();
  assert.deepEqual(names, ["localhost"]);
});
