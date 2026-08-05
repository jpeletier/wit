PRAGMA foreign_keys = ON;

CREATE TABLE schema_migrations (
  version INTEGER PRIMARY KEY CHECK(version > 0),
  applied_at TEXT NOT NULL
) STRICT;

CREATE TABLE networks (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  allow_join INTEGER NOT NULL DEFAULT 1 CHECK(allow_join IN (0,1)),
  join_free INTEGER NOT NULL DEFAULT 1 CHECK(join_free IN (0,1))
) STRICT;

CREATE TABLE authors (
  id INTEGER PRIMARY KEY,
  author TEXT NOT NULL
) STRICT;

CREATE TABLE game_types (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
) STRICT;

CREATE TABLE subjects (
  id INTEGER PRIMARY KEY,
  subject TEXT NOT NULL,
  question_count INTEGER NOT NULL DEFAULT 0 CHECK(question_count >= 0),
  game_type_id INTEGER NOT NULL REFERENCES game_types(id)
) STRICT;

CREATE TABLE channels (
  id INTEGER PRIMARY KEY,
  network_id INTEGER NOT NULL REFERENCES networks(id),
  name TEXT NOT NULL,
  name_key TEXT NOT NULL,
  last_used TEXT,
  default_tournament_id INTEGER REFERENCES tournaments(id),
  UNIQUE(network_id,name_key)
) STRICT;

CREATE TABLE question_subsets (
  id INTEGER PRIMARY KEY,
  description TEXT NOT NULL,
  multiplier REAL NOT NULL DEFAULT 1 CHECK(multiplier > 0),
  channel_id INTEGER REFERENCES channels(id)
) STRICT;

CREATE TABLE question_subset_members (
  id INTEGER PRIMARY KEY,
  subset_id INTEGER NOT NULL REFERENCES question_subsets(id) ON DELETE CASCADE,
  subject_id INTEGER NOT NULL REFERENCES subjects(id),
  weight INTEGER NOT NULL DEFAULT 1 CHECK(weight > 0),
  UNIQUE(subset_id,subject_id)
) STRICT;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  question TEXT NOT NULL CHECK(length(trim(question)) > 0),
  answer TEXT NOT NULL CHECK(length(trim(answer)) > 0),
  source INTEGER,
  repeats INTEGER CHECK(repeats IS NULL OR repeats >= 0),
  subject_id INTEGER NOT NULL REFERENCES subjects(id),
  author_id INTEGER NOT NULL REFERENCES authors(id),
  selection_ifs INTEGER,
  random_value INTEGER,
  selection_score REAL
) STRICT;

CREATE TABLE dictionary (
  id INTEGER NOT NULL,
  word TEXT PRIMARY KEY,
  word_key TEXT NOT NULL UNIQUE,
  meaning TEXT,
  status TEXT NOT NULL CHECK(status IN ('OK','NF'))
) STRICT;

CREATE TABLE players (
  id INTEGER PRIMARY KEY,
  network_id INTEGER NOT NULL REFERENCES networks(id),
  nick TEXT NOT NULL,
  nick_key TEXT NOT NULL,
  last_used TEXT,
  UNIQUE(network_id,nick_key)
) STRICT;

CREATE TABLE leagues (
  id INTEGER PRIMARY KEY,
  description TEXT NOT NULL,
  date_init TEXT,
  date_end TEXT
) STRICT;

CREATE TABLE tournaments (
  id INTEGER PRIMARY KEY,
  description TEXT NOT NULL,
  date_init TEXT,
  date_end TEXT,
  channel_id INTEGER NOT NULL REFERENCES channels(id),
  league_id INTEGER NOT NULL REFERENCES leagues(id),
  question_subset_id INTEGER NOT NULL REFERENCES question_subsets(id),
  game_type_id INTEGER NOT NULL REFERENCES game_types(id)
) STRICT;

CREATE TABLE games (
  id INTEGER PRIMARY KEY,
  tournament_id INTEGER REFERENCES tournaments(id),
  num_questions INTEGER NOT NULL DEFAULT 0 CHECK(num_questions >= 0),
  date_init TEXT NOT NULL,
  date_end TEXT,
  description TEXT NOT NULL DEFAULT ''
) STRICT;

CREATE TABLE scores (
  id INTEGER PRIMARY KEY,
  player_id INTEGER NOT NULL REFERENCES players(id),
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id),
  subject_id INTEGER NOT NULL REFERENCES subjects(id),
  questions_answered INTEGER NOT NULL CHECK(questions_answered >= 0),
  score INTEGER NOT NULL,
  UNIQUE(player_id,tournament_id,subject_id)
) STRICT;

CREATE TABLE score_history (
  id INTEGER PRIMARY KEY,
  player_id INTEGER NOT NULL REFERENCES players(id),
  tournament_id INTEGER NOT NULL REFERENCES tournaments(id),
  subject_id INTEGER NOT NULL REFERENCES subjects(id),
  questions_answered INTEGER NOT NULL CHECK(questions_answered >= 0),
  score INTEGER NOT NULL
) STRICT;

CREATE TABLE import_audit (
  key TEXT PRIMARY KEY,
  value INTEGER NOT NULL CHECK(value >= 0)
) STRICT;

CREATE INDEX idx_questions_selection ON questions(subject_id,selection_ifs,repeats,random_value);
CREATE INDEX idx_subset_members_subset ON question_subset_members(subset_id,subject_id);
CREATE INDEX idx_players_nick ON players(network_id,nick_key);
CREATE INDEX idx_tournaments_active ON tournaments(channel_id,game_type_id,date_end);
CREATE INDEX idx_games_tournament ON games(tournament_id,date_init);
CREATE INDEX idx_scores_ranking ON scores(tournament_id,score DESC);
CREATE INDEX idx_score_history_ranking ON score_history(tournament_id,score DESC);
