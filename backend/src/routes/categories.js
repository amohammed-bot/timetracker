const express = require("express");
const db = require("../db");
const { requireAuth } = require("../auth");

const router = express.Router();
router.use(requireAuth);

// GET /categories
router.get("/", async (req, res) => {
  const result = await db.query(
    "SELECT id, name, color FROM categories WHERE user_id = $1 ORDER BY id",
    [req.userId]
  );
  res.json(result.rows);
});

// POST /categories
router.post("/", async (req, res) => {
  const { name, color } = req.body || {};
  if (!name) return res.status(400).json({ error: "Name is required" });

  const result = await db.query(
    "INSERT INTO categories (user_id, name, color) VALUES ($1, $2, $3) RETURNING id, name, color",
    [req.userId, name, color || "#4F46E5"]
  );
  res.status(201).json(result.rows[0]);
});

// PUT /categories/:id
router.put("/:id", async (req, res) => {
  const { name, color } = req.body || {};
  const result = await db.query(
    `UPDATE categories SET name = COALESCE($1, name), color = COALESCE($2, color)
     WHERE id = $3 AND user_id = $4 RETURNING id, name, color`,
    [name, color, req.params.id, req.userId]
  );
  if (result.rows.length === 0) return res.status(404).json({ error: "Not found" });
  res.json(result.rows[0]);
});

// DELETE /categories/:id
router.delete("/:id", async (req, res) => {
  await db.query("DELETE FROM categories WHERE id = $1 AND user_id = $2", [
    req.params.id,
    req.userId,
  ]);
  res.status(204).end();
});

module.exports = router;
