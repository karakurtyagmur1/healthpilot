import functions from "firebase-functions";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// ✅ Cloud Function
export const chat = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const { message } = req.body;

    if (!message) {
      res.status(400).send({ error: "Message is required" });
      return;
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "Sen HealthPilot adında bir beslenme ve fitness asistanısın. Kullanıcılara kişisel beslenme, makro takibi, spor sonrası beslenme gibi konularda Türkçe ve samimi bir dille öneriler ver.",
        },
        { role: "user", content: message },
      ],
      max_tokens: 300,
    });

    const reply = completion.choices[0].message.content;
    res.send({ reply });
  } catch (error) {
    console.error("❌ Chat error:", error);
    res.status(500).send({ error: error.message });
  }
});
