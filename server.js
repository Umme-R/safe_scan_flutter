const express = require("express");
const axios = require("axios");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const port = Number(process.env.PORT) || 3000;
const webBuildDir = path.join(__dirname, "build", "web");
const webIndexPath = path.join(webBuildDir, "index.html");

app.use(cors());

app.get("/expand", async (req, res) => {
  const url = req.query.url;

  if (!url) {
    return res.status(400).json({ error: "Missing URL" });
  }

  try {
    const response = await axios.get(url, {
      maxRedirects: 10,
      validateStatus: null,
    });

    return res.json({
      expandedUrl: response.request?.res?.responseUrl ?? url,
    });
  } catch (error) {
    console.error("Expand URL failed:", error);
    return res.status(500).json({ error: "Failed to expand URL" });
  }
});

if (fs.existsSync(webBuildDir)) {
  app.use(express.static(webBuildDir));

  // Flutter web uses client-side routing, so non-API routes should return index.html.
  app.get(/^(?!\/expand(?:\/|$)).*/, (_req, res) => {
    res.sendFile(webIndexPath);
  });
} else {
  app.get("/", (_req, res) => {
    res.status(503).type("html").send(`
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>Build Required</title>
          <style>
            body {
              margin: 0;
              min-height: 100vh;
              display: grid;
              place-items: center;
              background: #08111f;
              color: #e2e8f0;
              font-family: Arial, sans-serif;
            }
            main {
              max-width: 640px;
              padding: 32px;
              border: 1px solid rgba(255, 255, 255, 0.12);
              border-radius: 16px;
              background: rgba(255, 255, 255, 0.04);
            }
            code {
              color: #93c5fd;
            }
          </style>
        </head>
        <body>
          <main>
            <h1>Flutter web build not found</h1>
            <p>The server is running, but <code>build/web</code> does not exist yet.</p>
            <p>Run <code>flutter build web</code> or <code>flutter run -d chrome</code> first.</p>
          </main>
        </body>
      </html>
    `);
  });
}

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
