import { calculate } from "../core/expression.js";
import { mirc } from "../core/format.js";
import type { Clock, RandomSource } from "../core/ports.js";
import { ircCasefold } from "../core/text.js";
import type {
  DictionaryRepository,
  GameRepository,
  QuestionRepository,
  TournamentContext,
} from "../db/repositories.js";
import {
  generateLetters,
  generateNumbers,
  LetterRound,
  NumberRound,
  type LetterWinner,
} from "../games/cyl.js";
import { TriviaGame, triviaPoints, type TriviaEvent } from "../games/trivia.js";
import type { IrcEvent, IrcPort, IrcUser } from "../irc/port.js";

interface PlayerState {
  id: number;
  identity: string;
  nick: string;
  total: number;
  order: number;
}
interface SessionBase {
  gameId: number;
  tournamentId: number;
  players: Map<string, PlayerState>;
  nextOrder: number;
  tick: number;
  channel: string;
  count: number;
}
interface TriviaSession extends SessionBase {
  type: "trivia";
  game: TriviaGame;
}
interface CylSession extends SessionBase {
  type: "cyl";
  challenge: number;
  round: LetterRound | NumberRound | undefined;
}
type Session = TriviaSession | CylSession;

export interface BotOptions {
  networkId: number;
  welcomeOnJoin: boolean;
}

const HELP = [
  "Wit IRC Bot, por Javier Peletier Ribera.",
  "Wit es un bot de juegos que te permitirá jugar al Trivial y a Cifras y Letras en IRC",
  "Comandos disponibles:",
  "HELP                        : Muestra la ayuda.",
  "TRIVIAL #canal numpreguntas : Comienza una partida de trivial.",
  "TRIVIAL #canal STOP         : Detiene una partida de trivial.",
  "CYL #canal numdesafíos      : Comienza una partida de Cifras y Letras.",
  "CYL #canal STOP             : Detiene una partida de Cifras y Letras.",
  "DATE                        : Muestra la hora en el servidor.",
];

