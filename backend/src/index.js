require("dotenv").config();
const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Simple health check so you (and Docker) can confirm the API is alive.
app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/auth", require("./routes/auth"));
app.use("/categories", require("./routes/categories"));
app.use("/entries", require("./routes/entries"));
app.use("/stats", require("./routes/stats"));

// Catch-all error handler.
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Server error" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`TimeTracker API listening on port ${PORT}`);
});
