import { resolve } from "node:path";
import { WitBot } from "./app/bot.js";
import { runQuestionMaintenance } from "./app/maintenance.js";
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
const database = openDatabase(
  resolve(process.env.WIT_DATABASE ?? config.database),
);
const games = new GameRepository(database, systemClock);
const questions = new QuestionRepository(database, systemRandom);
const dictionary = new DictionaryRepository(database);
const bots = config.bots.map((botConfig) => {
  const irc = new IrcClientAdapter(botConfig);
  const bot = new WitBot(
    irc,
    games,
    questions,
    dictionary,
    systemClock,
    systemRandom,
    { networkId: botConfig.networkId, welcomeOnJoin: config.welcomeOnJoin },
  );
  return bot;
});

await Promise.all(bots.map((bot) => bot.start()));
const questionMaintenance = setInterval(
  () => runQuestionMaintenance(() => questions.age()),
  60_000,
);
let shuttingDown = false;
const shutdown = (): void => {
  if (shuttingDown) return;
  shuttingDown = true;
  clearInterval(questionMaintenance);
  for (const bot of bots) {
    bot.stop();
  }
  database.close();
};
process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
