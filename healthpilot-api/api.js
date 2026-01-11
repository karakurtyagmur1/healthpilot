import express from "express";
import cors from "cors";
import OpenAI from "openai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ---------- CHAT ----------
app.post("/chat", async (req, res) => {
  try {
    const { message, context } = req.body;

    // Context güvenli alım
    const targets = context?.targets || {};
    const totals = context?.totals || {};
    const remaining = context?.remaining || {};

    const systemPrompt = `
Sen HealthPilot isimli akıllı bir beslenme asistanısın.

Kurallar:
- Türkçe konuş
- Kısa, net ve insansı cevaplar ver
- Robot gibi tekrar etme
- Kullanıcının sorusuna odaklan
- Sayıları küsüratsız yaz
- Gereksiz uzun açıklama yapma

Bugünkü durum:
- Hedef Kalori: ${Math.round(targets.kcal || 0)} kcal
- Alınan Kalori: ${Math.round(totals.kcal || 0)} kcal
- Kalan Kalori: ${Math.round(remaining.kcal || 0)} kcal

- Hedef Protein: ${Math.round(targets.protein || 0)} g
- Alınan Protein: ${Math.round(totals.protein || 0)} g
- Kalan Protein: ${Math.round(remaining.protein || 0)} g

- Hedef Karbonhidrat: ${Math.round(targets.carb || 0)} g
- Alınan Karbonhidrat: ${Math.round(totals.carb || 0)} g
- Kalan Karbonhidrat: ${Math.round(remaining.carb || 0)} g

- Hedef Yağ: ${Math.round(targets.fat || 0)} g
- Alınan Yağ: ${Math.round(totals.fat || 0)} g
- Kalan Yağ: ${Math.round(remaining.fat || 0)} g

Örnek cevap tarzı:
"Bugün 720 kcal hakkın kaldı. Protein biraz düşük, akşam yemeğinde protein ağırlıklı bir seçim iyi olur."
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
  console.log(`✅ HealthPilot API çalışıyor → http://localhost:${PORT}`);
});
