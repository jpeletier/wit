import type { DatabaseSync } from "node:sqlite";
import type { Clock, RandomSource } from "../core/ports.js";
import { lookupKey } from "../core/text.js";
import type {
  DictionaryWord,
  LetterWinner,
  NumberWinner,
} from "../games/cyl.js";
import type { TriviaQuestion } from "../games/trivia.js";
import { transaction } from "./database.js";

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
      if (existing !== undefined) return existing.id;
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

  addScore(
    playerId: number,
    tournamentId: number,
    subjectId: number,
    points: number,
    answered = 1,
  ): void {
    transaction(this.database, () => {
      this.database
        .prepare(
          `INSERT INTO scores(player_id,tournament_id,subject_id,questions_answered,score)
        VALUES(?,?,?,?,?) ON CONFLICT(player_id,tournament_id,subject_id) DO UPDATE SET
        questions_answered=questions_answered+excluded.questions_answered, score=score+excluded.score`,
        )
        .run(playerId, tournamentId, subjectId, answered, points);
    });
  }

  ensureTournament(
    networkId: number,
    channelName: string,
    gameTypeId: number,
    subsetId: number,
  ): { channelId: number; tournamentId: number } {
    return transaction(this.database, () => {
      const channelKey = lookupKey(channelName);
      let channel = this.database
        .prepare("SELECT id FROM channels WHERE network_id=? AND name_key=?")
        .get(networkId, channelKey) as { id: number } | undefined;
      if (channel === undefined) {
        channel = {
          id: Number(
            this.database
              .prepare(
                "INSERT INTO channels(network_id,name,name_key,last_used) VALUES(?,?,?,?)",
              )
              .run(
                networkId,
                channelName.normalize("NFC"),
                channelKey,
                this.clock.now().toISOString(),
              ).lastInsertRowid,
          ),
        };
      }
      const now = this.clock.now();
      const monthStart = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
      ).toISOString();
      const monthEnd = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1),
      ).toISOString();
      let league = this.database
        .prepare(
          "SELECT id FROM leagues WHERE date_init=? AND date_end=? LIMIT 1",
        )
        .get(monthStart, monthEnd) as { id: number } | undefined;
      if (league === undefined) {
        const id = Number(
          (
            this.database
              .prepare("SELECT COALESCE(MAX(id),0)+1 id FROM leagues")
              .get() as { id: number }
          ).id,
        );
        this.database
          .prepare(
            "INSERT INTO leagues(id,description,date_init,date_end) VALUES(?,?,?,?)",
          )
          .run(
            id,
            `Liga ${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, "0")}`,
            monthStart,
            monthEnd,
          );
        league = { id };
      }
      let tournament = this.database
        .prepare(
          "SELECT id FROM tournaments WHERE channel_id=? AND league_id=? AND game_type_id=? LIMIT 1",
        )
        .get(channel.id, league.id, gameTypeId) as { id: number } | undefined;
      if (tournament === undefined) {
        tournament = {
          id: Number(
            this.database
              .prepare(
                "INSERT INTO tournaments(description,date_init,date_end,channel_id,league_id,question_subset_id,game_type_id) VALUES(?,?,?,?,?,?,?)",
              )
              .run(
                `Torneo mensual de ${channelName}`,
                monthStart,
                monthEnd,
                channel.id,
                league.id,
                subsetId,
                gameTypeId,
              ).lastInsertRowid,
          ),
        };
      }
      return { channelId: channel.id, tournamentId: tournament.id };
    });
  }
}

export class QuestionRepository {
  constructor(
    private readonly database: DatabaseSync,
    private readonly random: RandomSource,
  ) {}

  select(subsetId: number, count: number): TriviaQuestion[] {
    return transaction(this.database, () => {
      const rows = this.database
        .prepare(
          `SELECT q.id,q.question text,q.answer,q.subject_id subjectId,s.subject,a.author,
      COALESCE(q.repeats,0) repeats,COALESCE(q.random_value,0) randomValue,COALESCE(q.selection_score,0) selectionScore,
      COALESCE(m.weight,1) weight FROM questions q JOIN subjects s ON s.id=q.subject_id JOIN authors a ON a.id=q.author_id
      JOIN question_subset_members m ON m.subject_id=q.subject_id WHERE m.subset_id=? AND q.question<>'' AND q.answer<>''
      ORDER BY (COALESCE(q.repeats,0)+1.0)/(MAX(COALESCE(m.weight,1),1)*(1.0+COALESCE(q.selection_score,0))) ASC, q.random_value ASC LIMIT ?`,
        )
        .all(subsetId, Math.max(count * 4, count)) as unknown as Array<
        TriviaQuestion & { repeats: number }
      >;
      const buffer = rows.slice(
        0,
        Math.max(count, Math.min(rows.length, count * 2)),
      );
      const selected: TriviaQuestion[] = [];
      while (selected.length < count && buffer.length > 0)
        selected.push(
          buffer.splice(Math.floor(this.random.next() * buffer.length), 1)[0]!,
        );
      if (selected.length < count)
        throw new Error(
          `Only ${selected.length} usable questions in subset ${subsetId}`,
        );
      const update = this.database.prepare(
        "UPDATE questions SET repeats=repeats+1 WHERE id=?",
      );
      for (const question of selected) update.run(question.id);
      return selected;
    });
  }

  multiplier(subsetId: number): number {
    const row = this.database
      .prepare("SELECT multiplier FROM question_subsets WHERE id=?")
      .get(subsetId) as { multiplier: number } | undefined;
    if (row === undefined)
      throw new Error(`Question subset ${subsetId} not found`);
    return row.multiplier;
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

export function persistWinners(
  repository: GameRepository,
  playerIds: ReadonlyMap<string, number>,
  tournamentId: number,
  subjectId: number,
  winners: readonly (LetterWinner | NumberWinner)[],
): void {
  for (const winner of winners) {
    const playerId = playerIds.get(winner.identity);
    if (playerId === undefined)
      throw new Error(`Missing player for ${winner.identity}`);
    repository.addScore(playerId, tournamentId, subjectId, winner.score);
  }
}
