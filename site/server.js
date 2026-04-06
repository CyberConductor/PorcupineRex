import express from "express";
import { MongoClient } from "mongodb";
import { fileURLToPath } from "url";
import pkg from "node-nlp";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import path from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, "../.env") });

const { NlpManager } = pkg;
const manager = new NlpManager({ languages: ['en', 'he'] });

async function trainAI()
{
    manager.addDocument('en', 'how many hackers are there', 'hackers.count');
    manager.addDocument('en', 'show attackers', 'hackers.count');
    manager.addDocument('en', 'number of intruders', 'hackers.count');
    manager.addDocument('en', 'how many threats', 'hackers.count');
    manager.addDocument('en', 'are there any hackers', 'hackers.count');
    manager.addDocument('en', 'show me hackers', 'hackers.count');

    manager.addDocument('en', 'show commands', 'commands.list');
    manager.addDocument('en', 'what attacks exist', 'commands.list');
    manager.addDocument('en', 'list payloads', 'commands.list');
    manager.addDocument('en', 'give me commands', 'commands.list');
    manager.addDocument('en', 'list all attacks', 'commands.list');

    manager.addDocument('en', 'hello', 'greeting');
    manager.addDocument('en', 'hi', 'greeting');

    manager.addDocument('he', 'כמה האקרים יש', 'hackers.count');
    manager.addDocument('he', 'תראה תוקפים', 'hackers.count');
    manager.addDocument('he', 'כמה תוקפים יש', 'hackers.count');
    manager.addDocument('he', 'יש האקרים', 'hackers.count');

    manager.addDocument('he', 'תראה פקודות', 'commands.list');
    manager.addDocument('he', 'איזה מתקפות יש', 'commands.list');
    manager.addDocument('he', 'רשימת פקודות', 'commands.list');

    manager.addDocument('he', 'שלום', 'greeting');
    manager.addDocument('he', 'היי', 'greeting');

    await manager.train();
    manager.save();
}

const app = express();
app.use(express.static('public'));
app.use(express.json());

const PORT = process.env.PORT || 3000;


const limiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    message: { error: "Too many requests, slow down." }
});
app.use(limiter);

const uri = process.env.MONGO_URI;
let db;

async function start()
{
    try
    {
        await trainAI();

        const client = new MongoClient(uri);
        await client.connect();
        db = client.db("honeypot");

        console.log("MongoDB connected");

      
        const apiKeyMiddleware = (req, res, next) =>
        {
            const key = req.headers['x-api-key'];
            if (!key || key !== process.env.API_KEY)
                return res.status(401).json({ error: "Unauthorized" });

            next();
        };

     
        app.get("/", (req, res) =>
        {
            res.sendFile(path.join(__dirname, "index.html"));
        });

        app.get("/api/hackers", apiKeyMiddleware, async (req, res) =>
        {
            try
            {
                const hackers = await db.collection("hackers").find({}).toArray();
                res.json(hackers);
            }
            catch (err)
            {
                console.error(err);
                res.status(500).json({ error: "Failed to fetch hackers" });
            }
        });

        app.get("/api/commands", apiKeyMiddleware, async (req, res) =>
        {
            try
            {
                const commands = await db.collection("commands").find({}).toArray();
                res.json(commands);
            }
            catch (err)
            {
                console.error(err);
                res.status(500).json({ error: "Failed to fetch commands" });
            }
        });

        app.post("/api/chat", apiKeyMiddleware, async (req, res) =>
        {
            const { message } = req.body;

            if (!message)
                return res.status(400).json({ reply: "Please send a message." });

            const cleanedMessage = message
                .replace(/[^a-zA-Z0-9א-ת\s]/g, '')
                .toLowerCase()
                .trim();

            let reply = "I don't understand.";

            try
            {
                const result = await manager.process('auto', cleanedMessage);

                if (result.intent === "hackers.count" && result.score > 0.6)
                {
                    const hackers = await db.collection("hackers").find({}).toArray();

                    reply = result.locale === 'he'
                        ? `יש ${hackers.length} תוקפים במערכת`
                        : `There are ${hackers.length} attackers recorded.`;
                }
                else if (result.intent === "commands.list" && result.score > 0.6)
                {
                    const commands = await db.collection("commands").find({}).toArray();
                    const sample = commands.slice(0, 5).map(c => c.command).join(", ");

                    reply = result.locale === 'he'
                        ? `יש ${commands.length} פקודות. דוגמאות: ${sample}`
                        : `I know ${commands.length} commands. Sample: ${sample}`;
                }
                else if (result.intent === "greeting" && result.score > 0.6)
                {
                    reply = result.locale === 'he'
                        ? "שלום! אתה יכול לשאול על האקרים או פקודות"
                        : "Hello! Ask me about hackers or commands.";
                }

                res.json({ reply });
            }
            catch (err)
            {
                console.error("Chatbot error:", err);
                res.status(500).json({ reply: "Something went wrong." });
            }
        });

        app.listen(PORT, () =>
        {
            console.log(`Server running on http://localhost:${PORT}`);
        });

        process.on("SIGINT", async () =>
        {
            console.log("Closing MongoDB connection");
            await client.close();
            process.exit();
        });
    }
    catch (err)
    {
        console.error("Failed to start server:", err);
    }
}

start();