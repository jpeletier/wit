import { resolve } from "node:path";
import { WitBot } from "./app/bot.js";
import { runQuestionMaintenance } from "./app/maintenance.js";
import { systemClock, systemRandom } from "./core/ports.js";
import { openDatabase } from "./db/database.js";
import { DictionaryRepository, GameRepository, QuestionRepository } from "./db/repositories.js";
import { loadConfig, selectDatabasePath } from "./config.js";
import { IrcClientAdapter } from "./irc/client-adapter.js";
import { enableTlsServerName } from "./irc/tls-sni.js";
import { createLogger } from "./logging.js";

const log = createLogger().child({ module: "service" });
enableTlsServerName();

const config = loadConfig(resolve(process.env.WIT_CONFIG ?? "data/config.json"));
log.info({ bots: config.bots.length }, "Wit starting");
const database = openDatabase(
  resolve(selectDatabasePath(config.database, process.env.WIT_DATABASE))
);
log.info({}, "Runtime database ready");
const games = new GameRepository(database, systemClock);
const questions = new QuestionRepository(database, systemRandom);
const dictionary = new DictionaryRepository(database);
const bots = config.bots.map((botConfig) => {
  const context = { networkId: botConfig.networkId, bot: botConfig.nick };
  const irc = new IrcClientAdapter(botConfig, log.child({ module: "irc.connection", ...context }));
  const bot = new WitBot(
    irc,
    games,
    questions,
    dictionary,
    systemClock,
    systemRandom,
    {
      networkId: botConfig.networkId,
      welcomeOnJoin: config.welcomeOnJoin,
      configuredChannels: botConfig.channels,
      channelLifecycle: botConfig.channelLifecycle,
    },
    log.child({ module: "bot", ...context })
  );
  return bot;
});

await Promise.all(bots.map((bot) => bot.start()));
const questionMaintenance = setInterval(
  () =>
    runQuestionMaintenance(
      () => questions.age(),
      (message) => log.error({ module: "maintenance.questions" }, message)
    ),
  60_000
);
let shuttingDown = false;
const shutdown = (): void => {
  if (shuttingDown) {
    return;
  }
  shuttingDown = true;
  log.info({}, "Wit shutting down");
  clearInterval(questionMaintenance);
  for (const bot of bots) {
    bot.stop();
  }
  database.close();
  log.info({}, "Wit stopped");
};
process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
