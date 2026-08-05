import { resolve } from "node:path";
import { WitBot } from "./app/bot.js";
import { systemClock, systemRandom } from "./core/ports.js";
import { openDatabase } from "./db/database.js";
import {
  DictionaryRepository,
  GameRepository,
  QuestionRepository,
} from "./db/repositories.js";
import { loadConfig } from "./config.js";
import { IrcClientAdapter } from "./irc/client-adapter.js";

const config = loadConfig(resolve(process.env.WIT_CONFIG ?? "config.json"));
const bots = config.bots.map((botConfig) => {
  const database = openDatabase(
    resolve(process.env.WIT_DATABASE ?? config.database),
  );
  const irc = new IrcClientAdapter(botConfig);
  const bot = new WitBot(
    irc,
    new GameRepository(database, systemClock),
    new QuestionRepository(database, systemRandom),
    new DictionaryRepository(database),
    systemClock,
    systemRandom,
    { networkId: botConfig.networkId, welcomeOnJoin: config.welcomeOnJoin },
  );
  return { bot, database };
});

await Promise.all(bots.map(({ bot }) => bot.start()));
const shutdown = (): void => {
  for (const { bot, database } of bots) {
    bot.stop();
    database.close();
  }
};
process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
