// Supabase Edge Function: read-label
// Prebere nalepko artikla s fotografije (Claude) in vrne kodo, EAN, proizvajalca in opis.
// Potrebuje skrivnost ANTHROPIC_API_KEY (Edge Functions → Secrets).
// V nastavitvah funkcije IZKLOPITE "Verify JWT" – zaščito zagotavlja PIN ekipe.

const MODEL = "claude-haiku-5-5";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PROMPT = `Na fotografiji je nalepka ali embalaža artikla (elektromaterial). Preberi podatke in vrni SAMO JSON, brez drugega besedila:
{"code":"","ean":"","manufacturer":"","description":"","unit":""}
- code: kataloška / naročniška številka proizvajalca (npr. A9F74116, 5SL6116-7, 2CDS251001R0164). Če je ni, prazen niz.
- ean: EAN/GTIN (8, 12, 13 ali 14 števk), če je viden; sicer prazen niz.
- manufacturer: ime proizvajalca (npr. Schneider Electric, Siemens, ABB).
- description: kratek opis artikla v slovenščini, največ 80 znakov (npr. "Inštalacijski odklopnik 1P C16 6kA").
- unit: "kos", "m", "kolut", "paket" ali "kpl"; če ni jasno, "kos".
Česar ne prebereš zanesljivo, pusti prazno. Ne ugibaj.`;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

const clean = (v: unknown) => (typeof v === "string" ? v.trim() : "");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "Dovoljen je samo POST" }, 405);

  try {
    const { pin, image, mediaType } = await req.json();
    if (!pin || !image) return json({ error: "Manjka PIN ali slika" }, 400);
    if (typeof image !== "string" || image.length > 5_000_000) return json({ error: "Slika je prevelika" }, 413);

    // Preverjanje PIN-a prek iste baze (javni ključ projekta ali ključ, ki ga pošlje aplikacija)
    const apikey = Deno.env.get("SUPABASE_ANON_KEY") || req.headers.get("apikey") || "";
    const base = Deno.env.get("SUPABASE_URL");
    const pr = await fetch(`${base}/rest/v1/rpc/check_pin`, {
      method: "POST",
      headers: { apikey, "Content-Type": "application/json" },
      body: JSON.stringify({ p_pin: String(pin) }),
    });
    if (!pr.ok || (await pr.json()) !== true) return json({ error: "Napačen PIN" }, 401);

    const key = Deno.env.get("ANTHROPIC_API_KEY");
    if (!key) return json({ error: "ANTHROPIC_API_KEY ni nastavljen v Supabase" }, 500);

    const ar = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 400,
        messages: [{
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: mediaType || "image/jpeg", data: image } },
            { type: "text", text: PROMPT },
          ],
        }],
      }),
    });

    if (!ar.ok) {
      const t = await ar.text();
      return json({ error: `AI napaka ${ar.status}`, detail: t.slice(0, 500) }, 502);
    }

    const data = await ar.json();
    const text = (data.content ?? [])
      .filter((b: { type: string }) => b.type === "text")
      .map((b: { text: string }) => b.text)
      .join("");
    const m = text.match(/\{[\s\S]*\}/);
    if (!m) return json({ error: "AI ni vrnil podatkov" }, 502);

    const r = JSON.parse(m[0]);
    return json({
      code: clean(r.code),
      ean: clean(r.ean).replace(/\D/g, ""),
      manufacturer: clean(r.manufacturer),
      description: clean(r.description),
      unit: clean(r.unit) || "kos",
    });
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
