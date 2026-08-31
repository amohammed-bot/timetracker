const db = require("./db");

// Creates all the tables the app needs. Safe to run multiple times.
async function migrate() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS users (
      id          SERIAL PRIMARY KEY,
      email       TEXT UNIQUE NOT NULL,
      password    TEXT NOT NULL,
      created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS categories (
      id          SERIAL PRIMARY KEY,
      user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name        TEXT NOT NULL,
      color       TEXT NOT NULL DEFAULT '#4F46E5',
      created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS time_entries (
      id           SERIAL PRIMARY KEY,
      user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      category_id  INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
      started_at   TIMESTAMPTZ NOT NULL,
      ended_at     TIMESTAMPTZ,
      seconds      INTEGER NOT NULL DEFAULT 0
    );
  `);

  await db.query(
    `CREATE INDEX IF NOT EXISTS idx_entries_user_started
     ON time_entries (user_id, started_at);`
  );

  console.log("Migration complete: tables are ready.");
  process.exit(0);
}

migrate().catch((err) => {
  console.error("Migration failed:", err);
  process.exit(1);
});
