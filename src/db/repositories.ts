import type { DatabaseSync } from "node:sqlite";
import type { Clock, RandomSource } from "../core/ports.js";
import { randomInt } from "../core/ports.js";
import { lookupKey } from "../core/text.js";
import type { DictionaryWord } from "../games/cyl.js";
import type { TriviaQuestion } from "../games/trivia.js";
import { transaction } from "./database.js";

export interface TournamentContext {
  channelId: number;
  tournamentId: number;
  leagueId: number;
  subsetId: number;
  tournamentDescription: string;
  subsetDescription: string;
  multiplier: number;
  firstGameInChannel: boolean;
  newTournament: boolean;
}

export interface ScoreChange {
  playerId: number;
  subjectId: number;
  points: number;
  answered?: number;
}
export interface TournamentRanking {
  playerId: number;
  total: number;
  rank: number;
}

export function legacyLeagueId(date: Date): number {
  return (date.getFullYear() - 2001) * 12 + date.getMonth() - 2;
}

export class GameRepository {
  constructor(
    private readonly database: DatabaseSync,
    private readonly clock: Clock,
  ) {}

  player(networkId: number, nick: string): number {
    const key = lookupKey(nick);
    return transaction(this.database, () => {
      const existing = this.database
        .prepare("SELECT id FROM players WHERE network_id=? AND nick_key=?")
        .get(networkId, key) as { id: number } | undefined;
      if (existing !== undefined) {
        this.database
          .prepare("UPDATE players SET nick=?,last_used=? WHERE id=?")
          .run(
            nick.normalize("NFC"),
            this.clock.now().toISOString(),
            existing.id,
          );
        return existing.id;
      }
      return Number(
        this.database
          .prepare(
            "INSERT INTO players(network_id,nick,nick_key,last_used) VALUES(?,?,?,?)",
          )
          .run(
            networkId,
            nick.normalize("NFC"),
            key,
            this.clock.now().toISOString(),
          ).lastInsertRowid,
      );
    });
  }

  prepareTournament(
    networkId: number,
    channelName: string,
    gameTypeId: 1 | 2,
  ): TournamentContext {
    return transaction(this.database, () => {
      const channelKey = lookupKey(channelName);
      let channel = this.database
        .prepare(
          "SELECT id,default_tournament_id defaultTournamentId FROM channels WHERE network_id=? AND name_key=?",
        )
        .get(networkId, channelKey) as
        { id: number; defaultTournamentId: number | null } | undefined;
      const firstGameInChannel = channel === undefined;
      if (channel === undefined) {
        channel = {
          id: Number(
            this.database
              .prepare(
                "INSERT INTO channels(network_id,name,name_key,last_used,default_tournament_id) VALUES(?,?,?,?,NULL)",
              )
              .run(
                networkId,
                channelName.normalize("NFC"),
                channelKey,
                this.clock.now().toISOString(),
              ).lastInsertRowid,
          ),
          defaultTournamentId: null,
        };
      }
      const leagueId = legacyLeagueId(this.clock.now());
      const leagueExists = this.database
        .prepare("SELECT 1 present FROM leagues WHERE id=?")
        .get(leagueId);
      if (leagueExists === undefined)
        this.database
          .prepare("INSERT INTO leagues(id,description) VALUES(?,?)")
          .run(leagueId, `${leagueId}ª Liga de trivial`);

      let tournament = this.database
        .prepare(
          `SELECT t.id,t.question_subset_id subsetId,t.description tournamentDescription,
        qs.description subsetDescription,qs.multiplier FROM tournaments t JOIN question_subsets qs ON qs.id=t.question_subset_id
        WHERE t.channel_id=? AND t.league_id=? AND t.game_type_id=? ORDER BY t.id LIMIT 1`,
        )
        .get(channel.id, leagueId, gameTypeId) as TournamentRow | undefined;
      let newTournament = false;
      if (tournament === undefined) {
        const subsetId =
          gameTypeId === 2
            ? 34
            : this.#inheritedTriviaSubset(channel.defaultTournamentId);
        const description = `Torneo oficial de ${channelName} en la ${leagueId}ª liga de ${gameTypeId === 1 ? "trivial" : "CYL"}.`;
        const id = Number(
          this.database
            .prepare(
              "INSERT INTO tournaments(description,date_init,date_end,channel_id,league_id,question_subset_id,game_type_id) VALUES(?,?,NULL,?,?,?,?)",
            )
            .run(
              description,
              this.clock.now().toISOString(),
              channel.id,
              leagueId,
              subsetId,
              gameTypeId,
            ).lastInsertRowid,
        );
        if (gameTypeId === 1)
          this.database
            .prepare("UPDATE channels SET default_tournament_id=? WHERE id=?")
            .run(id, channel.id);
        tournament = this.database
          .prepare(
            `SELECT t.id,t.question_subset_id subsetId,t.description tournamentDescription,
          qs.description subsetDescription,qs.multiplier FROM tournaments t JOIN question_subsets qs ON qs.id=t.question_subset_id WHERE t.id=?`,
          )
          .get(id) as unknown as TournamentRow;
        newTournament = true;
      } else if (
        gameTypeId === 1 &&
        channel.defaultTournamentId !== tournament.id
      ) {
        this.database
          .prepare("UPDATE channels SET default_tournament_id=? WHERE id=?")
          .run(tournament.id, channel.id);
      }
      return {
        channelId: channel.id,
        tournamentId: tournament.id,
        leagueId,
        subsetId: tournament.subsetId,
        tournamentDescription: tournament.tournamentDescription,
        subsetDescription: tournament.subsetDescription,
        multiplier: tournament.multiplier,
        firstGameInChannel,
        newTournament,
      };
    });
  }

