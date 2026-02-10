import express from "express";
import { MongoClient } from "mongodb";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

const uri = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/honeypot?retryWrites=true&w=majority";

async function start()
{
    const client = new MongoClient(uri);
    await client.connect();

    const db = client.db("honeypot");
    const hackers = db.collection("hackers");

    app.get("/", (req, res) =>
    {
        res.sendFile(path.join(__dirname, "index.html"));
    });

  app.get("/api/hackers", async (req, res) => {
  console.log("Request to /api/hackers received"); // <-- debug
  try {
    const client = new MongoClient(uri);
    await client.connect();
    console.log("MongoDB connected"); // <-- debug

    const db = client.db("honeypot");
    const hackers = await db.collection("hackers").find({}).toArray();
    console.log("Fetched data:", hackers.length, "records"); // <-- debug

    await client.close();
    res.json(hackers);
  } catch (err) {
    console.error("MongoDB error:", err); // <-- full error
    res.status(500).json({ error: "Failed to fetch data from MongoDB" });
  }
});


    app.listen(PORT, () =>
    {
        console.log("Server running on http://localhost:" + PORT);
    });
}

start();
