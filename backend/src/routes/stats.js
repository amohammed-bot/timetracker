const express = require("express");
const db = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();
router.use(requireAuth);

// Maps the requested period to a Postgres interval start.
const PERIODS = {
  day: "1 day",
  week: "7 days",
  month: "30 days",
};

// GET /stats?period=day|week|month
// Returns total seconds per category over the chosen period.
router.get("/", async (req, res) => {
  const period = req.query.period || "week";
  const interval = PERIODS[period];
  if (!interval) {
    return res.status(400).json({ error: "period must be day, week, or month" });
  }

  const result = await db.query(
    `SELECT c.id AS category_id, c.name, c.color,
            COALESCE(SUM(e.seconds), 0)::INTEGER AS total_seconds
     FROM categories c
     LEFT JOIN time_entries e
       ON e.category_id = c.id
       AND e.user_id = c.user_id
       AND e.ended_at IS NOT NULL
       AND e.started_at >= now() - $2::interval
     WHERE c.user_id = $1
     GROUP BY c.id, c.name, c.color
     ORDER BY total_seconds DESC`,
    [req.userId, interval]
  );

  const totalSeconds = result.rows.reduce((sum, r) => sum + r.total_seconds, 0);
  res.json({ period, total_seconds: totalSeconds, categories: result.rows });
});

module.exports = router;