  #inheritedTriviaSubset(defaultTournamentId: number | null): number {
    if (defaultTournamentId === null) return 1;
    const row = this.database
      .prepare(
        "SELECT question_subset_id subsetId FROM tournaments WHERE id=? AND game_type_id=1",
      )
      .get(defaultTournamentId) as { subsetId: number } | undefined;
    return row?.subsetId ?? 1;
  }

  createGame(
    tournamentId: number,
    challenges: number,
    description = "",
  ): number {
    return transaction(this.database, () =>
      Number(
        this.database
          .prepare(
            "INSERT INTO games(tournament_id,num_questions,date_init,description) VALUES(?,?,?,?)",
          )
          .run(
            tournamentId,
            challenges,
            this.clock.now().toISOString(),
            description,
          ).lastInsertRowid,
      ),
    );
  }

  finishGame(gameId: number): void {
    transaction(this.database, () => {
      const result = this.database
        .prepare("UPDATE games SET date_end=? WHERE id=? AND date_end IS NULL")
        .run(this.clock.now().toISOString(), gameId);
      if (result.changes !== 1)
        throw new Error(`Game ${gameId} was not active`);
    });
  }

  addScores(tournamentId: number, changes: readonly ScoreChange[]): void {
    transaction(this.database, () => {
      const statement = this.database
        .prepare(`INSERT INTO scores(player_id,tournament_id,subject_id,questions_answered,score)
        VALUES(?,?,?,?,?) ON CONFLICT(player_id,tournament_id,subject_id) DO UPDATE SET
        questions_answered=questions_answered+excluded.questions_answered,score=score+excluded.score`);
      for (const change of changes)
        statement.run(
          change.playerId,
          tournamentId,
          change.subjectId,
          change.answered ?? 1,
          change.points,
        );
    });
  }

  addScore(
    playerId: number,
    tournamentId: number,
    subjectId: number,
    points: number,
    answered = 1,
  ): void {
    this.addScores(tournamentId, [{ playerId, subjectId, points, answered }]);
  }

  rankings(
    tournamentId: number,
    playerIds: readonly number[],
  ): TournamentRanking[] {
    const all = this.database
      .prepare(
        `SELECT player_id playerId,SUM(score) total FROM scores WHERE tournament_id=?
      GROUP BY player_id ORDER BY total DESC,player_id`,
      )
      .all(tournamentId) as unknown as Array<{
      playerId: number;
      total: number;
    }>;
    const wanted = new Set(playerIds);
    return all
      .map((row, index) => ({ ...row, rank: index + 1 }))
      .filter((row) => wanted.has(row.playerId));
  }

  historicalTotal(playerId: number, tournamentId: number): number {
    const row = this.database
      .prepare(
        "SELECT COALESCE(SUM(score),0) total FROM score_history WHERE player_id=? AND tournament_id=?",
      )
      .get(playerId, tournamentId) as { total: number };
    return row.total;
  }
}

interface TournamentRow {
  id: number;
  subsetId: number;
  tournamentDescription: string;
  subsetDescription: string;
  multiplier: number;
}
interface SubjectBuffer {
  questions: TriviaQuestion[];
  idle: number;
}

export class QuestionRepository {
  readonly #buffers = new Map<number, SubjectBuffer>();
  readonly #subsets = new Map<
    number,
    Array<{ subjectId: number; cumulative: number }>
  >();
  #ageMinutes = 0;
  constructor(
    private readonly database: DatabaseSync,
    private readonly random: RandomSource,
  ) {}

