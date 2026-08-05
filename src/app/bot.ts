import { calculate } from "../core/expression.js";
import { mirc } from "../core/format.js";
import type { Clock, RandomSource } from "../core/ports.js";
import { ircCasefold } from "../core/text.js";
import type {
  DictionaryRepository,
  GameRepository,
  QuestionRepository,
} from "../db/repositories.js";
import {
  generateLetters,
  generateNumbers,
  LetterRound,
  NumberRound,
} from "../games/cyl.js";
import { TriviaGame, triviaPoints, type TriviaEvent } from "../games/trivia.js";
import type { IrcEvent, IrcPort, IrcUser } from "../irc/port.js";

interface SessionBase {
  gameId: number;
  tournamentId: number;
  players: Map<string, number>;
  tick: number;
}
interface TriviaSession extends SessionBase {
  type: "trivia";
  game: TriviaGame;
}
interface CylSession extends SessionBase {
  type: "cyl";
  challenge: number;
  total: number;
  round: LetterRound | NumberRound | undefined;
}
type Session = TriviaSession | CylSession;

export interface BotOptions {
  networkId: number;
  welcomeOnJoin: boolean;
  triviaSubsetId?: number;
  cylSubsetId?: number;
}

const HELP = [
  "Wit es un bot de juegos para Trivial y Cifras y Letras.",
  "TRIVIAL #canal [5-30]  - comienza una partida",
  "CYL #canal [1-30]      - comienza Cifras y Letras",
  "TRIVIAL/CYL #canal STOP - detiene la partida (sólo operadores)",
  "DATE                    - muestra la hora del servidor",
  "En un canal usa ?expresión para mostrar un cálculo; los dados usan NdM.",
];

export class WitBot {
  readonly #sessions = new Map<string, Session>();
  readonly #nicks = new Map<string, string>();
  #timer?: NodeJS.Timeout;

  constructor(
    private readonly irc: IrcPort,
    private readonly games: GameRepository,
    private readonly questions: QuestionRepository,
    private readonly dictionary: DictionaryRepository,
    private readonly clock: Clock,
    private readonly random: RandomSource,
    private readonly options: BotOptions,
  ) {
    irc.onEvent((event) => this.handle(event));
  }

  async start(): Promise<void> {
    await this.irc.connect();
    this.#timer = setInterval(() => this.tick(), 1000);
  }

  stop(): void {
    if (this.#timer !== undefined) clearInterval(this.#timer);
    this.#endAll("Bot detenido");
    this.irc.disconnect();
  }

  handle(event: IrcEvent): void {
    switch (event.type) {
      case "privateMessage":
        this.#private(event.user, event.text);
        break;
      case "message":
        this.#channel(event.channel, event.user, event.text);
        break;
      case "join":
        this.#remember(event.user);
        if (!event.self && this.options.welcomeOnJoin)
          this.irc.notice(
            event.user.nick,
            `Bienvenido a ${event.channel}. Para obtener ayuda, escribe /msg ${this.irc.nick} HELP`,
          );
        break;
      case "nick":
        this.#nicks.set(event.user.identity, event.user.nick);
        break;
      case "part":
        if (event.self)
          this.#end(
            event.channel,
            "La partida terminó porque el bot salió del canal",
          );
        break;
      case "disconnected":
        this.#endAll("La partida terminó porque el bot se desconectó");
        break;
      case "registered":
      case "membership":
        break;
    }
  }

  tick(): void {
    for (const [channel, session] of this.#sessions) {
      session.tick++;
      try {
        if (session.type === "trivia") this.#triviaTick(channel, session);
        else this.#cylTick(channel, session);
      } catch (error) {
        this.irc.say(
          channel,
          `Error persistente: ${error instanceof Error ? error.message : String(error)}. La partida ha terminado.`,
        );
        this.#end(channel);
      }
    }
  }

