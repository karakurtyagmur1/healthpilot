import express from "express";
import cors from "cors";
import OpenAI from "openai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Test endpoint
app.get("/", (req, res) => {
  res.send("HealthPilot API OK");
});

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ---------- CHAT ----------
app.post("/chat", async (req, res) => {
  try {
    const { message, context } = req.body;

    const targets = context?.targets || {};
    const totals = context?.totals || {};
    const remaining = context?.remaining || {};

    const systemPrompt = `
Sen HealthPilot isimli akıllı bir beslenme asistanısın.
Türkçe konuş, kısa ve net cevap ver.

Bugün:
Hedef Kalori: ${Math.round(targets.kcal || 0)}
Alınan Kalori: ${Math.round(totals.kcal || 0)}
Kalan Kalori: ${Math.round(remaining.kcal || 0)}

Hedef Protein: ${Math.round(targets.protein || 0)}
Alınan Protein: ${Math.round(totals.protein || 0)}
Kalan Protein: ${Math.round(remaining.protein || 0)}

Hedef Karbonhidrat: ${Math.round(targets.carb || 0)}
Alınan Karbonhidrat: ${Math.round(totals.carb || 0)}
Kalan Karbonhidrat: ${Math.round(remaining.carb || 0)}

Hedef Yağ: ${Math.round(targets.fat || 0)}
Alınan Yağ: ${Math.round(totals.fat || 0)}
Kalan Yağ: ${Math.round(remaining.fat || 0)}
`;

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      temperature: 0.6,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: message },
      ],
    });

    res.json({
      reply: response.choices[0].message.content,
    });
  } catch (err) {
    console.error("CHAT ERROR:", err);
    res.status(500).json({ error: "Chat sunucu hatası" });
  }
});

// ---------- SERVER ----------
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log("HealthPilot API çalışıyor. Port: " + PORT);
});