  validateSubset(subsetId: number): void {
    const subjects = this.#subjects(subsetId);
    if (subjects.length === 0)
      throw new Error(`El conjunto ${subsetId} no tiene temas`);
    const usable = this.database
      .prepare(
        `SELECT count(*) count FROM questions q JOIN question_subset_members m ON m.subject_id=q.subject_id
      WHERE m.subset_id=? AND q.selection_ifs IS NOT NULL AND q.question<>'' AND q.answer<>''`,
      )
      .get(subsetId) as { count: number };
    if (usable.count === 0)
      throw new Error(`El conjunto ${subsetId} no tiene preguntas utilizables`);
  }

  next(subsetId: number): TriviaQuestion {
    const subjects = this.#subjects(subsetId);
    for (
      let attempt = 0;
      attempt < Math.max(100, subjects.length * 10);
      attempt++
    ) {
      const total = subjects.at(-1)?.cumulative ?? 0;
      const draw = randomInt(this.random, 1, total);
      const subjectId = subjects.find(
        (subject) => draw <= subject.cumulative,
      )?.subjectId;
      if (subjectId === undefined) continue;
      const buffer = this.#buffers.get(subjectId) ?? { questions: [], idle: 0 };
      this.#buffers.set(subjectId, buffer);
      if (buffer.questions.length < 5) this.#fill(subjectId, buffer);
      const question = buffer.questions.shift();
      if (question !== undefined) {
        buffer.idle = 0;
        return question;
      }
    }
    throw new Error(
      `No se pudo seleccionar una pregunta del conjunto ${subsetId}`,
    );
  }

  age(minutes = 1): void {
    this.#ageMinutes += minutes;
    for (const [subjectId, buffer] of this.#buffers) {
      buffer.idle += minutes;
      if (buffer.idle >= 60) this.#buffers.delete(subjectId);
      else if (buffer.questions.length <= 10) this.#fill(subjectId, buffer);
    }
    if (this.#ageMinutes >= 1_440) {
      this.#subsets.clear();
      this.#ageMinutes = 0;
    }
  }

  multiplier(subsetId: number): number {
    const row = this.database
      .prepare("SELECT multiplier FROM question_subsets WHERE id=?")
      .get(subsetId) as { multiplier: number } | undefined;
    if (row === undefined)
      throw new Error(`Question subset ${subsetId} not found`);
    return row.multiplier;
  }

  #subjects(
    subsetId: number,
  ): Array<{ subjectId: number; cumulative: number }> {
    const cached = this.#subsets.get(subsetId);
    if (cached !== undefined) return cached;
    const rows = this.database
      .prepare(
        "SELECT subject_id subjectId,weight FROM question_subset_members WHERE subset_id=? ORDER BY id",
      )
      .all(subsetId) as unknown as Array<{ subjectId: number; weight: number }>;
    let cumulative = 0;
    const subjects = rows.map((row) => ({
      subjectId: row.subjectId,
      cumulative: (cumulative += row.weight),
    }));
    this.#subsets.set(subsetId, subjects);
    return subjects;
  }

  #fill(subjectId: number, buffer: SubjectBuffer): void {
    if (buffer.questions.length > 10) return;
    const subject = this.database
      .prepare("SELECT question_count count FROM subjects WHERE id=?")
      .get(subjectId) as { count: number } | undefined;
    if (subject === undefined || subject.count <= 0) return;
    const wanted = 30 - buffer.questions.length;
    const positions = Array.from({ length: wanted * 2 }, () =>
      randomInt(this.random, 1, subject.count),
    );
    const placeholders = positions.map(() => "?").join(",");
    transaction(this.database, () => {
      const rows = this.database
        .prepare(
          `SELECT q.id,q.question text,q.answer,q.subject_id subjectId,s.subject,a.author
        FROM questions q JOIN subjects s ON s.id=q.subject_id JOIN authors a ON a.id=q.author_id
        WHERE q.subject_id=? AND q.selection_ifs IN (${placeholders}) ORDER BY q.repeats,q.random_value LIMIT ?`,
        )
        .all(subjectId, ...positions, wanted) as unknown as TriviaQuestion[];
      const update = this.database.prepare(
        "UPDATE questions SET repeats=COALESCE(repeats,0)+1,random_value=? WHERE id=?",
      );
      for (const question of rows) {
        buffer.questions.push(question);
        update.run(randomInt(this.random, 1, 10_000), question.id);
      }
    });
  }
}

export class DictionaryRepository {
  constructor(private readonly database: DatabaseSync) {}
  lookup(key: string): DictionaryWord | undefined {
    return this.database
      .prepare(
        "SELECT word,meaning,status FROM dictionary WHERE word_key=? AND status IN ('OK','NF') LIMIT 1",
      )
      .get(key) as DictionaryWord | undefined;
  }
}