  #private(user: IrcUser, text: string): void {
    this.#remember(user);
    const parts = text.trim().split(/\s+/u);
    const command = parts[0]?.toUpperCase() ?? "";
    if (command === "HELP") {
      for (const line of HELP) this.irc.notice(user.nick, line);
      return;
    }
    if (command === "DATE") {
      this.irc.notice(
        user.nick,
        `La hora en el servidor es ${this.clock.now().toLocaleString("es-ES")}`,
      );
      return;
    }
    if (command !== "TRIVIAL" && command !== "CYL") {
      this.irc.notice(user.nick, "Comando desconocido. Escribe HELP.");
      return;
    }
    const channel = parts[1];
    if (channel === undefined || !channel.startsWith("#")) {
      this.irc.notice(user.nick, "Sintaxis incorrecta. Escribe HELP.");
      return;
    }
    if (parts[2]?.toUpperCase() === "STOP") {
      if (!this.irc.isOperator(channel, user.nick)) {
        this.irc.notice(
          user.nick,
          `Sólo un operador (@) de ${channel} puede detener la partida.`,
        );
        return;
      }
      if (!this.#sessions.has(this.#key(channel))) {
        this.irc.notice(
          user.nick,
          `No hay ninguna partida activa en ${channel}.`,
        );
        return;
      }
      this.irc.say(
        channel,
        mirc.color(`--- Partida detenida por ${user.nick} ---`, 5),
      );
      this.#end(channel);
      return;
    }
    if (this.#sessions.has(this.#key(channel))) {
      this.irc.notice(user.nick, `Ya hay una partida activa en ${channel}.`);
      return;
    }
    const requested = Number(parts[2] ?? 20);
    const minimum = command === "TRIVIAL" ? 5 : 1;
    if (!Number.isInteger(requested) || requested < minimum || requested > 30) {
      this.irc.notice(user.nick, `El número debe estar entre ${minimum} y 30.`);
      return;
    }
    try {
      if (command === "TRIVIAL") this.#startTrivia(channel, user, requested);
      else this.#startCyl(channel, user, requested);
    } catch (error) {
      this.irc.notice(
        user.nick,
        `No se pudo iniciar la partida: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  #channel(channel: string, user: IrcUser, text: string): void {
    this.#remember(user);
    const session = this.#sessions.get(this.#key(channel));
    if (session?.type === "trivia") {
      const event = session.game.submit(user.nick, text);
      if (event?.type === "correct") {
        const playerId = this.#player(session, user);
        this.games.addScore(
          playerId,
          session.tournamentId,
          event.subjectId,
          event.points,
        );
        this.#showTrivia(channel, event);
      }
      return;
    }
    if (session?.type === "cyl" && session.round !== undefined) {
      this.#player(session, user);
      const accepted = session.round.submit(user.identity, user.nick, text);
      if (
        accepted &&
        session.round instanceof NumberRound &&
        (session.round.winner()?.distance ?? 1) < 0.001
      )
        session.tick = 60;
      return;
    }
    if (session === undefined && (text.startsWith("?") || /^\d/u.test(text))) {
      const forced = text.startsWith("?");
      const expression = forced ? text.slice(1) : text;
      try {
        const value = calculate(expression, {
          dice: true,
          random: () => this.random.next(),
        });
        if (forced || String(value) !== expression.trim())
          this.irc.say(channel, `${user.nick}: ${expression}=${value}`);
      } catch {
        /* ordinary channel text is not an error response */
      }
    }
  }

  #startTrivia(channel: string, user: IrcUser, count: number): void {
    const subsetId = this.options.triviaSubsetId ?? 1;
    const tournament = this.games.ensureTournament(
      this.options.networkId,
      channel,
      1,
      subsetId,
    );
    const multiplier = this.questions.multiplier(subsetId);
    const gameId = this.games.createGame(
      tournament.tournamentId,
      count,
      "Trivial",
    );
    const game = new TriviaGame(
      this.questions.select(subsetId, count),
      multiplier,
      this.clock,
    );
    this.#sessions.set(this.#key(channel), {
      type: "trivia",
      gameId,
      tournamentId: tournament.tournamentId,
      players: new Map(),
      tick: 0,
      game,
    });
    this.irc.notice(user.nick, `Trivial iniciado en ${channel}`);
    this.irc.say(
      channel,
      `\u00038,1 wIt TrIvIa \u0003 Comienza una nueva partida de ${count} preguntas iniciada por ${mirc.color(user.nick, 5)}`,
    );
    this.irc.say(
      channel,
      `La puntuación máxima por respuesta es de ${mirc.color(String(triviaPoints(5, multiplier)), 5)} puntos.`,
    );
  }

  #startCyl(channel: string, user: IrcUser, total: number): void {
    const tournament = this.games.ensureTournament(
      this.options.networkId,
      channel,
      2,
      this.options.cylSubsetId ?? 34,
    );
    const gameId = this.games.createGame(
      tournament.tournamentId,
      total,
      "Cifras y Letras",
    );
    this.#sessions.set(this.#key(channel), {
      type: "cyl",
      gameId,
      tournamentId: tournament.tournamentId,
      players: new Map(),
      tick: 0,
      challenge: 0,
      total,
      round: undefined,
    });
    this.irc.notice(user.nick, `Cifras y Letras iniciado en ${channel}`);
    this.irc.say(
      channel,
      `\u00038,1 wIt C&L \u0003 Comienza una nueva partida de C&L iniciada por ${mirc.color(user.nick, 5)}`,
    );
  }

  #triviaTick(channel: string, session: TriviaSession): void {
    for (const event of session.game.tick()) this.#showTrivia(channel, event);
  }
  #showTrivia(channel: string, event: TriviaEvent): void {
    switch (event.type) {
      case "question":
        this.irc.say(
          channel,
          `Pregunta ${event.number}/${event.total}. TEMA: ${event.question.subject}.`,
        );
        this.irc.say(
          channel,
          `${mirc.color(event.question.text, 2)} (${event.words} pal.)`,
        );
        this.irc.say(channel, `-> ${event.hint}`);
        break;
      case "hint":
        this.irc.say(
          channel,
          `${event.level === 1 ? "Una" : "Otra"} pista: ${event.text}`,
        );
        break;
      case "correct":
        this.irc.say(
          channel,
          mirc.color(
            `¡¡${mirc.bold(event.nick)} acertó en ${event.seconds} segundos!! La respuesta era ${mirc.bold(event.answer)}. ${event.points} puntos más para ${event.nick}`,
            7,
          ),
        );
        break;
      case "timeout":
        this.irc.say(
          channel,
          mirc.color(
            `Se acabó el tiempo. La respuesta era ${mirc.bold(event.answer)}`,
            7,
          ),
        );
        break;
      case "complete":
        this.irc.say(channel, "Acabó la partida de trivial.");
        this.#end(channel);
        break;
    }
  }

  #cylTick(channel: string, session: CylSession): void {
    if (session.tick === 5) {
      session.challenge++;
      if (session.challenge % 4 === 0) {
        const generated = generateNumbers(this.random);
        session.round = new NumberRound(generated.numbers, generated.target);
        this.irc.say(channel, `Desafío #${session.challenge} a CIFRAS`);
        this.irc.say(
          channel,
          `Puedes usar estas cifras: ${generated.numbers.join(" ")} para conseguir el ${generated.target}`,
        );
      } else {
        const letters = generateLetters(this.random);
        session.round = new LetterRound(letters, (key) =>
          this.dictionary.lookup(key),
        );
        this.irc.say(channel, `Desafío #${session.challenge} a LETRAS`);
        this.irc.say(channel, `Puedes usar estas letras: ${letters.join(" ")}`);
      }
    }
    if (session.tick === 40 && session.round !== undefined)
      this.irc.say(channel, "20 segundos ...");
    if (session.tick < 60 || session.round === undefined) return;
    if (session.round instanceof LetterRound) {
      const winners = session.round.winners();
      if (winners.length === 0)
        this.irc.say(
          channel,
          "Se acabó el tiempo. Nadie supo construir una palabra.",
        );
      else {
        const definition = session.round.definition();
        this.irc.say(
          channel,
          `${mirc.bold(winners[0]!.entry.word)} (${winners[0]!.nick} +${winners[0]!.score})${definition === undefined ? "" : `: "${definition}"`}`,
        );
        for (const winner of winners)
          this.games.addScore(
            session.players.get(winner.identity)!,
            session.tournamentId,
            98,
            winner.score,
          );
      }
    } else {
      const winner = session.round.winner();
      if (winner === undefined)
        this.irc.say(channel, "Se acabó el tiempo. Nadie consiguió la cifra.");
      else {
        this.irc.say(
          channel,
          `${winner.nick} ${winner.distance < 0.001 ? "consiguió el número exacto" : "fue quien más se aproximó"}. ${winner.expression} = ${winner.value}`,
        );
        this.games.addScore(
          session.players.get(winner.identity)!,
          session.tournamentId,
          97,
          winner.score,
        );
      }
    }
    session.round = undefined;
    session.tick = 0;
    if (session.challenge >= session.total) {
      this.irc.say(channel, "Acabó la partida de C&L.");
      this.#end(channel);
    }
  }

  #player(session: SessionBase, user: IrcUser): number {
    const existing = session.players.get(user.identity);
    if (existing !== undefined) return existing;
    const id = this.games.player(this.options.networkId, user.nick);
    session.players.set(user.identity, id);
    return id;
  }
  #remember(user: IrcUser): void {
    this.#nicks.set(user.identity, user.nick);
  }
  #key(channel: string): string {
    return ircCasefold(channel, this.irc.caseMapping);
  }
  #end(channel: string, message?: string): void {
    const key = this.#key(channel);
    const session = this.#sessions.get(key);
    if (session === undefined) return;
    if (message !== undefined) this.irc.say(channel, message);
    this.games.finishGame(session.gameId);
    this.#sessions.delete(key);
  }
  #endAll(message: string): void {
    for (const channel of [...this.#sessions.keys()])
      this.#end(channel, message);
  }
}
