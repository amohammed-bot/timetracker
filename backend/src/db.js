const { Pool } = require("pg");

// The connection string comes from the DATABASE_URL environment variable,
// which is set by Docker Compose in production.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
