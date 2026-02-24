import express from "express";
import { MongoClient } from "mongodb";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json());

const uri = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/honeypot?retryWrites=true&w=majority";

let db;

async function start() {
    try {
        const client = new MongoClient(uri);
        await client.connect();
        console.log("MongoDB connected");
        db = client.db("honeypot");

        app.get("/", (req, res) => {
            res.sendFile(path.join(__dirname, "index.html"));
        });

        app.get("/api/hackers", async (req, res) => {
            try {
                const hackers = await db.collection("hackers").find({}).toArray();
                res.json(hackers);
            } catch (err) {
                console.error(err);
                res.status(500).json({ error: "Failed to fetch hackers" });
            }
        });


        app.get("/api/commands", async (req, res) => {
            try {
                const commands = await db.collection("commands").find({}).toArray();
                res.json(commands);
            } catch (err) {
                console.error(err);
                res.status(500).json({ error: "Failed to fetch commands" });
            }
        });

        app.post("/api/chat", async (req, res) => {
            const { message } = req.body;
            if (!message) return res.status(400).json({ reply: "Please send a message." });

            const lowerMsg = message.toLowerCase();
            let reply = "Sorry, You can ask about hackers or commands.";

            try {
                if (lowerMsg.includes("hackers") || lowerMsg.includes("attacker")) {
                    const hackers = await db.collection("hackers").find({}).toArray();
                    reply = `There are ${hackers.length} attackers recorded.`;
                } else if (lowerMsg.includes("commands") || lowerMsg.includes("attack")) {
                    const commands = await db.collection("commands").find({}).toArray();
                    const sample = commands.slice(0, 5).map(c => c.command).join(", ");
                    reply = `I know ${commands.length} commands. Sample commands: ${sample}`;
                } else if (lowerMsg.includes("hello") || lowerMsg.includes("hi")) {
                    reply = "Hello! I can provide info about hackers or commands. Try asking me!";
                }

                res.json({ reply });
            } catch (err) {
                console.error("Chatbot error:", err);
                res.status(500).json({ reply: "Something went wrong." });
            }
        });

        app.listen(PORT, () => {
            console.log(`Server running on http://localhost:${PORT}`);
        });

        process.on("SIGINT", async () => {
            console.log("Closing MongoDB connection");
            await client.close();
            process.exit();
        });

    } catch (err) {
        console.error("Failed to start server:", err);
    }
}

start();