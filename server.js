const express = require("express");
const axios = require("axios");
const cors = require("cors");
const https = require("https");
const fs = require("fs");
const app = express();

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

        res.json({
            expandedUrl: response.request.res.responseUrl
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to expand URL" });
    }
});

const options = {
    key: fs.readFileSync("server.key"),
    cert: fs.readFileSync("server.cert"),
};

app.listen(3000, () => {
    console.log("Server running on port 3000");
});