export class WitBot {
  readonly #sessions = new Map<string, Session>();
  #timer: NodeJS.Timeout | undefined;
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
    this.#timer = setInterval(() => this.tick(), 1_000);
  }
  stop(): void {
    if (this.#timer !== undefined) clearInterval(this.#timer);
    this.#endAll("Bot detenido");
    this.irc.disconnect();
  }

  handle(event: IrcEvent): void {
    try {
      this.#dispatch(event);
    } catch (error) {
      const channel = "channel" in event ? event.channel : undefined;
      if (channel !== undefined && this.#sessions.has(this.#key(channel)))
        this.#fail(channel, error);
      else if (event.type === "privateMessage")
        this.irc.notice(
          event.user.nick,
          `No se pudo ejecutar el comando: ${message(error)}`,
        );
    }
  }

  #dispatch(event: IrcEvent): void {
    switch (event.type) {
      case "privateMessage":
        this.#private(event.user, event.text);
        break;
      case "message":
        this.#channel(event.channel, event.user, event.text);
        break;
      case "join":
        if (!event.self && this.options.welcomeOnJoin)
          this.irc.notice(
            event.user.nick,
            `Bienvenido a ${event.channel}. Para obtener ayuda, escribe /msg ${this.irc.nick} HELP`,
          );
        break;
      case "nick":
        this.#rename(event.user);
        break;
      case "part":
        if (event.self)
          this.#end(
            event.channel,
            "La partida terminó porque el bot salió del canal",
          );
        break;
      case "kick":
        if (event.self) {
          if (this.#sessions.get(this.#key(event.channel))?.type === "trivia")
            this.irc.notice(
              event.user.nick,
              `Para quitar el trivial sin patearme, utiliza en un privado el comando TRIVIAL ${event.channel} STOP`,
            );
          this.#end(
            event.channel,
            "La partida terminó porque el bot fue expulsado del canal",
          );
        }
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
    for (const session of [...this.#sessions.values()]) {
      try {
        session.tick++;
        if (session.type === "trivia") this.#triviaTick(session);
        else this.#cylTick(session);
      } catch (error) {
        this.#fail(session.channel, error);
      }
    }
  }

  #private(user: IrcUser, text: string): void {
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
    if (command !== "TRIVIAL" && command !== "CYL") return;
    const type = command === "TRIVIAL" ? "trivia" : "cyl";
    const channel = parts[1];
    if (channel === undefined || !channel.startsWith("#")) {
      this.irc.notice(user.nick, "Sintaxis incorrecta. Escribe HELP");
      return;
    }
    if (!this.irc.isJoined(channel)) {
      this.irc.notice(user.nick, `Primero debo estar en el canal ${channel}.`);
      return;
    }
    if (parts[2]?.toUpperCase() === "STOP") {
      const session = this.#sessions.get(this.#key(channel));
      if (session?.type !== type) {
        this.irc.notice(
          user.nick,
          `No hay ninguna partida activa de ${command === "TRIVIAL" ? "trivial" : "Cifras y Letras"} en ${channel}`,
        );
        return;
      }
      if (!this.irc.isOperator(channel, user.nick)) {
        this.irc.notice(
          user.nick,
          `Sólo un operador (@) de ${channel} puede detener la partida.`,
        );
        return;
      }
      this.irc.say(
        channel,
        mirc.color(
          `--- Partida detenida por ${mirc.underline(user.nick)} ---`,
          4,
        ),
      );
      this.#end(channel);
      return;
    }
    if (this.#sessions.has(this.#key(channel))) {
      this.irc.notice(user.nick, `Ya hay una partida activa en ${channel}.`);
      return;
    }
    const parsed = Number(parts[2]);
    let count =
      parts[2] === undefined || !Number.isFinite(parsed)
        ? 20
        : Math.trunc(parsed);
    if (type === "trivia" && count < 5) count = 5;
    if (type === "cyl" && count <= 0) {
      this.irc.notice(user.nick, "El número de desafíos debe ser positivo.");
      return;
    }
    if (count > 30) {
      this.irc.notice(
        user.nick,
        `El máximo son 30 ${type === "trivia" ? "preguntas" : "desafíos"}`,
      );
      return;
    }
    const triviaCount = [...this.#sessions.values()].filter(
      (session) => session.type === "trivia",
    ).length;
    if ((type === "trivia" || type === "cyl") && triviaCount >= 2) {
      this.irc.notice(
        user.nick,
        `Estoy en demasiados ${type === "trivia" ? "trivials" : "juegos"}. Inténtalo de nuevo más tarde.`,
      );
      return;
    }
    if (type === "trivia") this.#startTrivia(channel, user, count);
    else this.#startCyl(channel, user, count);
  }

  #startTrivia(channel: string, user: IrcUser, count: number): void {
    const context = this.games.prepareTournament(
      this.options.networkId,
      channel,
      1,
    );
    this.questions.validateSubset(context.subsetId);
    const game = new TriviaGame(
      count,
      context.multiplier,
      () => this.questions.next(context.subsetId),
      this.random,
    );
    const gameId = this.games.createGame(
      context.tournamentId,
      count,
      "Trivial",
    );
    const session: TriviaSession = {
      type: "trivia",
      gameId,
      tournamentId: context.tournamentId,
      players: new Map(),
      nextOrder: 0,
      tick: 0,
      channel,
      count,
      game,
    };
    this.#sessions.set(this.#key(channel), session);
    try {
      this.irc.notice(user.nick, `Trivial2 iniciado en ${channel}`);
      this.#announceContext(channel, context, "trivial");
      this.irc.say(
        channel,
        `\u00038,1 wIt TrIvIa \u0003 Comienza una nueva partida de ${count} preguntas iniciada por${mirc.color(` ${user.nick}`, 4)}`,
      );
      this.irc.say(
        channel,
        `Torneo${mirc.color(` ${context.tournamentDescription}`, 12)} Preguntas:${mirc.color(` ${context.subsetDescription}`, 12)}`,
      );
      this.irc.say(
        channel,
        `La puntuación máxima por respuesta es de${mirc.color(` ${triviaPoints(5, context.multiplier)}`, 4)} puntos.`,
      );
      this.irc.say(channel, " ");
    } catch (error) {
      this.#end(channel);
      throw error;
    }
  }

  #startCyl(channel: string, user: IrcUser, count: number): void {
    const context = this.games.prepareTournament(
      this.options.networkId,
      channel,
      2,
    );
    const gameId = this.games.createGame(
      context.tournamentId,
      count,
      "Cifras y Letras",
    );
    const session: CylSession = {
      type: "cyl",
      gameId,
      tournamentId: context.tournamentId,
      players: new Map(),
      nextOrder: 0,
      tick: 0,
      channel,
      count,
      challenge: 0,
      round: undefined,
    };
    this.#sessions.set(this.#key(channel), session);
    try {
      this.irc.notice(user.nick, `Cifras y Letras iniciado en ${channel}`);
      this.#announceContext(channel, context, "CYL");
      this.irc.say(
        channel,
        `\u00038,1 wIt C&L \u0003 Comienza una nueva partida de C&L iniciada por ${mirc.color(user.nick, 4)}`,
      );
    } catch (error) {
      this.#end(channel);
      throw error;
    }
  }

  #announceContext(
    channel: string,
    context: TournamentContext,
    game: string,
  ): void {
    if (context.firstGameInChannel)
      this.irc.say(
        channel,
        "Es la primera partida que se juega en este canal.",
      );
    if (context.newTournament)
      this.irc.say(
        channel,
        mirc.bold(`¡Bienvenidos a la ${context.leagueId}ª liga de ${game}!`),
      );
  }

  #channel(channel: string, user: IrcUser, text: string): void {
    const session = this.#sessions.get(this.#key(channel));
    if (session?.type === "trivia") {
      const event = session.game.submit(user.nick, text);
      if (event?.type === "correct") {
        const player = this.#player(session, user);
        try {
          this.games.addScore(
            player.id,
            session.tournamentId,
            event.question.subjectId,
            event.points,
          );
        } catch (error) {
          this.#fail(channel, error);
          return;
        }
        player.total += event.points;
        player.nick = user.nick;
        this.#showTrivia(session, event);
        this.#standings(session);
      }
      return;
    }
    if (session?.type === "cyl" && session.round !== undefined) {
      const accepted = session.round.submit(user.identity, user.nick, text);
      if (accepted) this.#player(session, user).nick = user.nick;
      if (
        accepted &&
        session.round instanceof NumberRound &&
        session.round.winner()?.distance === 0
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
        /* ordinary text */
      }
    }
  }

  #triviaTick(session: TriviaSession): void {
    for (const event of session.game.tick()) {
      this.#showTrivia(session, event);
      if (event.type === "timeout") this.#standings(session);
      if (event.type === "complete") this.#complete(session, "trivial");
    }
  }

  #showTrivia(session: TriviaSession, event: TriviaEvent): void {
    const channel = session.channel;
    if (event.type === "question") {
      this.irc.say(
        channel,
        ` \u000311,0\`%\u00030,11%,\u000312,11\`%\u000311,12%,\u00032,12\`%\u000312,2%,\u00038,2 wIt TrIvIa \u000312,2\`%\u00032,12%,\u000311,12\`%\u000312,11%,\u00030,11\`%\u000311,0%, ${mirc.color(` Pregunta ${event.number}/${event.total}. TEMA: ${event.question.subject}.`, 5)}`,
      );
      this.irc.say(
        channel,
        `${mirc.color(event.question.text, 2)} (${event.words} pal.)`,
      );
      this.irc.say(channel, `${mirc.color("->", 2)} ${event.hint}`);
    } else if (event.type === "hint") {
      this.irc.say(
        channel,
        `${mirc.color(event.level === 1 ? "Una pista:" : "Otra pista:", 3)}${event.level === 1 ? "  " : " "}${event.text}`,
      );
    } else if (event.type === "correct") {
      const seconds = event.seconds === 1 ? "segundo" : "segundos";
      const answer =
        event.submitted === event.answer
          ? event.answer
          : `${event.submitted}=${event.answer}`;
      this.irc.say(
        channel,
        `${mirc.color(`¡¡${mirc.bold(event.nick)} acertó en ${mirc.underline(String(event.seconds))} ${seconds}!!. La respuesta era ${mirc.bold(answer)}`, 7)}. ${mirc.bold(mirc.color(` ${event.points} puntos más para ${mirc.underline(event.nick)}`, 7))}${author(event.question)}`,
      );
    } else if (event.type === "timeout") {
      this.irc.say(
        channel,
        `${mirc.color(`Se acabó el tiempo. La respuesta era ${mirc.bold(event.question.answer)}`, 7)}${author(event.question)}`,
      );
    }
  }

  #cylTick(session: CylSession): void {
    if (session.tick === 5) {
      session.challenge++;
      if (session.challenge % 4 === 0) {
        const generated = generateNumbers(this.random);
        session.round = new NumberRound(generated.numbers, generated.target);
        this.irc.say(
          session.channel,
          `${cylHeader()} Desafío #${session.challenge} a CIFRAS`,
        );
        this.irc.say(
          session.channel,
          `Puedes usar estas cifras: ${mirc.color(` ${generated.numbers.join(" ")} `, 2)}para conseguir el ${mirc.color(` ${generated.target} `, 0, 1)}`,
        );
      } else {
        const letters = generateLetters(this.random);
        session.round = new LetterRound(letters, (key) =>
          this.dictionary.lookup(key),
        );
        this.irc.say(
          session.channel,
          `${cylHeader()} Desafío #${session.challenge} a LETRAS`,
        );
        this.irc.say(
          session.channel,
          `Puedes usar estas letras: ${mirc.color(`${letters.join(" ")} `, 2)}`,
        );
      }
    }
    if (session.tick === 40 && session.round !== undefined)
      this.irc.say(
        session.channel,
        `20 segundos ... ${this.#roundReminder(session.round)}`,
      );
    if (session.tick < 60 || session.round === undefined) return;
    const changes: Array<{
      player: PlayerState;
      subjectId: number;
      points: number;
    }> = [];
    if (session.round instanceof LetterRound) {
      const winners = session.round.winners();
      if (winners.length === 0)
        this.irc.say(
          session.channel,
          "Se acabó el tiempo. Nadie supo construir una palabra.",
        );
      else {
        this.irc.say(
          session.channel,
          this.#letterResult(session.round, winners),
        );
        for (const winner of winners)
          changes.push({
            player: this.#requiredPlayer(session, winner.identity),
            subjectId: 98,
            points: winner.score,
          });
      }
    } else {
      const winner = session.round.winner();
      if (winner === undefined)
        this.irc.say(
          session.channel,
          "Se acabó el tiempo. Nadie consiguió la cifra.",
        );
      else {
        this.irc.say(
          session.channel,
          `${mirc.color(`¡ ${winner.nick} ${winner.distance === 0 ? "consiguió el número exacto" : "fue el que más se aproximó"} !`, 7)}${mirc.color(` ${winner.expression} = ${winner.value}`, 2)}`,
        );
        changes.push({
          player: this.#requiredPlayer(session, winner.identity),
          subjectId: 97,
          points: winner.score,
        });
      }
    }
    try {
      this.games.addScores(
        session.tournamentId,
        changes.map((change) => ({
          playerId: change.player.id,
          subjectId: change.subjectId,
          points: change.points,
        })),
      );
    } catch (error) {
      this.#fail(session.channel, error);
      return;
    }
    for (const change of changes) change.player.total += change.points;
    this.#standings(
      session,
      new Map(changes.map((change) => [change.player.identity, change.points])),
    );
    session.round = undefined;
    session.tick = 0;
    if (session.challenge >= session.count) this.#complete(session, "C&L");
  }

  #roundReminder(round: LetterRound | NumberRound): string {
    return round instanceof LetterRound
      ? `Puedes usar estas letras: ${mirc.color(`${round.letters.join(" ")} `, 2)}`
      : `Puedes usar estas cifras: ${mirc.color(` ${round.numbers.join(" ")} `, 2)}para conseguir el ${mirc.color(` ${round.target} `, 0, 1)}`;
  }

  #letterResult(round: LetterRound, winners: readonly LetterWinner[]): string {
    const first = winners[0]!;
    let text = `${mirc.bold(first.entry.word)} (${first.nick} ${mirc.color(`+${first.score}`, 4)}) `;
    const definition = round.definition();
    if (definition !== undefined) text += `: "${definition}"`;
    if (winners.length > 1)
      text += `. Otras palabras: ${winners
        .slice(1)
        .map(
          (winner) =>
            `${winner.entry.word} (${winner.nick} ${mirc.color(`+${winner.score}`, 4)}) `,
        )
        .join("")}`;
    return text;
  }

  #standings(session: Session, deltas = new Map<string, number>()): void {
    const players = this.#ordered(session).slice(0, 3);
    if (players.length === 0) return;
    const prefix =
      session.type === "trivia"
        ? `${mirc.bold("Puntuación:")} `
        : "Puntuaciones: ";
    const body = players
      .map((player, index) =>
        session.type === "trivia"
          ? `${index + 1}.- ${mirc.color(player.nick, 4)} (${player.total})   `
          : `${index + 1}.- ${player.nick}: ${player.total} ${deltas.has(player.identity) ? `(${mirc.color(`+${deltas.get(player.identity)}`, 4)}) ` : ""}`,
      )
      .join("");
    this.irc.say(session.channel, prefix + body);
  }

  #complete(session: Session, gameName: "trivial" | "C&L"): void {
    this.irc.say(
      session.channel,
      `Acabó la partida de ${gameName}. Puntuaciones: `,
    );
    const ordered = this.#ordered(session).slice(0, 10);
    const rankings = new Map(
      this.games
        .rankings(
          session.tournamentId,
          ordered.map((player) => player.id),
        )
        .map((ranking) => [ranking.playerId, ranking]),
    );
    ordered.forEach((player, index) => {
      const ranking = rankings.get(player.id);
      const general =
        ranking === undefined
          ? ""
          : ` p. Clasificación General (${mirc.bold(`${ranking.rank}º`)}, ${ranking.total} p.)`;
      this.irc.say(
        session.channel,
        mirc.color(
          `${mirc.bold(`${index + 1}º`)} ${player.nick} ${player.total}${general}`,
          1,
          15,
        ),
      );
    });
    const command = session.type === "trivia" ? "TRIVIAL" : "CYL";
    this.irc.say(
      session.channel,
      `Para volver a jugar, dile a ${this.irc.nick} o a cualquier otro Wit en privado --> ${mirc.bold(`${command} ${session.channel} ${session.count}`)}`,
    );
    this.#end(session.channel);
  }

  #player(session: SessionBase, user: IrcUser): PlayerState {
    const existing = session.players.get(user.identity);
    if (existing !== undefined) return existing;
    const player = {
      id: this.games.player(this.options.networkId, user.nick),
      identity: user.identity,
      nick: user.nick,
      total: 0,
      order: session.nextOrder++,
    };
    session.players.set(user.identity, player);
    return player;
  }
  #requiredPlayer(session: SessionBase, identity: string): PlayerState {
    const player = session.players.get(identity);
    if (player === undefined)
      throw new Error(`Jugador ${identity} no resuelto`);
    return player;
  }
  #ordered(session: SessionBase): PlayerState[] {
    return [...session.players.values()].sort(
      (left, right) => right.total - left.total || left.order - right.order,
    );
  }
  #rename(user: IrcUser): void {
    for (const session of this.#sessions.values()) {
      const player = session.players.get(user.identity);
      if (player !== undefined) player.nick = user.nick;
    }
  }
  #key(channel: string): string {
    return ircCasefold(channel, this.irc.caseMapping);
  }
  #end(channel: string, text?: string): void {
    const key = this.#key(channel);
    const session = this.#sessions.get(key);
    if (session === undefined) return;
    this.#sessions.delete(key);
    if (text !== undefined) {
      try {
        this.irc.say(session.channel, text);
      } catch {
        /* finalization must still run when the connection is gone */
      }
    }
    try {
      this.games.finishGame(session.gameId);
    } catch (error) {
      this.irc.say(
        session.channel,
        `Error al finalizar la partida: ${message(error)}`,
      );
    }
  }
  #fail(channel: string, error: unknown): void {
    try {
      this.irc.say(
        channel,
        `Error persistente: ${message(error)}. La partida ha terminado.`,
      );
    } finally {
      this.#end(channel);
    }
  }
  #endAll(text: string): void {
    for (const session of [...this.#sessions.values()])
      this.#end(session.channel, text);
  }
}

function author(question: { author: string; id: number }): string {
  return `. ${mirc.color(`Autor de la pregunta: ${mirc.bold(question.author)} (${mirc.color(`#${question.id}`, 4)})`, 5)}`;
}
function cylHeader(): string {
  return "\u00037,0`%\u00030,7%,\u00034,7`%\u00037,4%,\u00031,4`%\u00034,1%,\u00038,1 wIt C&L \u00034,1`%\u00031,4%,\u00037,4`%\u00034,7%,\u00030,7`%\u00037,0%,\u0003";
}
function message(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
