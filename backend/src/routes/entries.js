const express = require("express");
const db = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();
router.use(requireAuth);

// POST /entries/start  -> starts a running timer for a category
router.post("/start", async (req, res) => {
  const { category_id } = req.body || {};
  if (!category_id) return res.status(400).json({ error: "category_id is required" });

  // Make sure the category belongs to this user.
  const cat = await db.query(
    "SELECT id FROM categories WHERE id = $1 AND user_id = $2",
    [category_id, req.userId]
  );
  if (cat.rows.length === 0) return res.status(404).json({ error: "Category not found" });

  const result = await db.query(
    `INSERT INTO time_entries (user_id, category_id, started_at, seconds)
     VALUES ($1, $2, now(), 0) RETURNING id, category_id, started_at`,
    [req.userId, category_id]
  );
  res.status(201).json(result.rows[0]);
});

// POST /entries/:id/stop  -> stops a running timer and records the duration
router.post("/:id/stop", async (req, res) => {
  const result = await db.query(
    `UPDATE time_entries
     SET ended_at = now(),
         seconds = GREATEST(0, EXTRACT(EPOCH FROM (now() - started_at))::INTEGER)
     WHERE id = $1 AND user_id = $2 AND ended_at IS NULL
     RETURNING id, category_id, started_at, ended_at, seconds`,
    [req.params.id, req.userId]
  );
  if (result.rows.length === 0) {
    return res.status(404).json({ error: "No running timer with that id" });
  }
  res.json(result.rows[0]);
});

// GET /entries/running  -> returns the currently running timer, if any
router.get("/running", async (req, res) => {
  const result = await db.query(
    `SELECT id, category_id, started_at FROM time_entries
     WHERE user_id = $1 AND ended_at IS NULL
     ORDER BY started_at DESC LIMIT 1`,
    [req.userId]
  );
  res.json(result.rows[0] || null);
});

// GET /entries  -> recent history (finished entries, newest first)
router.get("/", async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit, 10) || 100, 500);
  const result = await db.query(
    `SELECT e.id, e.category_id, c.name AS category_name, c.color,
            e.started_at, e.ended_at, e.seconds
     FROM time_entries e
     JOIN categories c ON c.id = e.category_id
     WHERE e.user_id = $1 AND e.ended_at IS NOT NULL
     ORDER BY e.started_at DESC
     LIMIT $2`,
    [req.userId, limit]
  );
  res.json(result.rows);
});

module.exports = router;
