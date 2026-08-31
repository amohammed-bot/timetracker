const express = require("express");
const bcrypt = require("bcryptjs");
const db = require("../db");
const { signToken } = require("../auth");

const router = express.Router();

// A few sensible default categories every new user starts with.
const DEFAULT_CATEGORIES = [
  { name: "Work", color: "#4F46E5" },
  { name: "Study", color: "#059669" },
  { name: "Entertainment", color: "#DB2777" },
];

// POST /auth/register
router.post("/register", async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: "Password must be at least 6 characters" });
  }

  try {
    const existing = await db.query("SELECT id FROM users WHERE email = $1", [
      email.toLowerCase(),
    ]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: "That email is already registered" });
    }

    const hash = await bcrypt.hash(password, 10);
    const result = await db.query(
      "INSERT INTO users (email, password) VALUES ($1, $2) RETURNING id",
      [email.toLowerCase(), hash]
    );
    const userId = result.rows[0].id;

    // Give the new user their starter categories.
    for (const cat of DEFAULT_CATEGORIES) {
      await db.query(
        "INSERT INTO categories (user_id, name, color) VALUES ($1, $2, $3)",
        [userId, cat.name, cat.color]
      );
    }

    const token = signToken(userId);
    res.status(201).json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Something went wrong" });
  }
});

// POST /auth/login
router.post("/login", async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  try {
    const result = await db.query("SELECT * FROM users WHERE email = $1", [
      email.toLowerCase(),
    ]);
    const user = result.rows[0];
    if (!user) {
      return res.status(401).json({ error: "Wrong email or password" });
    }

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) {
      return res.status(401).json({ error: "Wrong email or password" });
    }

    const token = signToken(user.id);
    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Something went wrong" });
  }
});

module.exports = router;
