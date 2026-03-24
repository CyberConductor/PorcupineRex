import express from "express";
import { MongoClient } from "mongodb";
import path from "path";
import { fileURLToPath } from "url";
import pkg from "node-nlp";
const { NlpManager } = pkg;

const manager = new NlpManager({ languages: ['en', 'he'] });

async function trainAI()
{
    //English support - Hackers
    manager.addDocument('en', 'how many hackers are there', 'hackers.count');
    manager.addDocument('en', 'show attackers', 'hackers.count');
    manager.addDocument('en', 'number of intruders', 'hackers.count');
    manager.addDocument('en', 'how many threats', 'hackers.count');
    manager.addDocument('en', 'are there any hackers', 'hackers.count');
    manager.addDocument('en', 'show me hackers', 'hackers.count');

    //English support - Commands
    manager.addDocument('en', 'show commands', 'commands.list');
    manager.addDocument('en', 'what attacks exist', 'commands.list');
    manager.addDocument('en', 'list payloads', 'commands.list');
    manager.addDocument('en', 'give me commands', 'commands.list');
    manager.addDocument('en', 'list all attacks', 'commands.list');

    //English support - User Contact
    manager.addDocument('en', 'hello', 'greeting');
    manager.addDocument('en', 'hi', 'greeting');

    //Hebrew Support - Hackers
    manager.addDocument('he', 'כמה האקרים יש', 'hackers.count');
    manager.addDocument('he', 'תראה תוקפים', 'hackers.count');
    manager.addDocument('he', 'כמה תוקפים יש', 'hackers.count');
    manager.addDocument('he', 'יש האקרים', 'hackers.count');

    //Hebrew Support - Commands
    manager.addDocument('he', 'תראה פקודות', 'commands.list');
    manager.addDocument('he', 'איזה מתקפות יש', 'commands.list');
    manager.addDocument('he', 'רשימת פקודות', 'commands.list');

    //Hebrew Support - User Contact
    manager.addDocument('he', 'שלום', 'greeting');
    manager.addDocument('he', 'היי', 'greeting');

    await manager.train();
    manager.save();
}

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.static('public'));
const PORT = 3000;

app.use(express.json());

const uri = "mongodb+srv://kalaiboaz_db_user:XUV3rthRmubjnuHG@honeypot.nyvgpyd.mongodb.net/honeypot?retryWrites=true&w=majority";

let db;

function containsKeyword(msg, keywords)
{
    return keywords.some(word => msg.includes(word));
}

const hackerKeywords = ["hackers", "attackers", "intruders", "threats", "האקרים", "תוקפים"];
const commandKeywords = ["commands", "attacks", "payloads", "פקודות", "מתקפות"];

async function start()
{
    try
    {
        await trainAI();

        const client = new MongoClient(uri);
        await client.connect();
        console.log("MongoDB connected");
        db = client.db("honeypot");

        app.get("/", (req, res) =>
        {
            res.sendFile(path.join(__dirname, "index.html"));
        });

        app.get("/api/hackers", async (req, res) =>
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

        app.get("/api/commands", async (req, res) =>
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

        app.post("/api/chat", async (req, res) =>
        {
            const { message } = req.body;

            if (!message)
                return res.status(400).json({ reply: "Please send a message." });

            const cleanedMessage = message.toLowerCase().trim();
            let reply = "I don't understand.";

            try
            {
                const result = await manager.process('auto', cleanedMessage);

                console.log(result);

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
                else
                {
                    if (containsKeyword(cleanedMessage, hackerKeywords))
                    {
                        const hackers = await db.collection("hackers").find({}).toArray();

                        reply = cleanedMessage.match(/[א-ת]/)
                            ? `יש ${hackers.length} תוקפים במערכת`
                            : `There are ${hackers.length} attackers recorded.`;
                    }
                    else if (containsKeyword(cleanedMessage, commandKeywords))
                    {
                        const commands = await db.collection("commands").find({}).toArray();

                        reply = cleanedMessage.match(/[א-ת]/)
                            ? `יש ${commands.length} פקודות`
                            : `I know ${commands.length} commands.`;
                    }
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